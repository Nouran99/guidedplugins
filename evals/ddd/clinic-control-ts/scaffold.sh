#!/usr/bin/env bash
set -e
mkdir -p src/clinic
cat > src/clinic/README.md <<'MD'
# Clinic scheduling

Bounded context for appointments: a patient is given a slot, and the appointment ends as completed, cancelled or a no-show.

- Owner: the scheduling team.
- Subdomain: core. How reliably we fill and protect the clinic's day is why practices choose us, so this is where the modeling effort goes.
- Capacity is out of scope: which doctor or room serves a slot is decided by the practice manager's rota. Rooms are reference data kept by the practice manager: plain data, no rules (rooms.ts).
- Upstream: the old practice-management system. We are downstream of it and keep our model apart with a translator (an anticorruption layer): its appointment history comes in through intake-translator.ts and its codes appear nowhere else.
- Billing is a separate context with its own model and is not part of this change. Scheduling never calls it.
- Terms: appointment, patient, slot, book, cancel, late cancellation, complete, no-show.
MD
cat > src/clinic/slot.ts <<'TS'
// A slot is a stretch of the clinic's day. It is a value: it has no identity, only a start and a length.

/** A visit lasts 15 to 120 minutes in steps of 15. Longer treatments are booked as a procedure, not here. */
const MIN_MINUTES = 15;
const MAX_MINUTES = 120;
const STEP_MINUTES = 15;

const MS_PER_HOUR = 3_600_000;

export class InvalidSlot extends Error {}

export class Slot {
  readonly #startsAtMs: number;
  readonly minutes: number;

  constructor(startsAt: Date, minutes: number) {
    if (Number.isNaN(startsAt.getTime())) {
      throw new InvalidSlot('a slot needs a start time');
    }
    const lengthIsValid =
      Number.isInteger(minutes) && minutes >= MIN_MINUTES && minutes <= MAX_MINUTES && minutes % STEP_MINUTES === 0;
    if (!lengthIsValid) {
      throw new InvalidSlot(`a slot lasts ${MIN_MINUTES} to ${MAX_MINUTES} minutes in steps of ${STEP_MINUTES}`);
    }
    this.#startsAtMs = startsAt.getTime();
    this.minutes = minutes;
  }

  get startsAt(): Date {
    return new Date(this.#startsAtMs);
  }

  hasStartedBy(moment: Date): boolean {
    return this.#startsAtMs <= moment.getTime();
  }

  hoursUntilStart(now: Date): number {
    return (this.#startsAtMs - now.getTime()) / MS_PER_HOUR;
  }

  equals(other: Slot): boolean {
    return this.#startsAtMs === other.#startsAtMs && this.minutes === other.minutes;
  }
}
TS
cat > src/clinic/appointment.ts <<'TS'
// Scheduling context. An appointment is a patient's booking of one slot with the clinic.

import type { Slot } from './slot.ts';

export type AppointmentId = string & { readonly __brand: 'AppointmentId' };
export type PatientId = string & { readonly __brand: 'PatientId' };

export const asAppointmentId = (value: string): AppointmentId => value as AppointmentId;
export const asPatientId = (value: string): PatientId => value as PatientId;

/** Cancelling less than this long before the start is a late cancellation. */
const LATE_CANCELLATION_NOTICE_HOURS = 24;

export type AppointmentStatus = 'booked' | 'cancelled' | 'completed' | 'no-show';

export class CannotBookInThePast extends Error {}

export class InvalidTransition extends Error {
  constructor(id: AppointmentId, status: AppointmentStatus, attempt: string) {
    super(`appointment ${id} is ${status} and cannot be ${attempt}`);
  }
}

export interface StoredAppointment {
  id: AppointmentId;
  patientId: PatientId;
  slot: Slot;
  status: AppointmentStatus;
  cancelledLate: boolean;
}

export class Appointment {
  readonly id: AppointmentId;
  readonly patientId: PatientId;
  readonly slot: Slot;
  #status: AppointmentStatus;
  #cancelledLate: boolean;

  private constructor(stored: StoredAppointment) {
    this.id = stored.id;
    this.patientId = stored.patientId;
    this.slot = stored.slot;
    this.#status = stored.status;
    this.#cancelledLate = stored.cancelledLate;
  }

  /** A new appointment: the creation rules run here and nowhere else. */
  static book(id: AppointmentId, patientId: PatientId, slot: Slot, now: Date): Appointment {
    if (slot.hasStartedBy(now)) {
      throw new CannotBookInThePast(`a slot starting at ${slot.startsAt.toISOString()} has already started`);
    }
    return new Appointment({ id, patientId, slot, status: 'booked', cancelledLate: false });
  }

  /** A stored appointment: it may have been booked under older rules, so the creation rules do not run again. */
  static reconstitute(stored: StoredAppointment): Appointment {
    return new Appointment(stored);
  }

  get status(): AppointmentStatus {
    return this.#status;
  }

  get wasCancelledLate(): boolean {
    return this.#status === 'cancelled' && this.#cancelledLate;
  }

  cancel(now: Date): void {
    this.#requireBooked('cancelled');
    if (this.slot.hasStartedBy(now)) {
      throw new InvalidTransition(this.id, this.#status, 'cancelled after its start');
    }
    this.#cancelledLate = this.slot.hoursUntilStart(now) < LATE_CANCELLATION_NOTICE_HOURS;
    this.#status = 'cancelled';
  }

  complete(now: Date): void {
    this.#requireBookedAndStarted(now, 'completed');
    this.#status = 'completed';
  }

  markNoShow(now: Date): void {
    this.#requireBookedAndStarted(now, 'marked as a no-show');
    this.#status = 'no-show';
  }

  equals(other: Appointment): boolean {
    return this.id === other.id;
  }

  #requireBooked(attempt: string): void {
    if (this.#status !== 'booked') {
      throw new InvalidTransition(this.id, this.#status, attempt);
    }
  }

  #requireBookedAndStarted(now: Date, attempt: string): void {
    this.#requireBooked(attempt);
    if (!this.slot.hasStartedBy(now)) {
      throw new InvalidTransition(this.id, this.#status, `${attempt} before its start`);
    }
  }
}
TS
cat > src/clinic/scheduling.ts <<'TS'
import { Appointment, type AppointmentId, type PatientId } from './appointment.ts';
import { Slot } from './slot.ts';

/** Defined with the model. The database and in-memory implementations live elsewhere. */
export interface Appointments {
  get(id: AppointmentId): Promise<Appointment>;
  add(appointment: Appointment): Promise<void>;
  save(appointment: Appointment): Promise<void>;
}

export interface BookAppointment {
  id: AppointmentId;
  patientId: PatientId;
  startsAt: Date;
  minutes: number;
}

export class Scheduling {
  readonly #appointments: Appointments;
  readonly #clock: () => Date;

  constructor(appointments: Appointments, clock: () => Date) {
    this.#appointments = appointments;
    this.#clock = clock;
  }

  async book(command: BookAppointment): Promise<void> {
    const slot = new Slot(command.startsAt, command.minutes);
    const appointment = Appointment.book(command.id, command.patientId, slot, this.#clock());
    await this.#appointments.add(appointment);
  }

  async cancel(id: AppointmentId): Promise<void> {
    const appointment = await this.#appointments.get(id);
    appointment.cancel(this.#clock());
    await this.#appointments.save(appointment);
  }

  async complete(id: AppointmentId): Promise<void> {
    const appointment = await this.#appointments.get(id);
    appointment.complete(this.#clock());
    await this.#appointments.save(appointment);
  }

  async markNoShow(id: AppointmentId): Promise<void> {
    const appointment = await this.#appointments.get(id);
    appointment.markNoShow(this.#clock());
    await this.#appointments.save(appointment);
  }
}
TS
cat > src/clinic/intake-translator.ts <<'TS'
import { Appointment, type AppointmentStatus, asAppointmentId, asPatientId } from './appointment.ts';
import { Slot } from './slot.ts';

/** A row of the old practice-management system, exactly as its export writes it. START_TS is ISO 8601 in UTC. */
export interface LegacyAppointmentRow {
  APPT_ID: string;
  PAT_NO: string;
  START_TS: string;
  LEN_MIN: number;
  STAT: string;
}

export class UnknownLegacyStatus extends Error {
  constructor(code: string) {
    super(`unknown legacy appointment status: ${code}`);
  }
}

const STATUS_BY_LEGACY_CODE = new Map<string, AppointmentStatus>([
  ['B', 'booked'],
  ['C', 'cancelled'],
  ['D', 'completed'],
  ['N', 'no-show'],
]);

export function statusFromLegacy(code: string): AppointmentStatus {
  const status = STATUS_BY_LEGACY_CODE.get(code);
  if (status === undefined) {
    throw new UnknownLegacyStatus(code);
  }
  return status;
}

/**
 * Turns one exported row into an appointment of this context. Imported ids get a prefix so they
 * never clash with ours. Patient numbers are shared with the old system and kept as they are.
 * The old system did not record late cancellations, so imported cancellations are never late.
 */
export function appointmentFromLegacy(row: LegacyAppointmentRow): Appointment {
  return Appointment.reconstitute({
    id: asAppointmentId(`legacy-${row.APPT_ID}`),
    patientId: asPatientId(row.PAT_NO),
    slot: new Slot(new Date(row.START_TS), row.LEN_MIN),
    status: statusFromLegacy(row.STAT),
    cancelledLate: false,
  });
}
TS
cat > src/clinic/rooms.ts <<'TS'
// Reference data kept by the practice manager. It has no rules and no lifecycle of its own.

export interface Room {
  code: string;
  name: string;
  hasXray: boolean;
}

export const ROOMS: readonly Room[] = [
  { code: 'R1', name: 'Consulting room 1', hasXray: false },
  { code: 'R2', name: 'Consulting room 2', hasXray: false },
  { code: 'XR', name: 'Imaging', hasXray: true },
];

export function roomByCode(code: string): Room | undefined {
  return ROOMS.find((room) => room.code === code);
}
TS
cat > src/clinic/appointment.test.ts <<'TS'
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { Appointment, CannotBookInThePast, InvalidTransition, asAppointmentId, asPatientId } from './appointment.ts';
import { UnknownLegacyStatus, appointmentFromLegacy, statusFromLegacy } from './intake-translator.ts';
import { Scheduling, type Appointments } from './scheduling.ts';
import { InvalidSlot, Slot } from './slot.ts';

const NOW = new Date('2026-03-02T09:00:00Z');
const TOMORROW_8AM = new Date('2026-03-03T08:00:00Z');
const EXACTLY_A_DAY_AHEAD = new Date('2026-03-03T09:00:00Z');
const NEXT_WEEK = new Date('2026-03-09T10:00:00Z');
const FORTY_MINUTES_AFTER_TOMORROW_8AM = new Date('2026-03-03T08:40:00Z');
const id = asAppointmentId('a-1');
const patient = asPatientId('p-1');

const bookedFor = (startsAt: Date) => Appointment.book(id, patient, new Slot(startsAt, 30), NOW);

describe('a slot', () => {
  it('lasts 15 to 120 minutes in steps of 15', () => {
    for (const minutes of [10, 40, 135]) assert.throws(() => new Slot(NEXT_WEEK, minutes), InvalidSlot);
    assert.equal(new Slot(NEXT_WEEK, 45).minutes, 45);
  });

  it('needs a start time', () => {
    assert.throws(() => new Slot(new Date('not a date'), 30), InvalidSlot);
  });

  it('equals another slot with the same start and length', () => {
    assert.ok(new Slot(NEXT_WEEK, 30).equals(new Slot(new Date(NEXT_WEEK), 30)));
    assert.ok(!new Slot(NEXT_WEEK, 30).equals(new Slot(NEXT_WEEK, 45)));
  });
});

describe('an appointment', () => {
  it('cannot be booked for a slot that has already started', () => {
    assert.throws(() => Appointment.book(id, patient, new Slot(NOW, 30), NOW), CannotBookInThePast);
  });

  it('cancelled a week ahead is not a late cancellation', () => {
    const appointment = bookedFor(NEXT_WEEK);
    appointment.cancel(NOW);
    assert.equal(appointment.status, 'cancelled');
    assert.equal(appointment.wasCancelledLate, false);
  });

  it('cancelled less than 24 hours ahead is a late cancellation', () => {
    const appointment = bookedFor(TOMORROW_8AM);
    appointment.cancel(NOW);
    assert.equal(appointment.wasCancelledLate, true);
  });

  it('cancelled exactly 24 hours ahead is not a late cancellation', () => {
    const appointment = bookedFor(EXACTLY_A_DAY_AHEAD);
    appointment.cancel(NOW);
    assert.equal(appointment.wasCancelledLate, false);
  });

  it('cannot be cancelled twice', () => {
    const appointment = bookedFor(NEXT_WEEK);
    appointment.cancel(NOW);
    assert.throws(() => appointment.cancel(NOW), InvalidTransition);
  });

  it('cannot be cancelled once its slot has started', () => {
    assert.throws(() => bookedFor(TOMORROW_8AM).cancel(FORTY_MINUTES_AFTER_TOMORROW_8AM), InvalidTransition);
  });

  it('is completed after the patient was seen', () => {
    const appointment = bookedFor(TOMORROW_8AM);
    appointment.complete(FORTY_MINUTES_AFTER_TOMORROW_8AM);
    assert.equal(appointment.status, 'completed');
  });

  it('cannot be completed before it starts', () => {
    assert.throws(() => bookedFor(NEXT_WEEK).complete(NOW), InvalidTransition);
  });

  it('cannot be completed once it was cancelled', () => {
    const appointment = bookedFor(TOMORROW_8AM);
    appointment.cancel(NOW);
    assert.throws(() => appointment.complete(FORTY_MINUTES_AFTER_TOMORROW_8AM), InvalidTransition);
  });

  it('becomes a no-show when the patient does not come after the start', () => {
    const appointment = bookedFor(TOMORROW_8AM);
    appointment.markNoShow(FORTY_MINUTES_AFTER_TOMORROW_8AM);
    assert.equal(appointment.status, 'no-show');
  });

  it('cannot be marked as a no-show before its start', () => {
    assert.throws(() => bookedFor(NEXT_WEEK).markNoShow(NOW), InvalidTransition);
  });

  it('cannot be marked as a no-show once it was completed', () => {
    const appointment = bookedFor(TOMORROW_8AM);
    appointment.complete(FORTY_MINUTES_AFTER_TOMORROW_8AM);
    assert.throws(() => appointment.markNoShow(FORTY_MINUTES_AFTER_TOMORROW_8AM), InvalidTransition);
  });
});

describe('the old practice-management system', () => {
  it('has four statuses that map to ours', () => {
    assert.equal(statusFromLegacy('B'), 'booked');
    assert.equal(statusFromLegacy('C'), 'cancelled');
    assert.equal(statusFromLegacy('D'), 'completed');
    assert.equal(statusFromLegacy('N'), 'no-show');
  });

  it('is refused when it sends a status we do not know', () => {
    assert.throws(() => statusFromLegacy('Q'), UnknownLegacyStatus);
    assert.throws(() => statusFromLegacy(''), UnknownLegacyStatus);
  });

  it('can be imported as a completed appointment from the past, under a prefixed id', () => {
    const row = { APPT_ID: 'L-77', PAT_NO: '1042', START_TS: '2019-05-06T08:30:00Z', LEN_MIN: 30, STAT: 'D' };
    const appointment = appointmentFromLegacy(row);
    assert.equal(appointment.status, 'completed');
    assert.equal(appointment.id, 'legacy-L-77');
    assert.equal(appointment.patientId, '1042');
  });
});

describe('scheduling', () => {
  class InMemoryAppointments implements Appointments {
    readonly stored = new Map<string, Appointment>();

    async get(appointmentId: Appointment['id']): Promise<Appointment> {
      const found = this.stored.get(appointmentId);
      if (found === undefined) throw new Error(`no appointment ${appointmentId}`);
      return found;
    }

    async add(appointment: Appointment): Promise<void> {
      this.stored.set(appointment.id, appointment);
    }

    async save(appointment: Appointment): Promise<void> {
      this.stored.set(appointment.id, appointment);
    }
  }

  it('books an appointment and keeps it', async () => {
    const appointments = new InMemoryAppointments();
    await new Scheduling(appointments, () => NOW).book({ id, patientId: patient, startsAt: NEXT_WEEK, minutes: 30 });
    assert.equal((await appointments.get(id)).status, 'booked');
  });

  it('cancels a booked appointment and keeps the change', async () => {
    const appointments = new InMemoryAppointments();
    const scheduling = new Scheduling(appointments, () => NOW);
    await scheduling.book({ id, patientId: patient, startsAt: NEXT_WEEK, minutes: 30 });
    await scheduling.cancel(id);
    assert.equal((await appointments.get(id)).status, 'cancelled');
  });
});
TS
