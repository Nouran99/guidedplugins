---
name: "reversible-choices"
description: "Use when code hard-codes a vendor, database, platform, endpoint or policy that may change, or when choosing a serialization, config or file format. Covers reversibility, lock-in, plain text and versioned formats. A request that names a solution is `requirements`."
---

# Reversible choices

Keep decisions that may change cheap to change. This skill covers vendors, platforms, databases, deployment environments, policies and the formats data and configuration are stored in. Separating concerns inside the code is `$pragmatic-programmer:orthogonality`; deciding what a request actually needs is `$pragmatic-programmer:requirements`.

## When to use

- A vendor name, endpoint, region, limit or feature policy is written into code in many places.
- You are choosing a database, queue, cloud service, framework or file format for something that will live a long time.
- Data is written in a binary or framework-specific format with no version marker.
- A script or config is hard to read, diff or recreate.
- A commitment is being made before evidence exists that it is the right one.

## Rules

1. **Preserve reversibility when requirements, vendors, platforms, databases or deployment environments may change.** [MUST] Check: for each such choice, you can state what it would cost to change.
2. **Avoid irreversible commitments until evidence makes them worth the cost.** [MUST NOT] Check: a decision note or comment names the evidence for each commitment you do make.
3. **Prefer flexible boundaries over brittle cleverness.** [SHOULD] Check: a plain, replaceable boundary was chosen over a trick that only works while nothing changes.
4. **Build systems that are easy to observe, test and change.** [MUST] Check: you can run the piece you changed on its own and see what it did.
5. **Avoid premature commitment when requirements are still moving.** [MUST NOT] Check: decisions that depend on unsettled requirements are marked provisional.
6. **Keep volatile details in validated, controlled, versioned configuration, metadata or an explicit abstraction instead of hard-coding them.** [Compact checklist] Check: a search for the vendor's name, endpoint or limit finds it in one place.
7. **Put the seam where the volatility is.** [Added judgment] Wrap what you can name as likely to change, behind a narrow interface owned by one module; do not abstract everything "just in case". Check: the abstraction has a stated reason to exist.
8. **Favor plain text and open formats for long-lived automation and integration where practical.** [SHOULD] Check: the file can be opened, read and diffed with ordinary tools.
9. **Make scripts and configs inspectable and diffable.** [MUST] Check: a change to configuration shows up as a readable diff in version control.
10. **Keep serialization and configuration formats explicit and version-aware.** [MUST] Check: stored data carries a version, and there is a stated way to read older versions.
11. **Avoid opaque binary or framework-specific lock-in unless justified.** [MUST NOT] Check: where such a format is used, the justification (speed, size, an ecosystem requirement) is written next to it.
12. **When you must commit, say so and state the exit cost.** [Added judgment] Check: the report names the commitment and what leaving it would take.

## Procedure

1. List the decisions the change makes or depends on: vendors, storage, formats, platforms, policies, limits.
2. For each, ask whether it may change and how likely, and what changing it would cost today.
3. Move volatile details into one module and validated configuration.
4. For stored data, add or confirm a version marker and a reader for older versions.
5. Replace opaque formats with text where the data is long-lived, or write down why not.
6. Record each commitment you keep with its evidence and exit cost.

## Example

```python
# Before: the carrier's details are spread through the code, and snapshots are an opaque pickle
def create_label(order):
    resp = requests.post("https://api.shipfast.example/v2/labels",
                         json={"svc": "EXP", "weight_g": order.weight_g})
    return resp.json()["label_url"]

def save_snapshot(orders, path):
    with open(path, "wb") as f:
        pickle.dump(orders, f)          # tied to Python and to these class definitions; no version
```

```python
# After: one module knows the carrier; configuration is validated; snapshots are text with a version
@dataclass(frozen=True)
class CarrierConfig:
    base_url: str
    service_code: str

def load_carrier_config(raw: dict) -> CarrierConfig:
    missing = [k for k in ("base_url", "service_code") if not raw.get(k)]
    if missing:
        raise ConfigError(f"carrier config missing: {', '.join(missing)}")
    return CarrierConfig(raw["base_url"].rstrip("/"), raw["service_code"])

def create_label(order, cfg: CarrierConfig) -> str:           # shipping.py: the only module that names the carrier
    resp = requests.post(f"{cfg.base_url}/labels",
                         json={"svc": cfg.service_code, "weight_g": order.weight_g})
    return resp.json()["label_url"]

def save_snapshot(orders, path):
    with open(path, "w", encoding="utf-8") as f:
        json.dump({"schema_version": 2, "orders": [o.to_dict() for o in orders]}, f, indent=2, sort_keys=True)

def load_snapshot(path):
    with open(path, encoding="utf-8") as f:
        doc = json.load(f)
    if doc.get("schema_version") == 2:
        return [Order.from_dict(d) for d in doc["orders"]]
    raise ValueError(f"unsupported snapshot version: {doc.get('schema_version')!r}")
```

Switching carriers now touches `shipping.py` and a configuration file. The snapshot can be read in a diff, and the next format change adds a version branch instead of breaking old files.

## Anti-patterns

| Smell | Detect | Treat |
| --- | --- | --- |
| Vendor everywhere | The vendor's name, endpoint or types in many modules | One module, validated config |
| Unversioned format | Stored data with no version field | Add a version and a reader per supported version |
| Opaque snapshot | Pickle, native serialization or a framework dump as long-lived storage | A text format with an explicit schema, or a recorded justification |
| Hand-built environment | Setup that exists only in someone's shell history | A script or config in version control |
| Abstraction insurance | An interface with one implementation and no volatility in sight | Remove it, or record the expected change |
| Silent commitment | A hard-to-reverse choice with no evidence or note | Write the evidence and the exit cost |

## Trade-offs and exceptions

- The source qualifies its rules: "where practical" for plain text, "unless justified" for lock-in. A binary format that earns its keep (size, speed, a required ecosystem) is allowed when the reason is recorded.
- Reversibility has a price in indirection. Added judgment: pay it where change is likely or costly, not everywhere.
- Some commitments are right: a database chosen on evidence is fine; the rule asks for evidence, not endless optionality.
- Consistency and schema evolution in distributed data systems go deeper than this skill; a data-systems plugin owns them.

## Verification

- [ ] Each volatile detail lives in one module or one configuration source.
- [ ] Configuration is validated at load with a message that names what is wrong.
- [ ] Stored data carries a version and can be read in a diff.
- [ ] Every commitment kept has evidence and an exit cost recorded.
- [ ] No abstraction was added without a named reason.

## Related

`pragmatic-programmer-reversibility-reviewer` to review a diff; `$pragmatic-programmer:requirements` when the commitment comes from a solution-shaped request; `$pragmatic-programmer:generators-and-dsls` for specs and rule files; `$pragmatic-programmer:orthogonality` for boundaries inside the code.

## Source

- `Reversibility, Domain Languages, and Requirements`: only the rules on preserving reversibility and avoiding irreversible commitments.
- `Favor Adaptability`
- `Text and Data Rules`
