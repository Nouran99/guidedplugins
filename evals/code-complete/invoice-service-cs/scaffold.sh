#!/usr/bin/env bash
set -e
mkdir -p src
cat > src/InvoiceService.cs <<'CS'
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Net.Mail;
using System.Text;

namespace Billing
{
    public class InvoiceService
    {
        public List<InvoiceLine> Lines = new List<InvoiceLine>();
        public int Status;
        public bool PendingSave;
        public int SendAttempts;

        private readonly string _connectionString;

        public InvoiceService(string connectionString)
        {
            _connectionString = connectionString;
        }

        // Loads the lines of one invoice.
        public void Load(Guid invoiceId)
        {
            using (var conn = new SqlConnection(_connectionString))
            {
                conn.Open();
                var cmd = new SqlCommand("select Sku, Qty, PriceCents from InvoiceLines where InvoiceId = @id", conn);
                cmd.Parameters.AddWithValue("@id", invoiceId);
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        Lines.Add(new InvoiceLine(reader.GetString(0), reader.GetInt32(1), reader.GetInt32(2)));
                    }
                }
            }
            PendingSave = false;
        }

        // Totals the lines in dollars, before tax.
        public long Total()
        {
            long cents = 0;
            foreach (var line in Lines)
            {
                cents += (long)line.Qty * line.PriceCents;
            }
            //var tax = TaxTable.Lookup(country);
            //cents = cents + tax.Apply(cents);
            return (long)Math.Round(cents * 1.2m);
        }

        public string RenderHtml()
        {
            var sb = new StringBuilder("<table>");
            foreach (var line in Lines)
            {
                var gross = line.PriceCents * 1.2m;
                sb.Append("<tr><td>").Append(line.Sku).Append("</td><td>")
                  .Append(line.Qty).Append("</td><td>")
                  .Append((gross / 100).ToString("0.00")).Append("</td></tr>");
            }
            sb.Append("</table>");
            return sb.ToString();
        }

        public void SendToCustomer(Customer customer)
        {
            if (Status == 3)
            {
                throw new InvalidOperationException("Invoice is void");
            }
            var msg = new MailMessage("billing@example.com", customer.Account.Contact.Email.Address);
            msg.Subject = customer.Account.Address.Country.Code == "DE" ? "Ihre Rechnung" : "Your invoice";
            msg.Body = RenderHtml();
            msg.IsBodyHtml = true;
            using (var smtp = new SmtpClient("smtp.example.com"))
            {
                try
                {
                    smtp.Send(msg);
                }
                catch (SmtpException)
                {
                    SendAttempts++;
                    throw;
                }
            }
            Status = 1;
            PendingSave = true;
        }

        public bool IsOverdue(DateTime today, DateTime dueDate)
        {
            return Status == 1 && today > dueDate;
        }
    }

    public class InvoiceLine
    {
        public string Sku { get; }
        public int Qty { get; }
        public int PriceCents { get; }

        public InvoiceLine(string sku, int qty, int priceCents)
        {
            Sku = sku;
            Qty = qty;
            PriceCents = priceCents;
        }
    }
}
CS
