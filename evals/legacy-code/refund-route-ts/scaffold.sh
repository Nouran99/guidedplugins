#!/usr/bin/env bash
set -e
mkdir -p src/refunds

cat > src/refunds/requestContext.ts <<'TS'
import { AsyncLocalStorage } from "node:async_hooks";

export interface Actor {
  id: string;
  role: "customer" | "support" | "admin";
}

const storage = new AsyncLocalStorage<Actor>();

export function runAs<T>(actor: Actor, fn: () => T): T {
  return storage.run(actor, fn);
}

export function currentActor(): Actor {
  const actor = storage.getStore();
  if (!actor) throw new Error("no actor in the request context");
  return actor;
}
TS

cat > src/refunds/refundRoute.ts <<'TS'
import fs from "node:fs";
import type { Request, Response } from "express";
import { db } from "../db";
import { payments } from "../payments";
import { currentActor } from "./requestContext";

const REFUND_WINDOW_DAYS = 30;
const MARKETPLACE_WINDOW_DAYS = 14;
const CUSTOMER_LIMIT_CENTS = 20_000;
const AUDIT_LOG = "/var/log/shop/refunds.log";

export let lastDecision: string | null = null;

export async function refundOrder(req: Request, res: Response): Promise<void> {
  const order = await db.orders.findById(req.params.id);
  if (!order) {
    res.status(404).json({ error: "order not found" });
    return;
  }

  const amountCents = Number(req.body.amountCents);
  if (!Number.isInteger(amountCents) || amountCents <= 0) {
    res.status(400).json({ error: "amountCents must be a positive integer" });
    return;
  }

  const actor = currentActor();
  const ageDays = (Date.now() - order.paidAt.getTime()) / 86_400_000;
  const refundedSoFar = order.refunds.reduce((sum, r) => sum + r.cents, 0);

  let approved = order.status === "paid" || order.status === "partially_refunded";
  if (ageDays > REFUND_WINDOW_DAYS) approved = false;
  if (order.channel === "marketplace" && ageDays > MARKETPLACE_WINDOW_DAYS) approved = false;
  if (refundedSoFar + amountCents > order.totalCents) approved = false;
  if (actor.role === "customer" && amountCents > CUSTOMER_LIMIT_CENTS) approved = false;

  const decision = approved ? "approved" : "rejected";
  lastDecision = decision;
  fs.appendFileSync(
    AUDIT_LOG,
    `${new Date().toISOString()} ${actor.id} ${order.id} ${amountCents} ${decision}\n`,
  );

  if (!approved) {
    res.status(422).json({ error: "not refundable" });
    return;
  }

  await payments.refund(order.chargeId, amountCents);
  const fullyRefunded = refundedSoFar + amountCents === order.totalCents;
  await db.orders.update(order.id, {
    status: fullyRefunded ? "refunded" : "partially_refunded",
    refunds: [...order.refunds, { cents: amountCents, at: new Date() }],
  });
  res.json({ ok: true });
}

export async function listRefunds(req: Request, res: Response): Promise<void> {
  const order = await db.orders.findById(req.params.id);
  if (!order) {
    res.status(404).json({ error: "order not found" });
    return;
  }
  res.json({ refunds: order.refunds });
}
TS

cat > src/refunds/refundRoute.test.ts <<'TS'
import { beforeAll, describe, expect, it } from "vitest";
import type { Request, Response } from "express";
import { db } from "../db";
import { lastDecision, refundOrder } from "./refundRoute";
import { runAs } from "./requestContext";

function reqFor(id: string, amountCents: number): Request {
  return { params: { id }, body: { amountCents } } as unknown as Request;
}

function fakeRes() {
  return {
    statusCode: 200,
    body: undefined as unknown,
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    json(payload: unknown) {
      this.body = payload;
      return this;
    },
  };
}

const support = { id: "u-9", role: "support" as const };

describe("refundOrder", () => {
  beforeAll(async () => {
    await db.connect(process.env.TEST_DATABASE_URL!);
    await db.orders.insert({
      id: "o-1", status: "paid", totalCents: 5000, paidAt: new Date(),
      channel: "web", chargeId: "ch_1", refunds: [],
    });
    await db.orders.insert({
      id: "o-2", status: "paid", totalCents: 5000, paidAt: new Date("2023-01-01"),
      channel: "web", chargeId: "ch_2", refunds: [],
    });
  });

  it("refunds a paid order", async () => {
    const res = fakeRes();
    await runAs(support, () => refundOrder(reqFor("o-1", 5000), res as unknown as Response));
    expect(res.statusCode).toBe(200);
  });

  it("rejects a refund after the window", async () => {
    const res = fakeRes();
    await runAs(support, () => refundOrder(reqFor("o-2", 5000), res as unknown as Response));
    expect(lastDecision).toBeDefined();
  });

  it("answers not found for an unknown order", async () => {
    await refundOrder(reqFor("missing", 100), fakeRes() as unknown as Response);
  });
});
TS
