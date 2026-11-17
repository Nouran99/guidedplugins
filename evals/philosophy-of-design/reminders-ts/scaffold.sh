#!/usr/bin/env bash
set -e
mkdir -p src/infra src/reminders
cat > src/infra/kv-client.ts <<'TS'
export interface KeyValueClient {
  put(key: string, value: string): Promise<void>;
  delete(key: string): Promise<boolean>;
  scan(prefix: string): Promise<Array<{ key: string; value: string }>>;
}
TS
cat > src/infra/mailer.ts <<'TS'
export interface Mailer {
  send(to: string, subject: string, body: string, priority: 'high' | 'normal'): Promise<void>;
}
TS
cat > src/infra/time.d.ts <<'TS'
/** Reads a wall-clock string such as "2026-03-02 09:30" in an IANA zone and returns that instant. */
export declare function zonedToUtc(local: string, zone: string): Date;
TS
cat > src/reminders/reminder-store.ts <<'TS'
import { KeyValueClient } from '../infra/kv-client';

export interface Reminder {
  userId: string;
  dueAt: Date;
  text: string;
}

export class ReminderNotFound extends Error {}

export class ReminderStore {
  constructor(private readonly kv: KeyValueClient) {}

  async save(reminder: Reminder): Promise<void> {
    const key = `reminder:${reminder.userId}:${reminder.dueAt.getTime()}`;
    await this.kv.put(key, `${reminder.userId}|${reminder.dueAt.toISOString()}|${reminder.text}`);
  }

  async listDue(userId: string, before: Date): Promise<string[]> {
    const rows = await this.kv.scan(`reminder:${userId}:`);
    return rows
      .filter((row) => Number(row.key.split(':')[2]) <= before.getTime())
      .map((row) => row.value);
  }

  async remove(userId: string, dueAt: Date): Promise<void> {
    const removed = await this.kv.delete(`reminder:${userId}:${dueAt.getTime()}`);
    if (!removed) {
      throw new ReminderNotFound(`no reminder for ${userId} at ${dueAt.toISOString()}`);
    }
  }
}
TS
cat > src/reminders/reminder-service.ts <<'TS'
import { Reminder, ReminderStore } from './reminder-store';

export class ReminderService {
  constructor(private readonly store: ReminderStore) {}

  create(reminder: Reminder): Promise<void> {
    return this.store.save(reminder);
  }

  due(userId: string, before: Date): Promise<string[]> {
    return this.store.listDue(userId, before);
  }

  cancel(userId: string, dueAt: Date): Promise<void> {
    return this.store.remove(userId, dueAt);
  }
}
TS
cat > src/reminders/digest.ts <<'TS'
import { Mailer } from '../infra/mailer';
import { ReminderService } from './reminder-service';

export class DigestJob {
  private lines: string[] = [];
  private body = '';
  private collected = false;
  private rendered = false;

  constructor(
    private readonly reminders: ReminderService,
    private readonly mailer: Mailer,
  ) {}

  async collect(userId: string, before: Date): Promise<void> {
    this.lines = await this.reminders.due(userId, before);
    this.collected = true;
    this.rendered = false;
  }

  render(): void {
    if (!this.collected) {
      throw new Error('digest has no reminders loaded');
    }
    this.body = this.lines
      .map((line) => {
        const [, dueAt, text] = line.split('|');
        return `${dueAt.slice(0, 16).replace('T', ' ')}  ${text}`;
      })
      .join('\n');
    this.rendered = true;
  }

  async send(to: string, urgent: boolean, plainText: boolean): Promise<void> {
    if (!this.rendered) {
      throw new Error('digest has not been rendered');
    }
    const subject = urgent ? 'Overdue reminders' : 'Your reminders';
    const body = plainText ? this.body : `<pre>${this.body}</pre>`;
    await this.mailer.send(to, subject, body, urgent ? 'high' : 'normal');
  }
}
TS
cat > src/reminders/handlers.ts <<'TS'
import { Mailer } from '../infra/mailer';
import { zonedToUtc } from '../infra/time';
import { DigestJob } from './digest';
import { ReminderService } from './reminder-service';
import { ReminderNotFound } from './reminder-store';

interface Person {
  id: string;
  email: string;
  timezone?: string;
}

export async function createFromWeb(
  user: Person,
  form: { text?: string; due: string },
  reminders: ReminderService,
): Promise<void> {
  const zone = user.timezone || 'UTC';
  const text = String(form.text ?? '').trim().slice(0, 280);
  const dueAt = zonedToUtc(form.due, zone);
  await reminders.create({ userId: user.id, dueAt, text });
}

export async function createFromEmail(
  sender: Person,
  message: { subject?: string; dueHeader: string },
  reminders: ReminderService,
): Promise<void> {
  const zone = sender.timezone || 'UTC';
  const text = String(message.subject ?? '').trim().slice(0, 280);
  const dueAt = zonedToUtc(message.dueHeader, zone);
  await reminders.create({ userId: sender.id, dueAt, text });
}

export async function createFromSlack(
  user: Person,
  command: { text?: string; when: string },
  reminders: ReminderService,
): Promise<void> {
  const zone = user.timezone || 'UTC';
  const text = String(command.text ?? '').trim().slice(0, 280);
  const dueAt = zonedToUtc(command.when, zone);
  await reminders.create({ userId: user.id, dueAt, text });
}

export async function cancelFromWeb(user: Person, dueAt: string, reminders: ReminderService): Promise<void> {
  try {
    await reminders.cancel(user.id, new Date(dueAt));
  } catch (err) {
    if (!(err instanceof ReminderNotFound)) throw err;
  }
}

export async function cancelFromSlack(user: Person, dueAt: string, reminders: ReminderService): Promise<void> {
  try {
    await reminders.cancel(user.id, new Date(dueAt));
  } catch (err) {
    if (!(err instanceof ReminderNotFound)) {
      throw err;
    }
  }
}

export async function sendDigest(user: Person, reminders: ReminderService, mailer: Mailer): Promise<void> {
  const job = new DigestJob(reminders, mailer);
  await job.collect(user.id, new Date());
  job.render();
  await job.send(user.email, false, true);
}
TS
