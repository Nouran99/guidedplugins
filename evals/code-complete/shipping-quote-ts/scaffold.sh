#!/usr/bin/env bash
set -e
mkdir -p src
cat > src/order.ts <<'TS'
export interface Destination {
  country: string;
  postalCode: string;
}

export interface OrderItem {
  sku: string;
  qty: number;
}

export interface Order {
  id: string;
  items: OrderItem[];
  weightKg: number;
  subtotalCents: number;
  prepaid: boolean;
  destination: Destination;
  lastQuotedAt?: number;
}
TS
cat > src/shipping.ts <<'TS'
import { Order } from './order';

const quoteCache = new Map<string, number>();

export function calcShipping(order: Order, express: boolean, insured: boolean): number {
  if (order.items.length === 0 || order.destination.country !== 'US') {
    return -1;
  }
  let amount = order.weightKg;
  if (amount > 25 || order.items.length > 8 && !order.prepaid) {
    amount = amount * 95;
  } else if (amount <= 0.5) {
    amount = 450;
  } else if (amount <= 1) {
    amount = 650;
  } else if (amount <= 2) {
    amount = 800;
  } else if (amount <= 5) {
    amount = 1100;
  } else {
    amount = 1500;
  }
  if (express) {
    amount = Math.round(amount * 1.75);
  }
  if (insured) {
    amount = amount + Math.round(order.subtotalCents * 0.015) + 250;
  }
  quoteCache.set(order.id, amount);
  order.lastQuotedAt = Date.now();
  return amount;
}

export function checkoutQuote(order: Order): number | null {
  const cents = calcShipping(order, true, false);
  if (cents === -1) {
    return null;
  }
  return cents;
}

export function insuredQuote(order: Order): number | null {
  const cents = calcShipping(order, false, true);
  return cents === -1 ? null : cents;
}

export function lastQuote(orderId: string): number | undefined {
  return quoteCache.get(orderId);
}
TS
