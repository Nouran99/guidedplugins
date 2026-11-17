#!/usr/bin/env bash
set -e
mkdir -p src/Alerts
cat > src/Alerts/Channels.cs <<'CS'
using System;
using System.IO;
using System.Threading;

namespace Alerts;

public record Recipient(string Name, string Email, string Phone);

public abstract class Channel
{
    public string? Subject { get; set; }
    public string? Attachment { get; protected set; }

    public abstract string Name { get; }

    public virtual void Attach(string path)
    {
        Attachment = path;
    }

    public abstract bool Send(Recipient to, string text);
}

public class EmailChannel : Channel
{
    private readonly IMailTransport _mail;

    public EmailChannel(IMailTransport mail)
    {
        _mail = mail;
    }

    public override string Name => "email";

    public override bool Send(Recipient to, string text)
    {
        for (var attempt = 1; attempt <= 3; attempt++)
        {
            try
            {
                _mail.Deliver(to.Email, Subject ?? "(no subject)", text, Attachment);
                return true;
            }
            catch (IOException)
            {
                Thread.Sleep(200 * attempt);
            }
        }
        return false;
    }
}

public class SmsChannel : Channel
{
    private readonly ISmsTransport _sms;

    public SmsChannel(ISmsTransport sms)
    {
        _sms = sms;
    }

    public override string Name => "sms";

    public override void Attach(string path)
    {
        throw new NotSupportedException("SMS cannot carry attachments");
    }

    public override bool Send(Recipient to, string text)
    {
        for (var attempt = 1; attempt <= 3; attempt++)
        {
            try
            {
                _sms.Submit(to.Phone, text);
                return true;
            }
            catch (IOException)
            {
                Thread.Sleep(200 * attempt);
            }
        }
        return false;
    }
}
CS
cat > src/Alerts/Transports.cs <<'CS'
namespace Alerts;

public interface IMailTransport
{
    void Deliver(string address, string subject, string body, string? attachmentPath);
}

public interface ISmsTransport
{
    void Submit(string phoneNumber, string text);
}

public interface IPushTransport
{
    bool Publish(string deviceToken, string title, string message);
}
CS
cat > src/Alerts/Formatters.cs <<'CS'
using System;

namespace Alerts;

public abstract class Formatter
{
    public abstract string Format(string text, Recipient to);
}

public class EmailFormatter : Formatter
{
    public override string Format(string text, Recipient to)
    {
        return $"Dear {to.Name},\n\n{text}\n\nRegards,\nThe Alerts team";
    }
}

public class SmsFormatter : Formatter
{
    public override string Format(string text, Recipient to)
    {
        var body = $"{to.Name}: {text}";
        return body.Length <= 160 ? body : body.Substring(0, 157) + "...";
    }
}

public static class ChannelFactory
{
    public static (Channel Channel, Formatter Formatter) Create(
        string kind, IMailTransport mail, ISmsTransport sms)
    {
        switch (kind)
        {
            case "email":
                return (new EmailChannel(mail), new EmailFormatter());
            case "sms":
                return (new SmsChannel(sms), new SmsFormatter());
            default:
                throw new ArgumentException($"unknown channel {kind}");
        }
    }
}
CS
cat > src/Alerts/Delivery.cs <<'CS'
using System;
using System.Collections.Generic;
using System.IO;

namespace Alerts;

public class PushSender
{
    private readonly IPushTransport _push;

    public PushSender(IPushTransport push)
    {
        _push = push;
    }

    public void Notify(string deviceToken, string title, string message)
    {
        if (!_push.Publish(deviceToken, title, message))
        {
            throw new IOException("push failed for " + deviceToken);
        }
    }
}

public class AlertGateway
{
    private readonly Dictionary<string, Channel> _channels = new();
    private readonly Dictionary<string, Formatter> _formatters = new();
    private readonly PushSender _push;
    private int _sent;

    public AlertGateway(IMailTransport mail, ISmsTransport sms, PushSender push)
    {
        foreach (var kind in new[] { "email", "sms" })
        {
            var (channel, formatter) = ChannelFactory.Create(kind, mail, sms);
            _channels[kind] = channel;
            _formatters[kind] = formatter;
        }
        _push = push;
    }

    public bool SendEmail(Recipient to, string text) => Deliver("email", to, text);

    public bool SendSms(Recipient to, string text) => Deliver("sms", to, text);

    public void SendPush(string deviceToken, string title, string message) =>
        _push.Notify(deviceToken, title, message);

    public int SentCount => _sent;

    private bool Deliver(string kind, Recipient to, string text)
    {
        var body = _formatters[kind].Format(text, to);
        var ok = _channels[kind].Send(to, body);
        if (ok)
        {
            _sent++;
        }
        return ok;
    }

    private static int BackoffMillis(int attempt)
    {
        return Math.Min(200 * attempt, 2000);
    }
}

public class AlertService
{
    private readonly AlertGateway _gateway;

    public AlertService(AlertGateway gateway)
    {
        _gateway = gateway;
    }

    public bool SendEmail(Recipient to, string text) => _gateway.SendEmail(to, text);

    public bool SendSms(Recipient to, string text) => _gateway.SendSms(to, text);

    public void SendPush(string deviceToken, string title, string message) =>
        _gateway.SendPush(deviceToken, title, message);

    public int SentCount => _gateway.SentCount;
}
CS
