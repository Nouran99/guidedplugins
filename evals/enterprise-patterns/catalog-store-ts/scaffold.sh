#!/usr/bin/env bash
set -e
mkdir -p src/catalog

cat > src/catalog/db.ts <<'TS'
export interface Db {
  query<T = any>(sql: string, params?: unknown[]): Promise<T[]>;
}
TS

cat > src/catalog/repositories.ts <<'TS'
import type { Db } from "./db";

export interface ProductRow {
  id?: number;
  name: string;
  kind: string;
  price_cents: number;
  weight_grams: number;
  category_id: number;
  tags: string;
}

export interface CategoryRow {
  id?: number;
  name: string;
  parent_id: number | null;
}

export interface PromotionRow {
  id?: number;
  category_id: number;
  percent: number;
  starts_on: string;
  ends_on: string;
}

export class BaseRepository<T extends { id?: number }> {
  constructor(
    protected readonly db: Db,
    private readonly table: string,
  ) {}

  findAll(): Promise<T[]> {
    return this.db.query<T>(`select * from ${this.table}`);
  }

  findBy(criteria: Record<string, unknown>): Promise<T[]> {
    const columns = Object.keys(criteria);
    const where = columns.map((column, i) => `${column} = $${i + 1}`).join(" and ");
    return this.db.query<T>(`select * from ${this.table} where ${where}`, Object.values(criteria));
  }

  query(sql: string, params: unknown[] = []): Promise<T[]> {
    return this.db.query<T>(sql, params);
  }

  async save(entity: T): Promise<void> {
    const columns = Object.keys(entity).filter((column) => column !== "id");
    const values = columns.map((column) => (entity as Record<string, unknown>)[column]);
    if (entity.id === undefined) {
      const marks = columns.map((_, i) => `$${i + 1}`).join(", ");
      await this.db.query(`insert into ${this.table} (${columns.join(", ")}) values (${marks})`, values);
    } else {
      const sets = columns.map((column, i) => `${column} = $${i + 1}`).join(", ");
      await this.db.query(`update ${this.table} set ${sets} where id = $${columns.length + 1}`, [
        ...values,
        entity.id,
      ]);
    }
  }

  async remove(id: number): Promise<void> {
    await this.db.query(`delete from ${this.table} where id = $1`, [id]);
  }
}

export class ProductRepository extends BaseRepository<ProductRow> {
  constructor(db: Db) {
    super(db, "products");
  }
}

export class CategoryRepository extends BaseRepository<CategoryRow> {
  constructor(db: Db) {
    super(db, "categories");
  }
}

export class PromotionRepository extends BaseRepository<PromotionRow> {
  constructor(db: Db) {
    super(db, "promotions");
  }
}
TS

cat > src/catalog/product.ts <<'TS'
import type { Db } from "./db";

const FLAT_SHIPPING_CENTS = 400;
const SHIPPING_CENTS_PER_500_GRAMS = 150;

export class Product {
  constructor(
    public id: number | undefined,
    public name: string,
    public kind: "physical" | "digital" | "subscription",
    public priceCents: number,
    public weightGrams: number,
    public categoryId: number,
    public tags: string,
  ) {}

  static async load(db: Db, id: number): Promise<Product | undefined> {
    const [row] = await db.query(
      "select id, name, kind, price_cents, weight_grams, category_id, tags from products where id = $1",
      [id],
    );
    return (
      row &&
      new Product(row.id, row.name, row.kind, row.price_cents, row.weight_grams, row.category_id, row.tags)
    );
  }

  async save(db: Db): Promise<void> {
    const values = [this.name, this.kind, this.priceCents, this.weightGrams, this.categoryId, this.tags];
    if (this.id === undefined) {
      const [row] = await db.query<{ id: number }>(
        "insert into products (name, kind, price_cents, weight_grams, category_id, tags) " +
          "values ($1, $2, $3, $4, $5, $6) returning id",
        values,
      );
      this.id = row.id;
    } else {
      await db.query(
        "update products set name = $1, kind = $2, price_cents = $3, weight_grams = $4, " +
          "category_id = $5, tags = $6 where id = $7",
        [...values, this.id],
      );
    }
  }

  hasTag(tag: string): boolean {
    return this.tags.split(",").includes(tag);
  }

  shippingCents(): number {
    if (this.kind === "digital" || this.kind === "subscription") {
      return 0;
    }
    return FLAT_SHIPPING_CENTS + Math.ceil(this.weightGrams / 500) * SHIPPING_CENTS_PER_500_GRAMS;
  }

  async priceCentsOn(db: Db, day: string): Promise<number> {
    const promotions = await db.query<{ percent: number }>(
      "select percent from promotions where category_id = $1 and starts_on <= $2 and ends_on >= $2",
      [this.categoryId, day],
    );
    const best = Math.max(0, ...promotions.map((promotion) => promotion.percent));
    return Math.round((this.priceCents * (100 - best)) / 100);
  }
}
TS

cat > src/catalog/catalogService.ts <<'TS'
import type { Db } from "./db";
import { Product } from "./product";
import type { CategoryRepository, ProductRepository } from "./repositories";

export class CatalogService {
  constructor(
    private readonly db: Db,
    private readonly products: ProductRepository,
    private readonly categories: CategoryRepository,
  ) {}

  async listPage(page: number, pageSize = 20) {
    const rows = await this.products.query("select * from products order by id limit $1 offset $2", [
      pageSize,
      page * pageSize,
    ]);
    const items = [];
    for (const row of rows) {
      const [category] = await this.categories.findBy({ id: row.category_id });
      items.push({
        id: row.id,
        name: row.name,
        category: category.name,
        price: row.price_cents / 100,
        needsAddress: row.kind === "physical",
      });
    }
    return items;
  }

  async search(term: string, tag?: string, sortBy = "name") {
    let sql = "select id, name, price_cents from products where name ilike '%" + term + "%'";
    if (tag) {
      sql += " and tags like '%" + tag + "%'";
    }
    sql += " order by " + sortBy;
    return this.db.query(sql);
  }

  async quote(productId: number, day: string) {
    const product = await Product.load(this.db, productId);
    if (!product) {
      throw new Error(`unknown product ${productId}`);
    }
    return {
      productId,
      priceCents: await product.priceCentsOn(this.db, day),
      shippingCents: product.shippingCents(),
    };
  }
}
TS

cat > src/catalog/product.test.ts <<'TS'
import { describe, expect, it, vi } from "vitest";
import type { Db } from "./db";
import { Product } from "./product";

describe("Product.save", () => {
  it("inserts a new product", async () => {
    const db = { query: vi.fn().mockResolvedValue([{ id: 11 }]) };
    const product = new Product(undefined, "Mug", "physical", 1200, 300, 2, "kitchen,gift");

    await product.save(db as unknown as Db);

    expect(db.query).toHaveBeenCalledWith(
      expect.stringContaining("insert into products"),
      ["Mug", "physical", 1200, 300, 2, "kitchen,gift"],
    );
    expect(product.id).toBe(11);
  });

  it("updates an existing product", async () => {
    const db = { query: vi.fn().mockResolvedValue([]) };
    const product = new Product(7, "Mug", "physical", 1300, 300, 2, "kitchen");

    await product.save(db as unknown as Db);

    expect(db.query).toHaveBeenCalledWith(
      expect.stringContaining("update products set"),
      ["Mug", "physical", 1300, 300, 2, "kitchen", 7],
    );
  });
});

describe("Product.shippingCents", () => {
  it("is free for a digital product", () => {
    expect(new Product(1, "E-book", "digital", 900, 0, 3, "").shippingCents()).toBe(0);
  });

  it("charges a flat rate plus the weight bands for a physical product", () => {
    expect(new Product(2, "Mug", "physical", 1200, 600, 2, "").shippingCents()).toBe(700);
  });
});
TS
