# Domain model (Guided Plugins preset)

Business-rule-heavy code where the model of the domain is the hard part. This bundle contains no skills of its own. Installing it installs the plugins below as dependencies:

| Role | Plugin | Book |
| --- | --- | --- |
| Primary | `ddd-distilled` | Domain-Driven Design Distilled |
| Secondary | `clean-architecture` | Clean Architecture |
| Secondary | `refactoring` | Refactoring |
| Companion | `guided` | start, which-book, config, review (across books), conflicts, ci-setup |

**Why these.** DDD Distilled gives the pragmatic core of domain-driven design; Clean Architecture protects the model from frameworks; Refactoring evolves it safely. Every pair is rated Complementary in the compatibility guide, so the books can run side by side; the primary book decides if they ever disagree.

## Use it

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install guided-domain-model@guided-plugins
/guided:config domain-model            # writes .guided-plugins.json with this primary and secondary
/ddd-distilled:review                 # a review of your current diff
/guided:review                       # one review across all 3 books
```

Uninstalling the bundle leaves the plugins installed; remove them one by one with `/plugin uninstall`. More: [the repository](https://github.com/Nouran99/guidedplugins).

MIT licensed, unofficial, not endorsed by the authors or publishers of the books. See the repository NOTICE.
