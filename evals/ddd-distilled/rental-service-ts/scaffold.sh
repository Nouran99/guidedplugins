#!/usr/bin/env bash
set -e
mkdir -p src/rentals
cat > src/rentals/rental.ts <<'TS'
export class Rental {
  id: string;
  customerId: string;
  vehicleClass: string;
  driverAge: number;
  startsAt: Date;
  endsAt: Date;
  dailyRate: number;
  currency: string;
  deposit: number;
  fee: number;
  status: string;

  constructor(
    id: string,
    customerId: string,
    vehicleClass: string,
    driverAge: number,
    startsAt: Date,
    endsAt: Date,
    dailyRate: number,
    currency: string,
  ) {
    this.id = id;
    this.customerId = customerId;
    this.vehicleClass = vehicleClass;
    this.driverAge = driverAge;
    this.startsAt = startsAt;
    this.endsAt = endsAt;
    this.dailyRate = dailyRate;
    this.currency = currency;
    this.deposit = 0;
    this.fee = 0;
    this.status = 'booked';
  }
}

export interface RentalRepository {
  findById(id: string): Promise<Rental>;
  findByCustomer(customerId: string): Promise<Rental[]>;
  save(rental: Rental): Promise<void>;
}
TS
cat > src/rentals/rental-service.ts <<'TS'
import { Request } from 'express';
import { EventBus } from '../messaging/event-bus';
import { Rental, RentalRepository } from './rental';

export class RentalService {
  constructor(
    private readonly rentals: RentalRepository,
    private readonly bus: EventBus,
  ) {}

  async pickUp(req: Request): Promise<Rental> {
    const rental = await this.rentals.findById(req.params.id);
    const agent = req.headers['x-agent-id'] as string;
    if (rental.status !== 'booked') {
      throw new Error(`rental ${rental.id} is not waiting for pickup`);
    }
    if (new Date() < rental.startsAt) {
      throw new Error('pickup is before the start of the rental');
    }
    if (rental.driverAge < 25 || rental.vehicleClass === 'premium') {
      rental.deposit = rental.currency === 'EUR' ? 500 : 550;
    }
    rental.status = 'active';
    await this.rentals.save(rental);
    await this.bus.publish({
      type: 'RentalUpdated',
      rentalId: rental.id,
      field: 'status',
      from: 'booked',
      to: 'active',
      by: agent,
    });
    return rental;
  }

  async returnVehicle(req: Request): Promise<Rental> {
    const rental = await this.rentals.findById(req.params.id);
    const returnedAt = new Date(req.body.returnedAt);
    if (rental.status !== 'active') {
      throw new Error(`rental ${rental.id} is not active`);
    }
    const hoursLate = (returnedAt.getTime() - rental.endsAt.getTime()) / 3600000;
    if (hoursLate > 1) {
      rental.fee = Math.round(rental.dailyRate * 0.25 * Math.ceil(hoursLate) * 100) / 100;
    }
    rental.status = 'returned';
    await this.rentals.save(rental);
    await this.bus.publish({
      type: 'RentalUpdated',
      rentalId: rental.id,
      field: 'status',
      from: 'active',
      to: 'returned',
    });
    return rental;
  }

  async cancel(id: string, byCustomer: boolean): Promise<void> {
    const rental = await this.rentals.findById(id);
    if (rental.status === 'returned' || rental.status === 'cancelled') {
      throw new Error(`rental ${rental.id} can no longer be cancelled`);
    }
    const hoursToStart = (rental.startsAt.getTime() - Date.now()) / 3600000;
    if (byCustomer && hoursToStart < 48) {
      rental.fee = Math.round(rental.dailyRate * 100) / 100;
    }
    const previous = rental.status;
    rental.status = 'cancelled';
    await this.rentals.save(rental);
    await this.bus.publish({
      type: 'RentalUpdated',
      rentalId: rental.id,
      field: 'status',
      from: previous,
      to: 'cancelled',
    });
  }

  async history(customerId: string): Promise<Rental[]> {
    return this.rentals.findByCustomer(customerId);
  }
}
TS
