#!/usr/bin/env bash
set -e
mkdir -p src/notify/report
cat > src/notify/notifier.go <<'GO'
package notify

import (
	"context"
	"fmt"
	"time"

	"github.com/sendgrid/rest"
	"github.com/sendgrid/sendgrid-go"
	"github.com/sendgrid/sendgrid-go/helpers/mail"
)

// Provider delivers one message.
type Provider interface {
	Deliver(ctx context.Context, msg *mail.SGMailV3) (*rest.Response, error)
}

type sendgridProvider struct {
	client *sendgrid.Client
}

func (p *sendgridProvider) Deliver(ctx context.Context, msg *mail.SGMailV3) (*rest.Response, error) {
	return p.client.SendWithContext(ctx, msg)
}

func providerFor(opts Options) (Provider, error) {
	switch opts.Provider {
	case "sendgrid":
		return &sendgridProvider{client: sendgrid.NewSendClient(opts.APIKey)}, nil
	default:
		return nil, fmt.Errorf("unknown provider %q", opts.Provider)
	}
}

// Options configures a Notifier.
type Options struct {
	Provider    string
	APIKey      string
	Timeout     time.Duration
	BatchSize   int
	Jitter      bool
	UseHTTP2    bool
	TrackOpens  bool
	TrackClicks bool
	SandboxMode bool
}

type Notifier struct {
	opts     Options
	provider Provider
	pending  []*mail.SGMailV3
	Sent     int
	Failed   int
}

func New(opts Options) (*Notifier, error) {
	p, err := providerFor(opts)
	if err != nil {
		return nil, err
	}
	return &Notifier{opts: opts, provider: p}, nil
}

// Send delivers msg. With BatchSize above one, messages are held until the batch
// is full; call Flush before shutting down.
func (n *Notifier) Send(ctx context.Context, msg *mail.SGMailV3) error {
	if n.opts.BatchSize > 1 {
		n.pending = append(n.pending, msg)
		if len(n.pending) < n.opts.BatchSize {
			return nil
		}
		return n.Flush(ctx)
	}
	return n.deliver(ctx, msg)
}

// Flush delivers everything that is still waiting.
func (n *Notifier) Flush(ctx context.Context) error {
	batch := n.pending
	n.pending = nil
	for _, m := range batch {
		if err := n.deliver(ctx, m); err != nil {
			return err
		}
	}
	return nil
}

func (n *Notifier) deliver(ctx context.Context, msg *mail.SGMailV3) error {
	resp, err := n.provider.Deliver(ctx, msg)
	if err == nil && resp.StatusCode >= 300 {
		err = fmt.Errorf("sendgrid: status %d", resp.StatusCode)
	}
	if err != nil {
		n.Failed++
		return err
	}
	n.Sent++
	return nil
}
GO
cat > src/notify/wire.go <<'GO'
package notify

import "os"

func FromEnv() (*Notifier, error) {
	return New(Options{
		Provider:  "sendgrid",
		APIKey:    os.Getenv("SENDGRID_API_KEY"),
		BatchSize: 20,
	})
}
GO
cat > src/notify/messages.go <<'GO'
package notify

import (
	"context"

	"github.com/sendgrid/sendgrid-go/helpers/mail"
)

type User struct {
	Name  string
	Email string
}

func SendWelcome(ctx context.Context, n *Notifier, user User) error {
	msg := mail.NewV3Mail()
	msg.SetFrom(mail.NewEmail("Acme", "hello@acme.example"))
	msg.SetTemplateID("d-8f3a21c0")
	p := mail.NewPersonalization()
	p.AddTos(mail.NewEmail(user.Name, user.Email))
	p.SetDynamicTemplateData("name", user.Name)
	msg.AddPersonalizations(p)
	return n.Send(ctx, msg)
}

func SendInvoiceReady(ctx context.Context, n *Notifier, user User, invoiceID string) error {
	msg := mail.NewV3Mail()
	msg.SetFrom(mail.NewEmail("Acme", "hello@acme.example"))
	msg.SetTemplateID("d-4c7e9051")
	p := mail.NewPersonalization()
	p.AddTos(mail.NewEmail(user.Name, user.Email))
	p.SetDynamicTemplateData("invoice_id", invoiceID)
	msg.AddPersonalizations(p)
	return n.Send(ctx, msg)
}
GO
cat > src/notify/report/report.go <<'GO'
package report

import (
	"fmt"

	"example.com/app/notify"
)

// Summary describes the deliveries since the previous call and starts a new window.
func Summary(n *notify.Notifier) string {
	line := fmt.Sprintf("sent=%d failed=%d", n.Sent, n.Failed)
	n.Sent = 0
	n.Failed = 0
	return line
}
GO
