#!/usr/bin/env bash
set -e
mkdir -p src/Reminders

cat > src/Reminders/Reminder.cs <<'CS'
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text.Json.Serialization;

namespace Billing.Reminders;

[Table("reminder_tbl")]
public class Reminder
{
    [Key]
    [Column("reminder_id")]
    [JsonPropertyName("id")]
    public int ReminderId { get; set; }

    [Required]
    [Column("inv_ref")]
    [JsonPropertyName("invoice")]
    public string InvRef { get; set; } = "";

    [Column("cust_email")]
    [JsonPropertyName("customerEmail")]
    public string CustEmail { get; set; } = "";

    [Column("due_dt")]
    [JsonPropertyName("dueDate")]
    public DateTime DueDt { get; set; }

    [Column("amt_cents")]
    [JsonPropertyName("amount")]
    public long AmtCents { get; set; }

    [Column("status_cd")]
    [JsonIgnore]
    public int StatusCd { get; set; }

    [Column("sent_cnt")]
    [JsonIgnore]
    public int SentCnt { get; set; }
}
CS

cat > src/Reminders/SendOverdueReminders.cs <<'CS'
namespace Billing.Reminders;

public interface IReminderGateway
{
    List<Reminder> FindOverdue();

    bool MarkSentIfAllowed(int reminderId);
}

public interface IReminderMailer
{
    void Send(Reminder reminder);
}

public class SendOverdueReminders
{
    private readonly IReminderGateway _reminders;
    private readonly IReminderMailer _mailer;

    public SendOverdueReminders(IReminderGateway reminders, IReminderMailer mailer)
    {
        _reminders = reminders;
        _mailer = mailer;
    }

    public int Execute()
    {
        var sent = 0;
        foreach (var reminder in _reminders.FindOverdue())
        {
            if (!_reminders.MarkSentIfAllowed(reminder.ReminderId))
            {
                continue;
            }

            _mailer.Send(reminder);
            sent++;
        }

        return sent;
    }
}
CS

cat > src/Reminders/SqlReminderGateway.cs <<'CS'
using Billing.Infrastructure;

namespace Billing.Reminders;

public class SqlReminderGateway : IReminderGateway
{
    private readonly BillingDbContext _db;

    public SqlReminderGateway(BillingDbContext db)
    {
        _db = db;
    }

    public List<Reminder> FindOverdue()
    {
        var cutoff = DateTime.UtcNow.AddDays(-3);
        return _db.Reminders
            .Where(r => r.StatusCd == 0 && r.DueDt < cutoff && r.SentCnt < 3)
            .OrderBy(r => r.DueDt)
            .ToList();
    }

    public bool MarkSentIfAllowed(int reminderId)
    {
        var reminder = _db.Reminders.Find(reminderId);
        if (reminder == null || reminder.StatusCd != 0 || reminder.SentCnt >= 3)
        {
            return false;
        }

        reminder.SentCnt++;
        if (reminder.SentCnt == 3)
        {
            reminder.StatusCd = 1;
        }

        _db.SaveChanges();
        return true;
    }
}
CS

cat > src/Reminders/SmtpReminderMailer.cs <<'CS'
using System.Net.Mail;

namespace Billing.Reminders;

public class SmtpReminderMailer : IReminderMailer
{
    private readonly SmtpClient _smtp;
    private readonly IAmountFormatter _amounts;

    public SmtpReminderMailer(SmtpClient smtp, IAmountFormatter amounts)
    {
        _smtp = smtp;
        _amounts = amounts;
    }

    public void Send(Reminder reminder)
    {
        var subject = $"Invoice {reminder.InvRef} is overdue";
        if (reminder.SentCnt >= 3)
        {
            subject = "Final notice: " + subject;
        }

        var message = new MailMessage(
            "billing@example.com",
            reminder.CustEmail,
            subject,
            $"Our records show {_amounts.Format(reminder.AmtCents)} outstanding since {reminder.DueDt:d MMMM yyyy}.");
        if (reminder.AmtCents >= 100_000)
        {
            message.Priority = MailPriority.High;
        }

        _smtp.Send(message);
    }
}
CS

cat > src/Reminders/ReminderSummaryPresenter.cs <<'CS'
using Billing.Infrastructure;

namespace Billing.Reminders;

public class ReminderSummaryPresenter
{
    private readonly BillingDbContext _db;
    private readonly IAmountFormatter _amounts;

    public ReminderSummaryPresenter(BillingDbContext db, IAmountFormatter amounts)
    {
        _db = db;
        _amounts = amounts;
    }

    public string Present(int sentCount)
    {
        var stillOpen = _db.Reminders.Where(r => r.StatusCd == 0).ToList();
        var outstanding = stillOpen.Sum(r => r.AmtCents);
        var oldest = stillOpen.OrderBy(r => r.DueDt).FirstOrDefault();

        var summary = $"Sent {sentCount} reminders. {stillOpen.Count} invoices are still open "
            + $"({_amounts.Format(outstanding)} outstanding).";
        if (oldest != null)
        {
            summary += $" Oldest: {oldest.InvRef}, due {oldest.DueDt:yyyy-MM-dd}.";
        }

        return summary;
    }
}
CS

cat > src/Reminders/AmountFormatter.cs <<'CS'
using System.Globalization;

namespace Billing.Reminders;

public interface IAmountFormatter
{
    string Format(long cents);
}

public class AmountFormatter : IAmountFormatter
{
    public string Format(long cents)
    {
        return (cents / 100m).ToString("0.00", CultureInfo.InvariantCulture);
    }
}
CS

cat > src/Reminders/ReminderGatewayTests.cs <<'CS'
using Billing.Infrastructure;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace Billing.Reminders.Tests;

public class ReminderGatewayTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly BillingDbContext _db;
    private readonly SqlReminderGateway _gateway;

    public ReminderGatewayTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();
        var options = new DbContextOptionsBuilder<BillingDbContext>().UseSqlite(_connection).Options;
        _db = new BillingDbContext(options);
        _db.Database.EnsureCreated();
        _gateway = new SqlReminderGateway(_db);
    }

    [Fact]
    public void ThirdReminderClosesTheReminder()
    {
        AddReminder(1, daysOverdue: 10, sentCount: 2);

        _gateway.MarkSentIfAllowed(1);

        Assert.Equal(1, _db.Reminders.Find(1)!.StatusCd);
    }

    [Fact]
    public void FourthReminderIsRefused()
    {
        AddReminder(2, daysOverdue: 10, sentCount: 3);

        Assert.False(_gateway.MarkSentIfAllowed(2));
    }

    [Fact]
    public void InvoicesInsideTheGracePeriodAreNotOverdue()
    {
        AddReminder(3, daysOverdue: 2, sentCount: 0);

        Assert.Empty(_gateway.FindOverdue());
    }

    private void AddReminder(int id, int daysOverdue, int sentCount)
    {
        _db.Reminders.Add(new Reminder
        {
            ReminderId = id,
            InvRef = $"INV-{id}",
            CustEmail = "ap@example.com",
            DueDt = DateTime.UtcNow.AddDays(-daysOverdue),
            AmtCents = 25_000,
            SentCnt = sentCount,
        });
        _db.SaveChanges();
    }

    public void Dispose()
    {
        _db.Dispose();
        _connection.Dispose();
    }
}
CS
