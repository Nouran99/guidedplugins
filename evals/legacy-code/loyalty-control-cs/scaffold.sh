#!/usr/bin/env bash
set -e
mkdir -p src/Loyalty tests/Loyalty

cat > src/Loyalty/PointsPolicy.cs <<'CS'
namespace Shop.Loyalty;

public sealed record Purchase(string CustomerId, long TotalCents, DateTimeOffset At);

public enum Tier
{
    Standard,
    Silver,
    Gold,
}

public sealed record Award(long Points, string Reason);

/// <summary>
/// The rules for loyalty points. Everything the rules need arrives as an argument,
/// including the time of the purchase, so they can be called with literals.
/// </summary>
public static class PointsPolicy
{
    private const long CentsPerPoint = 100;
    private const long WeekendBonusPercent = 20;

    public static Award Evaluate(Purchase purchase, Tier tier)
    {
        if (purchase.TotalCents <= 0)
            return new Award(0, "no value");

        var basePoints = purchase.TotalCents / CentsPerPoint;
        var multiplier = tier switch
        {
            Tier.Gold => 3,
            Tier.Silver => 2,
            _ => 1,
        };
        var points = basePoints * multiplier;

        if (IsWeekend(purchase.At))
            points += points * WeekendBonusPercent / 100;

        return new Award(points, $"{tier} tier");
    }

    private static bool IsWeekend(DateTimeOffset at) =>
        at.DayOfWeek is DayOfWeek.Saturday or DayOfWeek.Sunday;
}
CS

cat > src/Loyalty/LoyaltyService.cs <<'CS'
namespace Shop.Loyalty;

public interface IPointsLedger
{
    Task<Tier> TierOfAsync(string customerId, CancellationToken ct);

    Task RecordAwardAsync(string customerId, Award award, CancellationToken ct);
}

public interface IPointsAnnouncer
{
    Task AnnounceAsync(string customerId, Award award, CancellationToken ct);
}

public sealed class LoyaltyService
{
    private readonly IPointsLedger _ledger;
    private readonly IPointsAnnouncer _announcer;
    private readonly TimeProvider _time;

    public LoyaltyService(IPointsLedger ledger, IPointsAnnouncer announcer, TimeProvider time)
    {
        _ledger = ledger;
        _announcer = announcer;
        _time = time;
    }

    public async Task<Award> OnPurchaseAsync(string customerId, long totalCents, CancellationToken ct)
    {
        var tier = await _ledger.TierOfAsync(customerId, ct);
        var award = PointsPolicy.Evaluate(new Purchase(customerId, totalCents, _time.GetUtcNow()), tier);
        if (award.Points == 0)
            return award;

        await _ledger.RecordAwardAsync(customerId, award, ct);
        await _announcer.AnnounceAsync(customerId, award, ct);
        return award;
    }
}
CS

cat > src/Loyalty/PurchaseController.cs <<'CS'
using Microsoft.AspNetCore.Mvc;

namespace Shop.Loyalty;

[ApiController]
[Route("loyalty/purchases")]
public sealed class PurchaseController : ControllerBase
{
    private readonly LoyaltyService _service;

    public PurchaseController(LoyaltyService service) => _service = service;

    public sealed record PurchaseDto(string CustomerId, long TotalCents);

    [HttpPost]
    public async Task<IActionResult> Post(PurchaseDto dto, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(dto.CustomerId))
            return BadRequest(new { error = "customerId is required" });

        var award = await _service.OnPurchaseAsync(dto.CustomerId, dto.TotalCents, ct);
        return Ok(new { points = award.Points, reason = award.Reason });
    }
}
CS

cat > tests/Loyalty/PointsPolicyTests.cs <<'CS'
using Shop.Loyalty;
using Xunit;

namespace Shop.Loyalty.Tests;

public class PointsPolicyTests
{
    private static readonly DateTimeOffset Wednesday = new(2025, 3, 5, 12, 0, 0, TimeSpan.Zero);
    private static readonly DateTimeOffset Saturday = new(2025, 3, 8, 12, 0, 0, TimeSpan.Zero);
    private static readonly DateTimeOffset Sunday = new(2025, 3, 9, 12, 0, 0, TimeSpan.Zero);

    [Fact]
    public void A_standard_customer_earns_one_point_per_whole_currency_unit()
    {
        var award = PointsPolicy.Evaluate(new Purchase("c-1", 2_550, Wednesday), Tier.Standard);

        Assert.Equal(25, award.Points);
        Assert.Equal("Standard tier", award.Reason);
    }

    [Theory]
    [InlineData(Tier.Silver, 50)]
    [InlineData(Tier.Gold, 75)]
    public void Higher_tiers_multiply_the_base_points(Tier tier, long expected)
    {
        var award = PointsPolicy.Evaluate(new Purchase("c-1", 2_500, Wednesday), tier);

        Assert.Equal(expected, award.Points);
    }

    [Fact]
    public void Saturday_purchases_earn_twenty_percent_more()
    {
        var award = PointsPolicy.Evaluate(new Purchase("c-1", 10_000, Saturday), Tier.Standard);

        Assert.Equal(120, award.Points);
    }

    [Fact]
    public void Sunday_purchases_earn_twenty_percent_more()
    {
        var award = PointsPolicy.Evaluate(new Purchase("c-1", 10_000, Sunday), Tier.Standard);

        Assert.Equal(120, award.Points);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-500)]
    public void A_purchase_without_value_earns_nothing(long totalCents)
    {
        var award = PointsPolicy.Evaluate(new Purchase("c-1", totalCents, Wednesday), Tier.Gold);

        Assert.Equal(0, award.Points);
        Assert.Equal("no value", award.Reason);
    }
}
CS

cat > tests/Loyalty/Fakes.cs <<'CS'
using Shop.Loyalty;

namespace Shop.Loyalty.Tests;

internal sealed class FakeLedger : IPointsLedger
{
    private readonly List<string> _calls;

    public FakeLedger(List<string> calls) => _calls = calls;

    public Tier Tier { get; set; } = Tier.Standard;

    public Task<Tier> TierOfAsync(string customerId, CancellationToken ct) => Task.FromResult(Tier);

    public Task RecordAwardAsync(string customerId, Award award, CancellationToken ct)
    {
        _calls.Add($"save {customerId} {award.Points}");
        return Task.CompletedTask;
    }
}

internal sealed class RecordingAnnouncer : IPointsAnnouncer
{
    private readonly List<string> _calls;

    public RecordingAnnouncer(List<string> calls) => _calls = calls;

    public Task AnnounceAsync(string customerId, Award award, CancellationToken ct)
    {
        _calls.Add($"announce {customerId} {award.Points}");
        return Task.CompletedTask;
    }
}
CS

cat > tests/Loyalty/LoyaltyServiceTests.cs <<'CS'
using Microsoft.Extensions.Time.Testing;
using Shop.Loyalty;
using Xunit;

namespace Shop.Loyalty.Tests;

public class LoyaltyServiceTests
{
    private static readonly DateTimeOffset Wednesday = new(2025, 3, 5, 12, 0, 0, TimeSpan.Zero);

    [Fact]
    public async Task A_purchase_with_points_is_saved_and_then_announced()
    {
        var calls = new List<string>();
        var service = new LoyaltyService(
            new FakeLedger(calls) { Tier = Tier.Silver },
            new RecordingAnnouncer(calls),
            new FakeTimeProvider(Wednesday));

        var award = await service.OnPurchaseAsync("c-7", 4_000, CancellationToken.None);

        Assert.Equal(80, award.Points);
        Assert.Equal(new[] { "save c-7 80", "announce c-7 80" }, calls);
    }

    [Fact]
    public async Task A_purchase_without_points_is_neither_saved_nor_announced()
    {
        var calls = new List<string>();
        var service = new LoyaltyService(
            new FakeLedger(calls),
            new RecordingAnnouncer(calls),
            new FakeTimeProvider(Wednesday));

        var award = await service.OnPurchaseAsync("c-7", 0, CancellationToken.None);

        Assert.Equal(0, award.Points);
        Assert.Empty(calls);
    }
}
CS

cat > tests/Loyalty/PurchaseControllerTests.cs <<'CS'
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Time.Testing;
using Shop.Loyalty;
using Xunit;

namespace Shop.Loyalty.Tests;

public class PurchaseControllerTests
{
    private static PurchaseController ControllerRecordingInto(List<string> calls) =>
        new(new LoyaltyService(
            new FakeLedger(calls),
            new RecordingAnnouncer(calls),
            new FakeTimeProvider(new DateTimeOffset(2025, 3, 5, 12, 0, 0, TimeSpan.Zero))));

    [Fact]
    public async Task A_blank_customer_id_is_a_bad_request_and_nothing_is_recorded()
    {
        var calls = new List<string>();

        var result = await ControllerRecordingInto(calls)
            .Post(new PurchaseController.PurchaseDto(" ", 1_000), CancellationToken.None);

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.Empty(calls);
    }

    [Fact]
    public async Task A_valid_purchase_is_answered_with_ok_after_the_award_is_recorded()
    {
        var calls = new List<string>();

        var result = await ControllerRecordingInto(calls)
            .Post(new PurchaseController.PurchaseDto("c-7", 2_500), CancellationToken.None);

        Assert.IsType<OkObjectResult>(result);
        Assert.Equal(new[] { "save c-7 25", "announce c-7 25" }, calls);
    }
}
CS
