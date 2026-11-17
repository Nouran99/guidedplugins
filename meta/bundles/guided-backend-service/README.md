# Backend service (Guided Plugins preset)

Services and APIs that must survive production: structure, data and failure. This bundle contains no skills of its own. Installing it installs the plugins below as dependencies:

| Role | Plugin | Book |
| --- | --- | --- |
| Primary | `clean-architecture` | Clean Architecture |
| Secondary | `release-it` | Release It! |
| Secondary | `data-intensive-apps` | Designing Data-Intensive Applications |
| Companion | `guided` | start, which-book, config, review (across books), conflicts, ci-setup |

**Why these.** Clean Architecture keeps the dependency direction; Release It! covers timeouts, retries and overload; Designing Data-Intensive Applications covers consistency and data flow. Every pair is rated Complementary in the compatibility guide, so the books can run side by side; the primary book decides if they ever disagree.

## Use it

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install guided-backend-service@guided-plugins
/guided:config backend-service            # writes .guided-plugins.json with this primary and secondary
/clean-architecture:review                 # a review of your current diff
/guided:review                       # one review across all 3 books
```

Uninstalling the bundle leaves the plugins installed; remove them one by one with `/plugin uninstall`. More: [the repository](https://github.com/Nouran99/guidedplugins).

MIT licensed, unofficial, not endorsed by the authors or publishers of the books. See the repository NOTICE.
