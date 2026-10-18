---
name: "enterprise-patterns-inheritance-mapping"
description: "Use when a class hierarchy has to be persisted: choosing between one table for the hierarchy, a table per class, or a table per concrete class, or when domain code branches on a discriminator column. Not for associations or values; see relational-mapping-structure."
license: "MIT"
metadata:
  plugin: "enterprise-patterns"
  book: "Patterns of Enterprise Application Architecture"
  invocation: "auto"
---

# Inheritance mapping

Chooses how a class hierarchy is stored (Single Table, Class Table or Concrete Table Inheritance) and keeps that choice inside inheritance mappers so domain code never depends on it. Associations and values are `enterprise-patterns-relational-mapping-structure`.

## When to use

- A new hierarchy (for example payments, notifications, accounts) must be stored.
- A table has many nullable columns that belong to different subtypes, or a union of near-identical tables is used to report across types.
- Domain code checks a `type` column or a string discriminator.
- Someone proposes changing the strategy for an existing hierarchy.

## Rules

1. **Choose the inheritance mapping by what the hierarchy costs under each strategy**, not by habit or the ORM default. Each strategy trades nulls, joins and duplication differently, and the cost falls on different queries. Check: you can name the queries the application runs (across all types, within one type) and the number of subtype-specific fields.
2. **Use Single Table Inheritance when one table with nullable columns is simpler than multiple joins.** There is no join to maintain; nullable columns are the price. Check: few subtype-specific columns, frequent queries across the whole hierarchy, and no need for subtype columns to be non-null at the database level (or constraints that enforce them per kind).
3. **Use Class Table Inheritance when normalized subtype data is worth the join complexity.** Required columns stay required, at the cost of joins. Check: subtypes have many distinct fields, you want each column to be genuinely required, and you accept joins when loading.
4. **Use Concrete Table Inheritance when each concrete type can own its table without excessive duplication.** There are no nulls and no join to a parent table; shared columns are duplicated. Check: queries rarely span types, shared columns are few or stable, and reports across types are infrequent.
5. **Use Inheritance Mappers to isolate inheritance persistence decisions from domain logic.** If domain code knows the table layout, changing strategy becomes a domain change. Check: no domain class reads or writes a discriminator or knows how many tables its hierarchy uses.
6. **Make the strategy a recorded decision.** Added judgment: one line next to the mapper naming the strategy, the force that chose it and the sign that would reopen it (for example "more than a handful of subtype-only columns"). Strategies get outgrown, and a recorded reason shows when.
7. **Choose per hierarchy.** Added judgment: an application may use different strategies for different hierarchies; the source asks for fit, not uniformity. The best fit differs by hierarchy.
8. **Keep integrity in the schema where the strategy leaves gaps.** Added judgment: under Single Table add a check constraint that ties each kind to its required columns; under Concrete Table remember that a plain foreign key cannot point at "any concrete table". The schema should enforce what the strategy leaves implicit.
9. **Do not let the ORM's default strategy decide silently.** Added judgment: a default chosen by tooling is a choice nobody made. Check: the strategy in the configuration is the one named in the decision record.

## Procedure

1. List the subtypes, their distinct fields, and the queries (across types and within one type).
2. Score each strategy against rules 2 to 4 and pick the cheapest honest one.
3. Write the DDL, with constraints for the gaps from rule 8.
4. Implement the inheritance mapper: one place that chooses the subtype on load and writes the right columns on save.
5. Make the domain classes ignorant of the strategy, and test a round trip for each subtype plus one query across types.
6. If you are changing strategy, migrate behind the mapper first (dual-read or a one-off script), then switch.

## Example

```sql
-- Before: Concrete Table Inheritance; every total across payment kinds needs a union
create table card_payments          (id integer primary key, customer_id integer not null, amount_cents integer not null, card_last4 text not null);
create table bank_transfer_payments (id integer primary key, customer_id integer not null, amount_cents integer not null, iban text not null);
select customer_id, sum(amount_cents) from (
  select customer_id, amount_cents from card_payments
  union all
  select customer_id, amount_cents from bank_transfer_payments
) group by customer_id;

-- After: Single Table Inheritance; one subtype column each, kept honest by a check constraint
create table payments (
  id integer primary key,
  customer_id integer not null,
  amount_cents integer not null,
  kind text not null check (kind in ('card', 'bank_transfer')),
  card_last4 text,
  iban text,
  check ((kind = 'card' and card_last4 is not null and iban is null)
      or (kind = 'bank_transfer' and iban is not null and card_last4 is null))
);
select customer_id, sum(amount_cents) from payments group by customer_id;
```

```python
# The inheritance mapper is the only code that knows the discriminator
class PaymentMapper:
    # row comes from: select kind, id, customer_id, amount_cents, card_last4, iban from payments
    def to_domain(self, row):
        kind, id_, customer_id, cents, last4, iban = row
        if kind == "card":
            return CardPayment(id_, customer_id, cents, last4)
        if kind == "bank_transfer":
            return BankTransferPayment(id_, customer_id, cents, iban)
        raise ValueError(f"unknown payment kind: {kind}")
```

With two subtypes and one extra column each, the single table is the simpler honest choice. If bank transfers later gain a dozen fields of their own, that is the signal to reopen the decision and move to Class Table Inheritance behind the same mapper.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Discriminator in the domain | `if payment.kind == "card"` in model or service code | Polymorphism in the model; discriminator only in the mapper |
| Nullable sprawl | Single table with many columns null for most rows | Reopen: Class Table Inheritance |
| Union reporting | Every cross-type report repeats a union of tables | Reopen: Single Table or Class Table Inheritance |
| Join sprawl | Loading one object joins many tables with few fields each | Reopen: Single Table Inheritance |
| Unconstrained gaps | Nullable columns with no check tying them to a kind | Add the constraint |

## Trade-offs and exceptions

- No strategy is free: the source describes each as a trade between nullable columns, joins and duplication. Choosing one is correct; pretending it is free is not.
- The choice is reversible only if the mapper isolates it, which is why the source pairs the strategies with inheritance mappers.
- Composition instead of a hierarchy often removes the problem; whether to restructure the model is a design decision outside this skill (see `enterprise-patterns-business-logic-patterns`).

## Verification

- [ ] The strategy is named with the force that chose it.
- [ ] The inheritance mapper is the only code that reads or writes the discriminator.
- [ ] Schema constraints cover the gaps the strategy leaves.
- [ ] A round-trip test exists for every subtype.
- [ ] At least one query across types is tested.
- [ ] The ORM configuration matches the decision record.

## Related

`enterprise-patterns-relational-mapping-structure` for the rest of the mapping; `enterprise-patterns-data-mapper` for the mapper layer; `enterprise-patterns-query-and-metadata-mapping` for queries across types; `enterprise-patterns-mapping-reviewer` to review a diff.

## Source

- `Object-Relational Mapping Pattern Index`
