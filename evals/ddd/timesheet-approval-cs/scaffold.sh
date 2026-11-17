#!/usr/bin/env bash
set -e
mkdir -p src/Timesheets
cat > src/Timesheets/Timesheet.cs <<'CS'
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Acme.Timesheets;

[Table("TS_HDR")]
public class Timesheet
{
    [Key]
    [Column("TS_ID")]
    public int TsId { get; set; }

    [Column("EMP_ID")]
    public string EmpId { get; set; } = "";

    [Column("WK_START_DT")]
    public DateTime WkStartDt { get; set; }

    [Column("TS_STS_CD")]
    public string TsStsCd { get; set; } = "D";

    [Column("RATE_AMT")]
    public double RateAmt { get; set; }

    [Column("RATE_CCY")]
    public string RateCcy { get; set; } = "";

    public List<TimeEntry> Entries { get; set; } = new();

    [NotMapped]
    public bool Dirty { get; set; }
}

[Table("TS_ENTRY")]
public class TimeEntry
{
    [Key]
    [Column("ENTRY_ID")]
    public int EntryId { get; set; }

    [Column("TS_ID")]
    public int TsId { get; set; }

    [Column("PRJ_ID")]
    public int PrjId { get; set; }

    [Column("WORKED_DT")]
    public DateTime WorkedDt { get; set; }

    [Column("HOURS")]
    public double Hours { get; set; }

    public virtual Project Project { get; set; } = null!;
}

[Table("PRJ")]
public class Project
{
    [Key]
    [Column("PRJ_ID")]
    public int PrjId { get; set; }

    [Column("PRJ_CD")]
    public string PrjCd { get; set; } = "";

    [Column("BUDGET_HRS")]
    public double BudgetHrs { get; set; }

    [Column("USED_HRS")]
    public double UsedHrs { get; set; }
}
CS
cat > src/Timesheets/Repositories.cs <<'CS'
using Microsoft.EntityFrameworkCore;

namespace Acme.Timesheets;

public class TimesheetDbContext : DbContext
{
    public TimesheetDbContext(DbContextOptions<TimesheetDbContext> options) : base(options) { }

    public DbSet<Timesheet> Timesheets => Set<Timesheet>();
    public DbSet<TimeEntry> TimeEntries => Set<TimeEntry>();
    public DbSet<Project> Projects => Set<Project>();
}

public class TimesheetRepository
{
    private readonly TimesheetDbContext _db;

    public TimesheetRepository(TimesheetDbContext db) => _db = db;

    public Task<Timesheet> Get(int id) =>
        _db.Timesheets
            .Include(t => t.Entries)
            .ThenInclude(e => e.Project)
            .SingleAsync(t => t.TsId == id);

    public Task<List<Timesheet>> FindByStatus(string status) =>
        _db.Timesheets.Where(t => t.TsStsCd == status).ToListAsync();

    public async Task Add(Timesheet timesheet)
    {
        _db.Timesheets.Add(timesheet);
        await _db.SaveChangesAsync();
    }
}

public class TimeEntryRepository
{
    private readonly TimesheetDbContext _db;

    public TimeEntryRepository(TimesheetDbContext db) => _db = db;

    public Task<List<TimeEntry>> ForSheet(int tsId) =>
        _db.TimeEntries.Where(e => e.TsId == tsId).ToListAsync();

    public async Task Add(TimeEntry entry)
    {
        _db.TimeEntries.Add(entry);
        await _db.SaveChangesAsync();
    }
}
CS
cat > src/Timesheets/TimesheetService.cs <<'CS'
namespace Acme.Timesheets;

public class TimesheetService
{
    private readonly TimesheetRepository _timesheets;
    private readonly TimesheetDbContext _db;

    public TimesheetService(TimesheetRepository timesheets, TimesheetDbContext db)
    {
        _timesheets = timesheets;
        _db = db;
    }

    public async Task Submit(int tsId)
    {
        var ts = await _timesheets.Get(tsId);
        if (ts.TsStsCd != "D")
            throw new InvalidOperationException("The timesheet was already submitted");
        if (!ts.Entries.Any())
            throw new InvalidOperationException("The timesheet is empty");

        ts.TsStsCd = "S";
        ts.Dirty = true;
        await _db.SaveChangesAsync();
    }

    public async Task Approve(int tsId, string approverId)
    {
        var ts = await _timesheets.Get(tsId);
        if (ts.TsStsCd != "S")
            throw new InvalidOperationException("Only a submitted timesheet can be approved");
        if (ts.EmpId == approverId)
            throw new InvalidOperationException("You cannot approve your own timesheet");
        if (ts.Entries.Sum(e => e.Hours) > 60)
            throw new InvalidOperationException("A week has at most 60 hours");

        foreach (var entry in ts.Entries)
            entry.Project.UsedHrs += entry.Hours;

        ts.TsStsCd = "A";
        ts.Dirty = true;
        await _db.SaveChangesAsync();
    }

    public async Task Reprice(int tsId, double rate, string currency)
    {
        if (rate <= 0 || currency.Length != 3)
            throw new ArgumentException("The rate must be positive and the currency a three-letter code");

        var ts = await _timesheets.Get(tsId);
        if (ts.TsStsCd == "A")
            throw new InvalidOperationException("An approved timesheet cannot be repriced");

        ts.RateAmt = rate;
        ts.RateCcy = currency;
        ts.Dirty = true;
        await _db.SaveChangesAsync();
    }

    public double AmountDue(Timesheet ts)
    {
        var hours = ts.Entries.Sum(e => e.Hours);
        var overtime = Math.Max(0, hours - 40);
        return ((hours - overtime) + overtime * 1.5) * ts.RateAmt;
    }
}
CS
cat > src/Timesheets/TimesheetsController.cs <<'CS'
using Microsoft.AspNetCore.Mvc;

namespace Acme.Timesheets;

public record CreateTimesheetRequest(string EmployeeId, DateTime WeekStart, double Rate, string Currency);

public record AddEntryRequest(int ProjectId, DateTime Date, double Hours);

[ApiController]
[Route("api/timesheets")]
public class TimesheetsController : ControllerBase
{
    private readonly TimesheetRepository _timesheets;
    private readonly TimeEntryRepository _entries;
    private readonly TimesheetService _service;

    public TimesheetsController(TimesheetRepository timesheets, TimeEntryRepository entries, TimesheetService service)
    {
        _timesheets = timesheets;
        _entries = entries;
        _service = service;
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateTimesheetRequest request)
    {
        if (request.Rate <= 0 || request.Currency.Length != 3)
            return BadRequest("The rate must be positive and the currency a three-letter code");

        var ts = new Timesheet();
        ts.EmpId = request.EmployeeId;
        ts.WkStartDt = request.WeekStart;
        ts.RateAmt = request.Rate;
        ts.RateCcy = request.Currency;
        ts.TsStsCd = "D";
        await _timesheets.Add(ts);
        return Created($"api/timesheets/{ts.TsId}", ts);
    }

    [HttpPost("{id}/entries")]
    public async Task<IActionResult> AddEntry(int id, AddEntryRequest request)
    {
        var entry = new TimeEntry
        {
            TsId = id,
            PrjId = request.ProjectId,
            WorkedDt = request.Date,
            Hours = request.Hours,
        };
        await _entries.Add(entry);
        return Ok();
    }

    [HttpPost("{id}/submit")]
    public async Task<IActionResult> Submit(int id)
    {
        await _service.Submit(id);
        return NoContent();
    }

    [HttpPost("{id}/approve")]
    public async Task<IActionResult> Approve(int id, [FromQuery] string approverId)
    {
        await _service.Approve(id, approverId);
        return NoContent();
    }
}
CS
