#!/usr/bin/env bash
set -e
mkdir -p src/orders/migrations

cat > src/orders/order.entity.ts <<'TS'
import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

export interface OrderLine {
  sku: string;
  quantity: number;
  unitCents: number;
}

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  status!: 'PLACED' | 'PAID' | 'SHIPPED' | 'CANCELLED';

  @Column({ name: 'total_cents', type: 'bigint' })
  totalCents!: number;

  @Column()
  currency!: string;

  @Column({ name: 'customer_email' })
  customerEmail!: string;

  @Column({ name: 'internal_notes', nullable: true })
  internalNotes?: string;

  @Column('jsonb')
  lines!: OrderLine[];

  @Column({ name: 'created_at' })
  createdAt!: Date;
}
TS

cat > src/orders/publisher.ts <<'TS'
import { Kafka } from 'kafkajs';
import { Order } from './order.entity';

const kafka = new Kafka({
  clientId: 'orders',
  brokers: (process.env.KAFKA_BROKERS ?? '').split(','),
});
const producer = kafka.producer();

const TOPIC = 'orders';

export async function connectPublisher(): Promise<void> {
  await producer.connect();
}

export async function publishOrderPlaced(order: Order): Promise<void> {
  await producer.send({
    topic: TOPIC,
    messages: [{ value: JSON.stringify({ type: 'OrderPlaced', order }) }],
  });
}

export async function publishOrderShipped(order: Order): Promise<void> {
  await producer.send({
    topic: TOPIC,
    messages: [{ value: JSON.stringify({ type: 'OrderShipped', order }) }],
  });
}

// Asks the inventory service to hold stock for a freshly placed order.
export async function requestStockReservation(order: Order): Promise<void> {
  await producer.send({
    topic: TOPIC,
    messages: [
      {
        value: JSON.stringify({
          type: 'ReserveStock',
          orderId: order.id,
          items: order.lines.map((line) => ({ sku: line.sku, qty: line.quantity })),
        }),
      },
    ],
  });
}
TS

cat > src/orders/inventory-consumer.ts <<'TS'
import { Kafka } from 'kafkajs';
import { Order } from './order.entity';

export interface Db {
  run(sql: string, params: unknown[]): Promise<void>;
}

interface Item {
  sku: string;
  qty: number;
}

type Message =
  | { type: 'ReserveStock'; orderId: string; items: Item[] }
  | { type: 'OrderPlaced'; order: Order }
  | { type: 'OrderShipped'; order: Order };

const kafka = new Kafka({
  clientId: 'inventory',
  brokers: (process.env.KAFKA_BROKERS ?? '').split(','),
});

export async function startInventoryConsumer(db: Db): Promise<void> {
  const consumer = kafka.consumer({ groupId: 'inventory' });
  await consumer.connect();
  await consumer.subscribe({ topic: 'orders' });
  await consumer.run({
    partitionsConsumedConcurrently: 4,
    eachMessage: async ({ message }) => {
      await handleMessage(db, JSON.parse(message.value!.toString()));
    },
  });
}

export async function handleMessage(db: Db, message: Message): Promise<void> {
  switch (message.type) {
    case 'ReserveStock':
      await reserve(db, message.orderId, message.items);
      break;
    case 'OrderShipped':
      await commit(db, message.order);
      break;
    case 'OrderPlaced':
      break;
    default:
      throw new Error(`unexpected message type ${(message as { type: string }).type}`);
  }
}

async function reserve(db: Db, orderId: string, items: Item[]): Promise<void> {
  for (const item of items) {
    await db.run('UPDATE stock SET reserved = reserved + $1 WHERE sku = $2', [item.qty, item.sku]);
  }
  await db.run("INSERT INTO reservations (order_id, state) VALUES ($1, 'HELD')", [orderId]);
}

async function commit(db: Db, order: Order): Promise<void> {
  // The reservation for this order was created when it was placed.
  await db.run("UPDATE reservations SET state = 'COMMITTED' WHERE order_id = $1", [order.id]);
  for (const line of order.lines) {
    await db.run(
      'UPDATE stock SET on_hand = on_hand - $1, reserved = reserved - $1 WHERE sku = $2',
      [line.quantity, line.sku],
    );
  }
}
TS

cat > src/orders/inventory-consumer.test.ts <<'TS'
import { handleMessage } from './inventory-consumer';

function fakeDb() {
  return { run: jest.fn().mockResolvedValue(undefined) };
}

const shippedOrder = {
  id: 'o-1',
  status: 'SHIPPED',
  totalCents: 4200,
  currency: 'EUR',
  customerEmail: 'sam@example.com',
  lines: [{ sku: 'pen', quantity: 2, unitCents: 150 }],
  createdAt: new Date('2026-03-01T10:00:00Z'),
} as any;

describe('inventory consumer', () => {
  it('holds stock for a placed order', async () => {
    const db = fakeDb();
    await handleMessage(db, {
      type: 'ReserveStock',
      orderId: 'o-1',
      items: [{ sku: 'pen', qty: 2 }],
    });
    expect(db.run).toHaveBeenCalledTimes(2);
  });

  it('takes the stock out when the order ships', async () => {
    const db = fakeDb();
    await handleMessage(db, { type: 'OrderShipped', order: shippedOrder });
    expect(db.run).toHaveBeenCalledTimes(2);
  });
});
TS

cat > src/orders/migrations/0042_order_totals.sql <<'SQL'
-- Totals are stored in cents and every order records its currency.
ALTER TABLE orders RENAME COLUMN total TO total_cents;
ALTER TABLE orders ALTER COLUMN total_cents TYPE bigint USING (total_cents * 100);
ALTER TABLE orders ADD COLUMN currency text NOT NULL;
SQL
