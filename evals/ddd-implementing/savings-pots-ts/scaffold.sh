#!/usr/bin/env bash
set -e
mkdir -p src/pots
cat > src/pots/pot.ts <<'TS'
export type PotEvent =
  | { type: 'PotOpened'; potId: string; ownerId: string; name: string; targetCents: number }
  | { type: 'MoneyDeposited'; potId: string; amountCents: number }
  | { type: 'MoneyWithdrawn'; potId: string; amountCents: number };

// A savings pot: money an owner sets aside towards a target.
export class Pot {
  id = '';
  ownerId = '';
  name = '';
  targetCents = 0;
  balanceCents = 0;
  version = 0;
  updatedAt = new Date(0);
  private uncommitted: PotEvent[] = [];

  static open(potId: string, ownerId: string, name: string, targetCents: number): Pot {
    const pot = new Pot();
    pot.record({ type: 'PotOpened', potId, ownerId, name, targetCents });
    return pot;
  }

  static replay(events: PotEvent[]): Pot {
    const pot = new Pot();
    for (const event of events) {
      pot.apply(event);
    }
    return pot;
  }

  deposit(amountCents: number): void {
    this.record({ type: 'MoneyDeposited', potId: this.id, amountCents });
  }

  withdraw(amountCents: number): void {
    this.record({ type: 'MoneyWithdrawn', potId: this.id, amountCents });
  }

  takeEvents(): PotEvent[] {
    const events = this.uncommitted;
    this.uncommitted = [];
    return events;
  }

  private record(event: PotEvent): void {
    this.apply(event);
    this.uncommitted.push(event);
  }

  private apply(event: PotEvent): void {
    switch (event.type) {
      case 'PotOpened':
        this.id = event.potId;
        this.ownerId = event.ownerId;
        this.name = event.name;
        this.targetCents = event.targetCents;
        break;
      case 'MoneyDeposited':
        this.balanceCents += event.amountCents;
        break;
      case 'MoneyWithdrawn':
        if (event.amountCents > this.balanceCents) {
          throw new Error('insufficient funds');
        }
        this.balanceCents -= event.amountCents;
        break;
    }
    this.updatedAt = new Date();
    this.version += 1;
  }
}
TS
cat > src/pots/event-store.ts <<'TS'
import { AsyncLocalStorage } from 'node:async_hooks';
import type { Pool } from 'pg';

export const tenantContext = new AsyncLocalStorage<{ tenantId: string }>();

function currentTenant(): string {
  const store = tenantContext.getStore();
  if (!store) {
    throw new Error('no tenant in context');
  }
  return store.tenantId;
}

export class EventStore {
  constructor(private readonly pool: Pool) {}

  async append(streamId: string, events: object[]): Promise<void> {
    const tenantId = currentTenant();
    for (const event of events) {
      await this.pool.query(
        'INSERT INTO events (tenant_id, stream_id, payload) VALUES ($1, $2, $3)',
        [tenantId, streamId, JSON.stringify(event)],
      );
    }
  }

  async load<E>(streamId: string): Promise<E[]> {
    const result = await this.pool.query(
      'SELECT payload FROM events WHERE tenant_id = $1 AND stream_id = $2 ORDER BY seq',
      [currentTenant(), streamId],
    );
    return result.rows.map((row) => row.payload as E);
  }

  async streamIds(prefix: string): Promise<string[]> {
    const result = await this.pool.query(
      'SELECT DISTINCT stream_id FROM events WHERE tenant_id = $1 AND stream_id LIKE $2',
      [currentTenant(), `${prefix}%`],
    );
    return result.rows.map((row) => row.stream_id as string);
  }
}
TS
cat > src/pots/preferences.ts <<'TS'
import type { EventStore } from './event-store';

type Theme = 'light' | 'dark';

export type PreferenceEvent =
  | { type: 'ThemeChanged'; userId: string; theme: Theme }
  | { type: 'LanguageChanged'; userId: string; language: string }
  | { type: 'WeeklyDigestToggled'; userId: string; enabled: boolean };

export class Preferences {
  theme: Theme = 'light';
  language = 'en';
  weeklyDigest = true;

  static replay(events: PreferenceEvent[]): Preferences {
    const prefs = new Preferences();
    for (const event of events) {
      switch (event.type) {
        case 'ThemeChanged':
          prefs.theme = event.theme;
          break;
        case 'LanguageChanged':
          prefs.language = event.language;
          break;
        case 'WeeklyDigestToggled':
          prefs.weeklyDigest = event.enabled;
          break;
      }
    }
    return prefs;
  }
}

export class PreferencesService {
  constructor(private readonly store: EventStore) {}

  async setTheme(userId: string, theme: Theme): Promise<void> {
    await this.store.append(`prefs-${userId}`, [{ type: 'ThemeChanged', userId, theme }]);
  }

  async setLanguage(userId: string, language: string): Promise<void> {
    await this.store.append(`prefs-${userId}`, [{ type: 'LanguageChanged', userId, language }]);
  }

  async setWeeklyDigest(userId: string, enabled: boolean): Promise<void> {
    await this.store.append(`prefs-${userId}`, [{ type: 'WeeklyDigestToggled', userId, enabled }]);
  }

  async get(userId: string): Promise<Preferences> {
    const events = await this.store.load<PreferenceEvent>(`prefs-${userId}`);
    return Preferences.replay(events);
  }
}
TS
cat > src/pots/http.ts <<'TS'
import type { Request, Response } from 'express';
import { Pot, type PotEvent } from './pot';
import type { EventStore } from './event-store';

const streamOf = (potId: string) => `pot-${potId}`;

export function potHandlers(store: EventStore) {
  async function loadPot(potId: string): Promise<Pot> {
    return Pot.replay(await store.load<PotEvent>(streamOf(potId)));
  }

  return {
    async open(req: Request, res: Response): Promise<void> {
      const { ownerId, name, targetCents } = req.body;
      const pot = Pot.open(crypto.randomUUID(), ownerId, name, targetCents);
      await store.append(streamOf(pot.id), pot.takeEvents());
      res.status(201).json(pot);
    },

    async deposit(req: Request, res: Response): Promise<void> {
      const pot = await loadPot(req.params.id);
      pot.deposit(req.body.amountCents);
      await store.append(streamOf(pot.id), pot.takeEvents());
      res.json(pot);
    },

    async withdraw(req: Request, res: Response): Promise<void> {
      const pot = await loadPot(req.params.id);
      pot.withdraw(req.body.amountCents);
      await store.append(streamOf(pot.id), pot.takeEvents());
      res.json(pot);
    },

    async get(req: Request, res: Response): Promise<void> {
      res.json(await loadPot(req.params.id));
    },

    async overview(_req: Request, res: Response): Promise<void> {
      const streams = await store.streamIds('pot-');
      const pots = await Promise.all(streams.map((s) => store.load<PotEvent>(s).then(Pot.replay)));
      res.json(
        pots.map((p) => ({
          id: p.id,
          name: p.name,
          balanceCents: p.balanceCents,
          targetCents: p.targetCents,
        })),
      );
    },
  };
}
TS
