#!/usr/bin/env bash
set -e
mkdir -p src/inventory

cat > src/inventory/outcomes.ts <<'TS'
// What an inventory lookup can come to, named by what a caller should do about it.

/** Connection failure or 5xx: the service could not answer, and one more attempt may work. */
export class InventoryUnavailable extends Error {}

/** No answer inside the attempt's time limit. Retried like any unavailability, but counted on its own. */
export class InventoryTimeout extends InventoryUnavailable {}

/** 429: the service is shedding load. Repeating at once would add to it, so the lookup degrades instead. */
export class InventoryThrottled extends Error {}

/** The service understood the request and refused it (4xx). Repeating it cannot help. */
export class InventoryRejected extends Error {}

/** The reply breaks the contract: an unexpected status or content type, invalid JSON or an unexpected shape. */
export class InventoryMalformedReply extends Error {}

/** The reply is well formed but is not a stock level the warehouse system could have reported. */
export class InventoryImplausibleReply extends Error {}

export type Availability =
  | { sku: string; available: number; degraded: false }
  | { sku: string; available: null; degraded: true; reason: "unavailable" | "breaker-open" };
TS

cat > src/inventory/breaker.ts <<'TS'
export type BreakerState = "closed" | "open" | "half-open";

/**
 * Opens after `maxFailures` consecutive failures of the dependency, stays open for `openMs`,
 * then lets a single probe through. The caller reports every outcome of an allowed call.
 */
export class CircuitBreaker {
  readonly #maxFailures: number;
  readonly #openMs: number;
  readonly #now: () => number;
  readonly #onChange: (from: BreakerState, to: BreakerState) => void;
  #failures = 0;
  #openedAt = 0;
  #probing = false;
  #announced: BreakerState = "closed";

  constructor(opts: {
    maxFailures: number;
    openMs: number;
    now?: () => number;
    onChange?: (from: BreakerState, to: BreakerState) => void;
  }) {
    this.#maxFailures = opts.maxFailures;
    this.#openMs = opts.openMs;
    this.#now = opts.now ?? Date.now;
    this.#onChange = opts.onChange ?? (() => {});
  }

  get state(): BreakerState {
    if (this.#failures < this.#maxFailures) return "closed";
    return this.#now() - this.#openedAt >= this.#openMs ? "half-open" : "open";
  }

  /** True when a call may go through. While half-open only one probe is allowed at a time. */
  tryAcquire(): boolean {
    this.#announce();
    const state = this.state;
    if (state === "closed") return true;
    if (state === "half-open" && !this.#probing) {
      this.#probing = true;
      return true;
    }
    return false;
  }

  recordSuccess(): void {
    this.#failures = 0;
    this.#probing = false;
    this.#announce();
  }

  recordFailure(): void {
    this.#failures += 1;
    this.#probing = false;
    if (this.#failures >= this.#maxFailures) this.#openedAt = this.#now();
    this.#announce();
  }

  /** Reports each change of state once, whether a call outcome or the hold time running out caused it. */
  #announce(): void {
    const state = this.state;
    if (state === this.#announced) return;
    const from = this.#announced;
    this.#announced = state;
    this.#onChange(from, state);
  }
}
TS

cat > src/inventory/reply.ts <<'TS'
import {
  InventoryImplausibleReply,
  InventoryMalformedReply,
  InventoryRejected,
  InventoryThrottled,
  InventoryTimeout,
  InventoryUnavailable,
} from "./outcomes.ts";

const MAX_PLAUSIBLE_STOCK = 1_000_000; // the largest stock level the warehouse system can report

/** A failure of the connection itself, with a timeout told apart so it is counted on its own. */
export function transportFailure(err: unknown, what: string): InventoryUnavailable {
  const name = (err as Error).name;
  const message = `${what}: ${name}`;
  return name === "TimeoutError" ? new InventoryTimeout(message, { cause: err }) : new InventoryUnavailable(message, { cause: err });
}

/** Checks status, content type, syntax, shape and plausibility, in that order, and returns the stock level. */
export async function readAvailability(res: Response): Promise<number> {
  if (res.status === 429) throw new InventoryThrottled("status 429");
  if (res.status >= 500) throw new InventoryUnavailable(`status ${res.status}`);
  if (res.status >= 400) throw new InventoryRejected(`status ${res.status}`);
  if (res.status !== 200) throw new InventoryMalformedReply(`unexpected status ${res.status}`);
  if (!res.headers.get("content-type")?.startsWith("application/json")) {
    throw new InventoryMalformedReply("content type is not JSON");
  }
  let body: unknown;
  try {
    body = await res.json();
  } catch (err) {
    if (err instanceof SyntaxError) throw new InventoryMalformedReply("body is not valid JSON");
    throw transportFailure(err, "reading the body failed");
  }
  const available = (body as { available?: unknown } | null)?.available;
  if (typeof available !== "number") throw new InventoryMalformedReply("available is missing or not a number");
  if (!Number.isInteger(available) || available < 0 || available > MAX_PLAUSIBLE_STOCK) {
    throw new InventoryImplausibleReply(`available ${available} is not a stock level`);
  }
  return available;
}
TS

cat > src/inventory/availability-client.ts <<'TS'
import { CircuitBreaker } from "./breaker.ts";
import { InventoryRejected, InventoryUnavailable, type Availability } from "./outcomes.ts";
import { readAvailability, transportFailure } from "./reply.ts";

// The product page gives this lookup 1.5 s in total and keeps 300 ms for rendering. The service's p99 is
// about 250 ms, so one attempt may take 400 ms and a single retry still fits inside the 1.2 s that remain.
export const ATTEMPT_TIMEOUT_MS = 400;
export const MAX_ATTEMPTS = 2;
const RETRY_BASE_MS = 100;
const TOTAL_BUDGET_MS = 1200;
const BREAKER_MAX_FAILURES = 5; // consecutive health failures before calls stop
const BREAKER_OPEN_MS = 10_000; // how long calls stay stopped before a single probe goes through

export interface Deps {
  fetch: typeof fetch;
  sleep(ms: number): Promise<void>;
  random(): number;
  now(): number;
  log: { warn(message: string, fields: Record<string, unknown>): void };
  metrics: {
    increment(name: string): void;
    gauge(name: string, value: number): void;
    observe(name: string, value: number, labels: Record<string, string>): void;
  };
}

export class InventoryClient {
  readonly #baseUrl: string;
  readonly #deps: Deps;
  readonly #breaker: CircuitBreaker;
  readonly #attemptTimeoutMs: number;

  constructor(
    baseUrl: string,
    deps: Deps,
    opts: { attemptTimeoutMs?: number; breaker?: { maxFailures: number; openMs: number } } = {},
  ) {
    this.#baseUrl = baseUrl;
    this.#deps = deps;
    this.#attemptTimeoutMs = opts.attemptTimeoutMs ?? ATTEMPT_TIMEOUT_MS;
    this.#breaker = new CircuitBreaker({
      maxFailures: opts.breaker?.maxFailures ?? BREAKER_MAX_FAILURES,
      openMs: opts.breaker?.openMs ?? BREAKER_OPEN_MS,
      now: deps.now,
      onChange: (from, to) => deps.log.warn("inventory breaker changed state", { dependency: "inventory", from, to }),
    });
  }

  /** Resolves with a degraded result when inventory is slow or down; rejects only when the service refuses the request. */
  async availability(sku: string, requestId: string): Promise<Availability> {
    if (!this.#breaker.tryAcquire()) {
      this.#deps.metrics.increment("inventory.short_circuited");
      return { sku, available: null, degraded: true, reason: "breaker-open" };
    }
    const started = this.#deps.now();
    const stats = { attempts: 0 };
    let outcome = "ok";
    try {
      const available = await this.#lookup(sku, requestId, stats);
      this.#breaker.recordSuccess();
      return { sku, available, degraded: false };
    } catch (err) {
      outcome = err instanceof Error ? err.constructor.name : "unknown";
      if (err instanceof InventoryRejected) {
        this.#breaker.recordSuccess(); // the service answered, so it is healthy; the request was the problem
        throw err;
      }
      this.#breaker.recordFailure();
      this.#deps.metrics.increment("inventory.degraded");
      this.#deps.log.warn("inventory lookup failed, serving a degraded result", {
        dependency: "inventory",
        operation: "availability",
        outcome,
        attempts: stats.attempts,
        elapsed_ms: this.#deps.now() - started,
        request_id: requestId,
        sku,
      });
      return { sku, available: null, degraded: true, reason: "unavailable" };
    } finally {
      this.#deps.metrics.observe("inventory.latency_ms", this.#deps.now() - started, { outcome });
      this.#deps.metrics.gauge("inventory.breaker_open", this.#breaker.state === "closed" ? 0 : 1);
    }
  }

  // Reading a stock level changes nothing, so a repeat is safe. This is the only retry on this path:
  // the page calls availability() once and fetch does not retry on its own.
  async #lookup(sku: string, requestId: string, stats: { attempts: number }): Promise<number> {
    const started = this.#deps.now();
    let lastError: unknown;
    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
      stats.attempts = attempt;
      try {
        return await this.#attempt(sku, requestId);
      } catch (err) {
        lastError = err;
        if (!(err instanceof InventoryUnavailable)) break; // a refusal or an unusable reply fails the same way again, and a throttled service is left alone
        const delay = Math.floor(this.#deps.random() * RETRY_BASE_MS * 2 ** (attempt - 1)); // full jitter
        const spent = this.#deps.now() - started;
        if (attempt === MAX_ATTEMPTS || spent + delay + this.#attemptTimeoutMs > TOTAL_BUDGET_MS) break;
        this.#deps.metrics.increment("inventory.retries");
        await this.#deps.sleep(delay);
      }
    }
    throw lastError;
  }

  async #attempt(sku: string, requestId: string): Promise<number> {
    let res: Response;
    try {
      // The signal also covers reading the body, so the limit bounds the whole attempt.
      res = await this.#deps.fetch(`${this.#baseUrl}/v1/availability/${encodeURIComponent(sku)}`, {
        headers: { "x-request-id": requestId },
        signal: AbortSignal.timeout(this.#attemptTimeoutMs),
      });
    } catch (err) {
      throw transportFailure(err, "request failed");
    }
    try {
      return await readAvailability(res);
    } finally {
      if (!res.bodyUsed) await res.body?.cancel(); // hand the connection back when the body was not read
    }
  }
}
TS

cat > src/inventory/test-support.ts <<'TS'
import type { Deps } from "./availability-client.ts";

export const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

// Fake clock, seeded randomness and recording sinks, so no test waits for real time or depends on chance.
export function makeDeps(fetchImpl: typeof fetch) {
  let clock = 0;
  const counters = new Map<string, number>();
  const logs: Record<string, unknown>[] = [];
  const sleeps: number[] = [];
  const latencies: Record<string, string>[] = [];
  const deps: Deps = {
    fetch: fetchImpl,
    sleep: async (ms) => {
      sleeps.push(ms);
      clock += ms;
    },
    random: () => 0.5,
    now: () => clock,
    log: { warn: (_message, fields) => void logs.push(fields) },
    metrics: {
      increment: (name) => void counters.set(name, (counters.get(name) ?? 0) + 1),
      gauge: (name, value) => void counters.set(name, value),
      observe: (_name, _value, labels) => void latencies.push(labels),
    },
  };
  return { deps, counters, logs, sleeps, latencies, advance: (ms: number) => void (clock += ms) };
}
TS

cat > src/inventory/availability-client.test.ts <<'TS'
import assert from "node:assert/strict";
import { createServer } from "node:http";
import type { Socket } from "node:net";
import { test } from "node:test";
import { InventoryClient } from "./availability-client.ts";
import { InventoryRejected } from "./outcomes.ts";
import { json, makeDeps } from "./test-support.ts";

test("a peer that accepts the connection and never answers costs a bounded time and degrades", async () => {
  const sockets = new Set<Socket>();
  const server = createServer(() => {}); // reads the request and never replies
  server.on("connection", (socket) => sockets.add(socket));
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address() as { port: number };
  const { deps, counters, latencies } = makeDeps(fetch);
  const client = new InventoryClient(`http://127.0.0.1:${port}`, deps, { attemptTimeoutMs: 50 });

  const started = performance.now();
  const result = await client.availability("sku-1", "req-1");
  const elapsed = performance.now() - started;
  sockets.forEach((socket) => socket.destroy());
  server.close();

  assert.deepEqual(result, { sku: "sku-1", available: null, degraded: true, reason: "unavailable" });
  assert.ok(elapsed < 1000, `took ${elapsed} ms`);
  assert.equal(counters.get("inventory.degraded"), 1);
  assert.equal(latencies[0]?.outcome, "InventoryTimeout");
});

test("a refused request is surfaced after one attempt", async () => {
  let calls = 0;
  const { deps } = makeDeps(async () => {
    calls += 1;
    return json(404, {});
  });
  const client = new InventoryClient("http://inventory.test", deps);

  await assert.rejects(client.availability("unknown", "req-2"), InventoryRejected);
  assert.equal(calls, 1);
});

test("a throttled answer is not repeated and degrades", async () => {
  let calls = 0;
  const { deps, sleeps } = makeDeps(async () => {
    calls += 1;
    return json(429, {});
  });
  const client = new InventoryClient("http://inventory.test", deps);

  const result = await client.availability("sku-6", "req-6");

  assert.equal(result.degraded, true);
  assert.equal(calls, 1);
  assert.deepEqual(sleeps, []);
});

test("a transient 503 is retried once after a jittered delay, with the request id on both attempts", async () => {
  const replies = [json(503, {}), json(200, { available: 7 })];
  const ids: (string | null)[] = [];
  const { deps, sleeps, counters } = makeDeps(async (_url, init) => {
    ids.push(new Headers(init?.headers).get("x-request-id"));
    return replies.shift()!;
  });
  const client = new InventoryClient("http://inventory.test", deps);

  const result = await client.availability("sku-3", "req-3");

  assert.deepEqual(result, { sku: "sku-3", available: 7, degraded: false });
  assert.deepEqual(sleeps, [50]); // random() is 0.5 of a 100 ms base
  assert.deepEqual(ids, ["req-3", "req-3"]);
  assert.equal(counters.get("inventory.retries"), 1);
});

test("a retry that could not finish inside the total budget is not started", async () => {
  let calls = 0;
  let advance = (_ms: number) => {};
  const harness = makeDeps(async () => {
    calls += 1;
    advance(900); // a slow failure that leaves too little of the budget for a second attempt
    return json(503, {});
  });
  advance = harness.advance;
  const client = new InventoryClient("http://inventory.test", harness.deps);

  const result = await client.availability("sku-7", "req-7");

  assert.equal(result.degraded, true);
  assert.equal(calls, 1);
});

test("a malformed reply and an implausible one are told apart, and neither is retried", async () => {
  const replies = [
    new Response("<html></html>", { status: 200, headers: { "content-type": "text/html" } }),
    json(200, { available: -4 }),
  ];
  let calls = 0;
  const { deps, logs } = makeDeps(async () => {
    calls += 1;
    return replies.shift()!;
  });
  const client = new InventoryClient("http://inventory.test", deps);

  const first = await client.availability("sku-4", "req-4");
  const second = await client.availability("sku-4", "req-5");

  assert.ok(first.degraded && second.degraded);
  assert.equal(calls, 2);
  assert.deepEqual(logs.map((entry) => entry.outcome), ["InventoryMalformedReply", "InventoryImplausibleReply"]);
  assert.equal(logs[1]?.request_id, "req-5");
});
TS

cat > src/inventory/availability-breaker.test.ts <<'TS'
import assert from "node:assert/strict";
import { test } from "node:test";
import { InventoryClient, MAX_ATTEMPTS } from "./availability-client.ts";
import { json, makeDeps } from "./test-support.ts";

test("repeated failures open the breaker, and a single probe after the hold time closes it", async () => {
  let healthy = false;
  let calls = 0;
  const { deps, counters, logs, advance } = makeDeps(async () => {
    calls += 1;
    return healthy ? json(200, { available: 3 }) : json(503, {});
  });
  const client = new InventoryClient("http://inventory.test", deps, { breaker: { maxFailures: 2, openMs: 5_000 } });

  await client.availability("sku-5", "req-5");
  await client.availability("sku-5", "req-6");
  assert.equal(calls, 2 * MAX_ATTEMPTS);
  assert.equal(counters.get("inventory.breaker_open"), 1);

  const shortCircuited = await client.availability("sku-5", "req-7");
  assert.equal(shortCircuited.degraded && shortCircuited.reason, "breaker-open");
  assert.equal(calls, 2 * MAX_ATTEMPTS); // nothing reached the dependency while the breaker was open

  healthy = true;
  advance(5_000);
  const [probe, alongside] = await Promise.all([
    client.availability("sku-5", "req-8"),
    client.availability("sku-5", "req-9"),
  ]);
  assert.equal(probe.degraded, false);
  assert.equal(alongside.degraded && alongside.reason, "breaker-open"); // one probe at a time
  assert.equal(calls, 2 * MAX_ATTEMPTS + 1);
  assert.equal(counters.get("inventory.breaker_open"), 0);
  const transitions = logs.filter((entry) => entry.to).map((entry) => `${entry.from} > ${entry.to}`);
  assert.deepEqual(transitions, ["closed > open", "open > half-open", "half-open > closed"]);
});
TS
