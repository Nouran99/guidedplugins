#!/usr/bin/env bash
set -e
mkdir -p src
cat > src/order-manager.ts <<'TS'
import axios, { AxiosResponse } from 'axios';
import { sendMail } from './mailer';

export class OrderManager {
  // process an order
  async process(o: any, p: boolean, e: boolean): Promise<AxiosResponse | null> {
    // validate
    if (!o.items || o.items.length == 0) {
      return null;
    }
    let t = 0;
    for (let i = 0; i < o.items.length; i++) {
      t += o.items[i].price * o.items[i].qty; // add price
    }
    if (p) {
      t = t * 0.9;
    }
    if (t > 1000) {
      t = t - 50;
    }
    try {
      const r = await axios.post('https://pay.example.com/charge', {
        amount: t,
        cust: o.customer.account.id,
      });
      if (e) {
        await sendMail(o.customer.email, 'Your order', 'Thanks for ordering ' + o.items.length + ' items. Total ' + t);
      }
      return r;
    } catch (err) {
    }
    return null;
  }
}

// old version:
// export function processOrder(o) { return o.items.length }
TS
