#!/usr/bin/env bash
set -e
mkdir -p src/Quota
cat > src/Quota/RateLimiter.cs <<'CS'
namespace Quota;

/// <summary>What the limiter decided for one call.</summary>
/// <param name="Allowed">True when the call may proceed.</param>
/// <param name="RetryAfter">Zero when allowed; otherwise how long until this client's next call would be admitted.</param>
public readonly record struct Decision(bool Allowed, TimeSpan RetryAfter);

/// <summary>
/// Admits at most <c>limit</c> calls per client in any rolling <c>window</c>. Thread-safe.
/// Client ids are compared ignoring case. Memory use is proportional to the number of distinct client ids times
/// <c>limit</c>, because an id is remembered until <see cref="Reset"/>; that is acceptable because the gateway
/// caps distinct client ids at 10,000.
/// </summary>
public sealed class RateLimiter
{
    private readonly int _limit;
    private readonly TimeSpan _window;
    private readonly Func<DateTimeOffset> _now;
    private readonly Dictionary<string, Queue<DateTimeOffset>> _admitted = new(StringComparer.OrdinalIgnoreCase);
    private readonly object _gate = new();

    /// <param name="limit">Calls admitted per window; at least 1.</param>
    /// <param name="window">Length of the rolling window; positive.</param>
    /// <param name="now">Time source; defaults to the system clock.</param>
    public RateLimiter(int limit, TimeSpan window, Func<DateTimeOffset>? now = null)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(limit, 1);
        ArgumentOutOfRangeException.ThrowIfLessThanOrEqual(window, TimeSpan.Zero);
        _limit = limit;
        _window = window;
        _now = now ?? (() => DateTimeOffset.UtcNow);
    }

    /// <summary>
    /// Records a call by <paramref name="clientId"/> if it fits in the window and says whether it was admitted.
    /// A refused call is not recorded, so a client that backs off is admitted again as soon as its oldest
    /// admitted call leaves the window. Throws <see cref="ArgumentException"/> for a blank id, which is a bug in the caller.
    /// </summary>
    public Decision TryAcquire(string clientId)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(clientId);
        lock (_gate)
        {
            var now = _now();
            if (!_admitted.TryGetValue(clientId, out var calls))
            {
                calls = new Queue<DateTimeOffset>();
                _admitted[clientId] = calls;
            }

            // The window is half-open: a call made exactly one window ago no longer counts.
            while (calls.Count > 0 && calls.Peek() <= now - _window)
            {
                calls.Dequeue();
            }

            if (calls.Count < _limit)
            {
                calls.Enqueue(now);
                return new Decision(true, TimeSpan.Zero);
            }

            return new Decision(false, calls.Peek() + _window - now);
        }
    }

    /// <summary>Forgets every call by <paramref name="clientId"/>. Does nothing for a client the limiter has not seen.</summary>
    public void Reset(string clientId)
    {
        lock (_gate)
        {
            _admitted.Remove(clientId);
        }
    }
}
CS
cat > src/Quota/ClientKey.cs <<'CS'
namespace Quota;

/// <summary>Turns the several ways a request can identify its sender into the one client id the limiter counts.</summary>
public static class ClientKey
{
    /// <summary>All service accounts share this bucket, so adding a service never raises the total they may send.</summary>
    public const string ServiceBucket = "service-accounts";

    private const string ServiceKeyPrefix = "svc-";

    /// <summary>
    /// The id to count a request under: <see cref="ServiceBucket"/> for API keys starting with "svc-",
    /// the API key itself for any other key, and otherwise the first hop of <paramref name="forwardedFor"/>
    /// (the gateway's X-Forwarded-For header), falling back to <paramref name="remoteAddress"/>.
    /// </summary>
    public static string From(string? apiKey, string? forwardedFor, string remoteAddress)
    {
        if (!string.IsNullOrWhiteSpace(apiKey))
        {
            var key = apiKey.Trim();
            return key.StartsWith(ServiceKeyPrefix, StringComparison.Ordinal) ? ServiceBucket : key;
        }

        var firstHop = forwardedFor?.Split(',')[0].Trim();
        return string.IsNullOrEmpty(firstHop) ? remoteAddress : firstHop;
    }
}
CS
cat > src/Quota/RateLimitHttp.cs <<'CS'
using System.Globalization;

namespace Quota;

/// <summary>Maps a limiter decision onto the status and header an HTTP caller expects.</summary>
public static class RateLimitHttp
{
    private const int StatusOk = 200;
    private const int StatusTooManyRequests = 429;

    /// <summary>
    /// 200 with no header when allowed. Otherwise 429 with Retry-After in whole seconds, rounded up
    /// and never below 1, because HTTP clients treat 0 as "retry now" and would spin.
    /// </summary>
    public static (int Status, string? RetryAfter) ToResponse(Decision decision)
    {
        if (decision.Allowed)
        {
            return (StatusOk, null);
        }

        var seconds = Math.Max(1, (int)Math.Ceiling(decision.RetryAfter.TotalSeconds));
        return (StatusTooManyRequests, seconds.ToString(CultureInfo.InvariantCulture));
    }
}
CS
cat > src/Quota/RateLimiterTests.cs <<'CS'
using Xunit;

namespace Quota;

public class RateLimiterTests
{
    private static readonly TimeSpan Window = TimeSpan.FromSeconds(60);
    private DateTimeOffset _now = new(2026, 3, 2, 9, 0, 0, TimeSpan.Zero);

    private RateLimiter LimiterOf(int limit) => new(limit, Window, () => _now);

    [Fact]
    public void Admits_calls_up_to_the_limit()
    {
        var limiter = LimiterOf(2);

        Assert.True(limiter.TryAcquire("a").Allowed);
        Assert.True(limiter.TryAcquire("a").Allowed);
    }

    [Fact]
    public void Refuses_the_call_over_the_limit_and_says_when_to_retry()
    {
        var limiter = LimiterOf(1);
        limiter.TryAcquire("a");
        _now += TimeSpan.FromSeconds(20);

        var decision = limiter.TryAcquire("a");

        Assert.False(decision.Allowed);
        Assert.Equal(TimeSpan.FromSeconds(40), decision.RetryAfter);
    }

    [Fact]
    public void Admits_again_exactly_when_the_oldest_call_leaves_the_window()
    {
        var limiter = LimiterOf(1);
        limiter.TryAcquire("a");
        _now += Window;

        Assert.True(limiter.TryAcquire("a").Allowed);
    }

    [Fact]
    public void A_refused_call_does_not_extend_the_wait()
    {
        var limiter = LimiterOf(1);
        limiter.TryAcquire("a");
        _now += TimeSpan.FromSeconds(30);
        limiter.TryAcquire("a");
        _now += TimeSpan.FromSeconds(30);

        Assert.True(limiter.TryAcquire("a").Allowed);
    }

    [Fact]
    public void Counts_each_client_separately_ignoring_case()
    {
        var limiter = LimiterOf(1);
        limiter.TryAcquire("Alice");

        Assert.False(limiter.TryAcquire("alice").Allowed);
        Assert.True(limiter.TryAcquire("bob").Allowed);
    }

    [Fact]
    public void Reset_gives_a_client_a_fresh_window()
    {
        var limiter = LimiterOf(1);
        limiter.TryAcquire("a");
        limiter.Reset("a");

        Assert.True(limiter.TryAcquire("a").Allowed);
    }

    [Fact]
    public void Reset_of_an_unknown_client_does_nothing()
    {
        var limiter = LimiterOf(1);

        limiter.Reset("nobody");

        Assert.True(limiter.TryAcquire("nobody").Allowed);
    }

    [Fact]
    public void A_blank_client_id_is_rejected()
    {
        Assert.Throws<ArgumentException>(() => LimiterOf(1).TryAcquire(" "));
    }

    [Fact]
    public void A_limit_below_one_is_rejected()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => LimiterOf(0));
    }
}

public class ClientKeyTests
{
    [Fact]
    public void Service_accounts_share_one_bucket()
    {
        Assert.Equal(ClientKey.ServiceBucket, ClientKey.From("svc-billing", null, "10.0.0.1"));
        Assert.Equal(ClientKey.ServiceBucket, ClientKey.From(" svc-search ", null, "10.0.0.2"));
    }

    [Fact]
    public void Other_api_keys_count_under_the_key_itself()
    {
        Assert.Equal("key-123", ClientKey.From(" key-123 ", "1.2.3.4", "10.0.0.1"));
    }

    [Fact]
    public void Anonymous_callers_count_under_the_first_forwarded_hop()
    {
        Assert.Equal("1.2.3.4", ClientKey.From(null, "1.2.3.4, 5.6.7.8", "10.0.0.1"));
    }

    [Fact]
    public void Without_a_forwarded_header_the_remote_address_is_used()
    {
        Assert.Equal("10.0.0.1", ClientKey.From(null, " ", "10.0.0.1"));
    }
}

public class RateLimitHttpTests
{
    [Fact]
    public void An_allowed_call_is_a_200_without_a_header()
    {
        Assert.Equal((200, (string?)null), RateLimitHttp.ToResponse(new Decision(true, TimeSpan.Zero)));
    }

    [Fact]
    public void A_refused_call_is_a_429_with_the_wait_rounded_up_to_whole_seconds()
    {
        var response = RateLimitHttp.ToResponse(new Decision(false, TimeSpan.FromSeconds(20.2)));

        Assert.Equal((429, "21"), response);
    }

    [Fact]
    public void A_wait_under_a_second_is_reported_as_one_second()
    {
        var response = RateLimitHttp.ToResponse(new Decision(false, TimeSpan.FromMilliseconds(5)));

        Assert.Equal((429, "1"), response);
    }
}
CS
