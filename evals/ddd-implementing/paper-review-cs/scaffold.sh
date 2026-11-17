#!/usr/bin/env bash
set -e
mkdir -p src/Papers
cat > src/Papers/Submission.cs <<'CS'
namespace Conf.Papers;

public class Submission
{
    public Guid Id { get; set; }
    public string Title { get; set; } = "";
    public string Abstract { get; set; } = "";
    public string AuthorEmail { get; set; } = "";
    public Guid TrackId { get; set; }
    public string Status { get; set; } = "new";
    public List<Review> Reviews { get; set; } = new();
}

public class Review
{
    public Guid Id { get; set; }
    public Guid SubmissionId { get; set; }
    public string ReviewerEmail { get; set; } = "";
    public int Score { get; set; }
    public string Comments { get; set; } = "";
}

public record DecisionRequest(bool Accept);
CS
cat > src/Papers/Repositories.cs <<'CS'
using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;

namespace Conf.Papers;

public class PapersDbContext : DbContext
{
    public PapersDbContext(DbContextOptions<PapersDbContext> options) : base(options) { }

    public DbSet<Submission> Submissions => Set<Submission>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Track> Tracks => Set<Track>();
}

public interface IRepository<T> where T : class
{
    IEnumerable<T> GetAll();
    T? Find(Guid id);
    IEnumerable<T> Where(Expression<Func<T, bool>> predicate);
    void Add(T entity);
    void Update(T entity);
    void Delete(T entity);
}

public class EfRepository<T> : IRepository<T> where T : class
{
    protected readonly PapersDbContext Db;

    public EfRepository(PapersDbContext db)
    {
        Db = db;
    }

    public IEnumerable<T> GetAll() => Db.Set<T>().ToList();

    public virtual T? Find(Guid id) => Db.Set<T>().Find(id);

    public IEnumerable<T> Where(Expression<Func<T, bool>> predicate) => Db.Set<T>().Where(predicate).ToList();

    public void Add(T entity)
    {
        Db.Set<T>().Add(entity);
        Db.SaveChanges();
    }

    public virtual void Update(T entity)
    {
        Db.Set<T>().Update(entity);
        Db.SaveChanges();
    }

    public void Delete(T entity)
    {
        Db.Set<T>().Remove(entity);
        Db.SaveChanges();
    }
}

public class SubmissionRepository : EfRepository<Submission>
{
    public SubmissionRepository(PapersDbContext db) : base(db) { }

    public override Submission? Find(Guid id) =>
        Db.Submissions.Include(s => s.Reviews).SingleOrDefault(s => s.Id == id);

    public override void Update(Submission submission)
    {
        var reviewCount = Db.Reviews.Count(r => r.SubmissionId == submission.Id);
        if (submission.Status == "in-review" && reviewCount >= 3)
        {
            submission.Status = "ready";
        }
        base.Update(submission);
    }
}

public class ReviewRepository : EfRepository<Review>
{
    public ReviewRepository(PapersDbContext db) : base(db) { }
}
CS
cat > src/Papers/SubmissionService.cs <<'CS'
namespace Conf.Papers;

public interface IMailer
{
    void Send(string to, string subject, string body);
}

public class SubmissionService
{
    private readonly SubmissionRepository _submissions;
    private readonly ReviewRepository _reviews;
    private readonly IMailer _mailer;

    public SubmissionService(SubmissionRepository submissions, ReviewRepository reviews, IMailer mailer)
    {
        _submissions = submissions;
        _reviews = reviews;
        _mailer = mailer;
    }

    public Submission Submit(string title, string abstractText, string authorEmail, Guid trackId)
    {
        var submission = new Submission
        {
            Id = Guid.NewGuid(),
            Title = title,
            Abstract = abstractText,
            AuthorEmail = authorEmail,
            TrackId = trackId,
            Status = "new",
        };
        _submissions.Add(submission);
        return submission;
    }

    public void AddReview(Guid submissionId, string reviewerEmail, int score, string comments)
    {
        var submission = _submissions.Find(submissionId)
            ?? throw new KeyNotFoundException($"no submission {submissionId}");
        if (submission.Status != "new" && submission.Status != "in-review")
        {
            throw new InvalidOperationException("reviews are closed for this submission");
        }
        if (submission.AuthorEmail == reviewerEmail)
        {
            throw new InvalidOperationException("authors cannot review their own paper");
        }
        if (score < 1 || score > 5)
        {
            throw new ArgumentOutOfRangeException(nameof(score));
        }
        _reviews.Add(new Review
        {
            Id = Guid.NewGuid(),
            SubmissionId = submission.Id,
            ReviewerEmail = reviewerEmail,
            Score = score,
            Comments = comments,
        });
        submission.Status = "in-review";
        _submissions.Update(submission);
    }

    public void Decide(Guid submissionId, bool accept)
    {
        var submission = _submissions.Find(submissionId)
            ?? throw new KeyNotFoundException($"no submission {submissionId}");
        if (submission.Status != "ready" || submission.Reviews.Count < 3)
        {
            throw new InvalidOperationException("a decision needs three reviews");
        }
        var average = submission.Reviews.Average(r => r.Score);
        if (accept && average < 3.0)
        {
            throw new InvalidOperationException("average score too low to accept");
        }
        submission.Status = accept ? "accepted" : "rejected";
        _submissions.Update(submission);
        _mailer.Send(submission.AuthorEmail, $"Decision on {submission.Title}", submission.Status);
    }
}
CS
cat > src/Papers/SubmissionsController.cs <<'CS'
using Microsoft.AspNetCore.Mvc;

namespace Conf.Papers;

[ApiController]
[Route("api/submissions")]
public class SubmissionsController : ControllerBase
{
    private readonly SubmissionRepository _submissions;
    private readonly SubmissionService _service;

    public SubmissionsController(SubmissionRepository submissions, SubmissionService service)
    {
        _submissions = submissions;
        _service = service;
    }

    [HttpGet]
    public IEnumerable<Submission> List([FromQuery] string? status) =>
        _submissions.Where(s => status == null || s.Status == status);

    [HttpGet("{id:guid}")]
    public ActionResult<Submission> Get(Guid id)
    {
        var submission = _submissions.Find(id);
        return submission is null ? NotFound() : Ok(submission);
    }

    [HttpPost("{id:guid}/decision")]
    public ActionResult<Submission> Decide(Guid id, DecisionRequest body)
    {
        var submission = _submissions.Find(id);
        if (submission is null)
        {
            return NotFound();
        }
        if (submission.Status != "ready")
        {
            return Conflict("the submission is not ready for a decision");
        }
        _service.Decide(id, body.Accept);
        return Ok(submission);
    }
}
CS
cat > src/Papers/Tracks.cs <<'CS'
namespace Conf.Papers;

public interface IDomainEvent { }

public record TrackRenamed(Guid TrackId, string NewName) : IDomainEvent;

public interface IEventBus
{
    void Publish(IDomainEvent domainEvent);
}

/// <summary>A conference track such as Security or Data, maintained by the chairs on an admin page.</summary>
public class Track
{
    private readonly List<IDomainEvent> _events = new();

    public Guid Id { get; private set; }
    public string Name { get; private set; } = "";

    public static Track Create(string name) => new() { Id = Guid.NewGuid(), Name = name };

    public void Rename(string name)
    {
        Name = name;
        _events.Add(new TrackRenamed(Id, name));
    }

    public IReadOnlyList<IDomainEvent> PullEvents()
    {
        var pulled = _events.ToList();
        _events.Clear();
        return pulled;
    }
}

public class TrackRepository : EfRepository<Track>
{
    public TrackRepository(PapersDbContext db) : base(db) { }
}

public class TrackService
{
    private readonly TrackRepository _tracks;
    private readonly IEventBus _bus;

    public TrackService(TrackRepository tracks, IEventBus bus)
    {
        _tracks = tracks;
        _bus = bus;
    }

    public Track Create(string name)
    {
        var track = Track.Create(name);
        _tracks.Add(track);
        return track;
    }

    public void Rename(Guid trackId, string name)
    {
        var track = _tracks.Find(trackId) ?? throw new KeyNotFoundException($"no track {trackId}");
        track.Rename(name);
        _tracks.Update(track);
        foreach (var domainEvent in track.PullEvents())
        {
            _bus.Publish(domainEvent);
        }
    }
}
CS
