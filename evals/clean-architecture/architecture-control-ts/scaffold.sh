#!/usr/bin/env bash
set -e
mkdir -p src/permits/domain src/permits/application src/permits/adapters src/permits/infrastructure

cat > src/permits/domain/permit.ts <<'TS'
const MS_PER_DAY = 86_400_000;

/** The city lets a permit be extended by 14 days in total, however many times it is extended. */
export const MAX_EXTENSION_DAYS = 14;

export type PermitStatus = "active" | "revoked";

export class PermitRevoked extends Error {
  constructor(readonly permitId: string) {
    super(`permit ${permitId} is revoked`);
  }
}

export class InvalidExtensionDays extends Error {
  constructor(readonly days: number) {
    super(`an extension is a positive whole number of days, got ${days}`);
  }
}

export class ExtensionLimitExceeded extends Error {
  constructor(
    readonly permitId: string,
    readonly remainingDays: number,
  ) {
    super(`permit ${permitId} can be extended by ${remainingDays} more days at most`);
  }
}

export class Permit {
  private constructor(
    readonly id: string,
    private expiry: Date,
    private extended: number,
    private state: PermitStatus,
  ) {}

  static restore(id: string, expiresOn: Date, extendedDays: number, status: PermitStatus): Permit {
    if (!Number.isInteger(extendedDays) || extendedDays < 0 || extendedDays > MAX_EXTENSION_DAYS) {
      throw new RangeError(`extendedDays must be a whole number from 0 to ${MAX_EXTENSION_DAYS}`);
    }
    return new Permit(id, new Date(expiresOn), extendedDays, status);
  }

  get expiresOn(): Date {
    return new Date(this.expiry);
  }

  get extendedDays(): number {
    return this.extended;
  }

  get status(): PermitStatus {
    return this.state;
  }

  extend(days: number): void {
    if (!Number.isInteger(days) || days <= 0) {
      throw new InvalidExtensionDays(days);
    }
    if (this.state === "revoked") {
      throw new PermitRevoked(this.id);
    }
    const remaining = MAX_EXTENSION_DAYS - this.extended;
    if (days > remaining) {
      throw new ExtensionLimitExceeded(this.id, remaining);
    }
    this.expiry = new Date(this.expiry.getTime() + days * MS_PER_DAY);
    this.extended += days;
  }
}
TS

cat > src/permits/domain/permit.test.ts <<'TS'
import { describe, expect, it } from "vitest";
import {
  ExtensionLimitExceeded,
  InvalidExtensionDays,
  MAX_EXTENSION_DAYS,
  Permit,
  PermitRevoked,
} from "./permit";

const expiresOn = new Date("2026-06-01T00:00:00Z");

function activePermit(extendedDays = 0): Permit {
  return Permit.restore("p-1", expiresOn, extendedDays, "active");
}

describe("Permit.extend", () => {
  it("moves the expiry date by the requested days", () => {
    const permit = activePermit();
    permit.extend(5);
    expect(permit.expiresOn).toEqual(new Date("2026-06-06T00:00:00Z"));
    expect(permit.extendedDays).toBe(5);
  });

  it("allows several extensions up to the limit", () => {
    const permit = activePermit();
    permit.extend(10);
    permit.extend(4);
    expect(permit.extendedDays).toBe(MAX_EXTENSION_DAYS);
  });

  it("refuses an extension past the limit and leaves the permit unchanged", () => {
    const permit = activePermit(10);
    expect(() => permit.extend(5)).toThrow(ExtensionLimitExceeded);
    expect(permit.extendedDays).toBe(10);
    expect(permit.expiresOn).toEqual(expiresOn);
  });

  it("refuses to extend a revoked permit", () => {
    const permit = Permit.restore("p-1", expiresOn, 0, "revoked");
    expect(() => permit.extend(1)).toThrow(PermitRevoked);
  });

  it("refuses zero, negative and fractional days", () => {
    for (const days of [0, -3, 1.5]) {
      expect(() => activePermit().extend(days)).toThrow(InvalidExtensionDays);
    }
  });
});

describe("Permit.restore", () => {
  it("rejects stored data that is already past the limit", () => {
    expect(() => Permit.restore("p-1", expiresOn, MAX_EXTENSION_DAYS + 1, "active")).toThrow(RangeError);
  });
});
TS

cat > src/permits/application/extendPermit.ts <<'TS'
import {
  ExtensionLimitExceeded,
  InvalidExtensionDays,
  PermitRevoked,
  type Permit,
} from "../domain/permit";

export interface ExtendPermitRequest {
  permitId: string;
  days: number;
}

export type ExtendPermitResponse =
  | { outcome: "extended"; permitId: string; expiresOn: Date }
  | { outcome: "not-found" }
  | { outcome: "revoked" }
  | { outcome: "invalid-days" }
  | { outcome: "limit-exceeded"; remainingDays: number };

export interface PermitStore {
  findById(id: string): Promise<Permit | undefined>;
  save(permit: Permit): Promise<void>;
}

export class ExtendPermit {
  constructor(private readonly permits: PermitStore) {}

  async execute(request: ExtendPermitRequest): Promise<ExtendPermitResponse> {
    const permit = await this.permits.findById(request.permitId);
    if (!permit) {
      return { outcome: "not-found" };
    }

    try {
      permit.extend(request.days);
    } catch (error) {
      if (error instanceof PermitRevoked) {
        return { outcome: "revoked" };
      }
      if (error instanceof InvalidExtensionDays) {
        return { outcome: "invalid-days" };
      }
      if (error instanceof ExtensionLimitExceeded) {
        return { outcome: "limit-exceeded", remainingDays: error.remainingDays };
      }
      throw error;
    }

    await this.permits.save(permit);
    return { outcome: "extended", permitId: permit.id, expiresOn: permit.expiresOn };
  }
}
TS

cat > src/permits/application/extendPermit.test.ts <<'TS'
import { describe, expect, it } from "vitest";
import { Permit } from "../domain/permit";
import { ExtendPermit, type PermitStore } from "./extendPermit";

class InMemoryPermitStore implements PermitStore {
  saves = 0;
  private readonly permits = new Map<string, Permit>();

  constructor(...existing: Permit[]) {
    for (const permit of existing) {
      this.permits.set(permit.id, permit);
    }
  }

  async findById(id: string): Promise<Permit | undefined> {
    return this.permits.get(id);
  }

  async save(permit: Permit): Promise<void> {
    this.saves += 1;
    this.permits.set(permit.id, permit);
  }
}

const expiresOn = new Date("2026-06-01T00:00:00Z");

describe("ExtendPermit", () => {
  it("extends the permit and saves it", async () => {
    const store = new InMemoryPermitStore(Permit.restore("p-1", expiresOn, 0, "active"));

    const result = await new ExtendPermit(store).execute({ permitId: "p-1", days: 7 });

    expect(result).toEqual({
      outcome: "extended",
      permitId: "p-1",
      expiresOn: new Date("2026-06-08T00:00:00Z"),
    });
    expect(store.saves).toBe(1);
  });

  it("reports the days left when the limit would be exceeded, and saves nothing", async () => {
    const store = new InMemoryPermitStore(Permit.restore("p-1", expiresOn, 12, "active"));

    const result = await new ExtendPermit(store).execute({ permitId: "p-1", days: 5 });

    expect(result).toEqual({ outcome: "limit-exceeded", remainingDays: 2 });
    expect(store.saves).toBe(0);
  });

  it("reports days that are not a positive whole number, and saves nothing", async () => {
    const store = new InMemoryPermitStore(Permit.restore("p-1", expiresOn, 0, "active"));

    const result = await new ExtendPermit(store).execute({ permitId: "p-1", days: -2 });

    expect(result).toEqual({ outcome: "invalid-days" });
    expect(store.saves).toBe(0);
  });

  it("reports a revoked permit", async () => {
    const store = new InMemoryPermitStore(Permit.restore("p-1", expiresOn, 0, "revoked"));

    const result = await new ExtendPermit(store).execute({ permitId: "p-1", days: 1 });

    expect(result).toEqual({ outcome: "revoked" });
  });

  it("reports an unknown permit", async () => {
    const result = await new ExtendPermit(new InMemoryPermitStore()).execute({ permitId: "nope", days: 1 });

    expect(result).toEqual({ outcome: "not-found" });
  });
});
TS

cat > src/permits/adapters/extendPermitController.ts <<'TS'
import type { Request, RequestHandler, Response } from "express";
import type { ExtendPermit, ExtendPermitResponse } from "../application/extendPermit";

interface HttpResult {
  status: number;
  body: object;
}

// The one place that turns use case outcomes into HTTP results.
function toHttp(response: ExtendPermitResponse): HttpResult {
  switch (response.outcome) {
    case "extended":
      return {
        status: 200,
        body: { permitId: response.permitId, expiresOn: response.expiresOn.toISOString() },
      };
    case "not-found":
      return { status: 404, body: { error: "unknown permit" } };
    case "revoked":
      return { status: 409, body: { error: "permit is revoked" } };
    case "invalid-days":
      return { status: 400, body: { error: "days must be a positive whole number" } };
    case "limit-exceeded":
      return {
        status: 422,
        body: { error: "extension limit reached", remainingDays: response.remainingDays },
      };
  }
}

export function extendPermitController(extendPermit: Pick<ExtendPermit, "execute">): RequestHandler {
  return async (req: Request, res: Response): Promise<void> => {
    const days = req.body?.days;
    if (typeof days !== "number") {
      res.status(400).json({ error: "days must be a number" });
      return;
    }

    const result = toHttp(await extendPermit.execute({ permitId: req.params.id, days }));
    res.status(result.status).json(result.body);
  };
}
TS

cat > src/permits/adapters/extendPermitController.test.ts <<'TS'
import type { Request, Response } from "express";
import { describe, expect, it } from "vitest";
import type { ExtendPermitResponse } from "../application/extendPermit";
import { extendPermitController } from "./extendPermitController";

async function call(outcome: ExtendPermitResponse, body: unknown) {
  const sent: { status?: number; json?: unknown } = {};
  const res = {
    status(code: number) {
      sent.status = code;
      return this;
    },
    json(payload: unknown) {
      sent.json = payload;
      return this;
    },
  };
  const useCase = { execute: async () => outcome };

  await extendPermitController(useCase)(
    { params: { id: "p-1" }, body } as unknown as Request,
    res as unknown as Response,
    () => undefined,
  );
  return sent;
}

describe("extendPermitController", () => {
  it("answers 200 with the new expiry date", async () => {
    const sent = await call(
      { outcome: "extended", permitId: "p-1", expiresOn: new Date("2026-06-08T00:00:00Z") },
      { days: 7 },
    );
    expect(sent).toEqual({
      status: 200,
      json: { permitId: "p-1", expiresOn: "2026-06-08T00:00:00.000Z" },
    });
  });

  it("answers 404 for an unknown permit", async () => {
    expect((await call({ outcome: "not-found" }, { days: 7 })).status).toBe(404);
  });

  it("answers 409 for a revoked permit", async () => {
    expect((await call({ outcome: "revoked" }, { days: 7 })).status).toBe(409);
  });

  it("answers 400 when the use case refuses the days", async () => {
    expect((await call({ outcome: "invalid-days" }, { days: -1 })).status).toBe(400);
  });

  it("answers 422 with the days left when the limit is reached", async () => {
    const sent = await call({ outcome: "limit-exceeded", remainingDays: 2 }, { days: 7 });
    expect(sent.status).toBe(422);
    expect(sent.json).toEqual({ error: "extension limit reached", remainingDays: 2 });
  });

  it("answers 400 when the body has no numeric days", async () => {
    const sent = await call({ outcome: "not-found" }, { days: "soon" });
    expect(sent.status).toBe(400);
    expect(sent.json).toEqual({ error: "days must be a number" });
  });
});
TS

cat > src/permits/infrastructure/pgPermitStore.ts <<'TS'
import type { Pool } from "pg";
import type { PermitStore } from "../application/extendPermit";
import { Permit, type PermitStatus } from "../domain/permit";

interface PermitRow {
  id: string;
  expires_on: Date;
  extended_days: number;
  status: PermitStatus;
}

// The table also has a CHECK on extended_days as a backstop. The rule itself lives in Permit.extend().
export class PgPermitStore implements PermitStore {
  constructor(private readonly pool: Pool) {}

  async findById(id: string): Promise<Permit | undefined> {
    const { rows } = await this.pool.query<PermitRow>(
      "select id, expires_on, extended_days, status from permits where id = $1",
      [id],
    );
    const row = rows[0];
    return row && Permit.restore(row.id, row.expires_on, row.extended_days, row.status);
  }

  async save(permit: Permit): Promise<void> {
    await this.pool.query("update permits set expires_on = $2, extended_days = $3 where id = $1", [
      permit.id,
      permit.expiresOn,
      permit.extendedDays,
    ]);
  }
}
TS

cat > src/permits/infrastructure/pgPermitStore.test.ts <<'TS'
import type { Pool } from "pg";
import { describe, expect, it } from "vitest";
import { Permit } from "../domain/permit";
import { PgPermitStore } from "./pgPermitStore";

function poolReturning(rows: unknown[]) {
  const queries: { params: unknown[] }[] = [];
  const pool = {
    async query(_sql: string, params: unknown[]) {
      queries.push({ params });
      return { rows };
    },
  };
  return { pool: pool as unknown as Pool, queries };
}

describe("PgPermitStore", () => {
  it("maps a stored row to a permit", async () => {
    const { pool } = poolReturning([
      { id: "p-1", expires_on: new Date("2026-06-01T00:00:00Z"), extended_days: 3, status: "active" },
    ]);

    const permit = await new PgPermitStore(pool).findById("p-1");

    expect(permit?.id).toBe("p-1");
    expect(permit?.expiresOn).toEqual(new Date("2026-06-01T00:00:00Z"));
    expect(permit?.extendedDays).toBe(3);
    expect(permit?.status).toBe("active");
  });

  it("returns nothing when no row matches", async () => {
    const { pool } = poolReturning([]);

    expect(await new PgPermitStore(pool).findById("nope")).toBeUndefined();
  });

  it("writes the new expiry date and the extended days", async () => {
    const { pool, queries } = poolReturning([]);
    const permit = Permit.restore("p-1", new Date("2026-06-01T00:00:00Z"), 0, "active");
    permit.extend(7);

    await new PgPermitStore(pool).save(permit);

    expect(queries).toEqual([{ params: ["p-1", new Date("2026-06-08T00:00:00Z"), 7] }]);
  });
});
TS

cat > src/permits/main.ts <<'TS'
import express from "express";
import { Pool } from "pg";
import { extendPermitController } from "./adapters/extendPermitController";
import { ExtendPermit } from "./application/extendPermit";
import { PgPermitStore } from "./infrastructure/pgPermitStore";

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  throw new Error("DATABASE_URL is required");
}

const extendPermit = new ExtendPermit(new PgPermitStore(new Pool({ connectionString: databaseUrl })));

const app = express();
app.use(express.json());
app.post("/permits/:id/extend", extendPermitController(extendPermit));

app.listen(Number(process.env.PORT ?? 3000));
TS

cat > src/permits/architecture.test.ts <<'TS'
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";

const permitsDir = fileURLToPath(new URL(".", import.meta.url));
const outward = (layers: string[]) =>
  new RegExp(`from\\s+["'](?:\\.\\./)+(?:${layers.join("|")})/|from\\s+["'](?:express|pg)["']`);

const forbiddenImports: Record<string, RegExp> = {
  domain: outward(["application", "adapters", "infrastructure"]),
  application: outward(["adapters", "infrastructure"]),
};

function sourceFiles(dir: string): string[] {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) {
      return sourceFiles(path);
    }
    return entry.name.endsWith(".ts") && !entry.name.endsWith(".test.ts") ? [path] : [];
  });
}

describe("dependency rule", () => {
  it.each(Object.entries(forbiddenImports))("%s imports nothing from an outer layer, express or pg", (layer, pattern) => {
    const offenders = sourceFiles(join(permitsDir, layer)).filter((file) =>
      pattern.test(readFileSync(file, "utf8")),
    );
    expect(offenders).toEqual([]);
  });
});
TS
