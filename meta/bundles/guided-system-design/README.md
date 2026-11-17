# System design (Guided Plugins preset)

Designing modules, APIs and boundaries before or while building them. This bundle contains no skills of its own. Installing it installs the plugins below as dependencies:

| Role | Plugin | Book |
| --- | --- | --- |
| Primary | `philosophy-of-design` | A Philosophy of Software Design |
| Secondary | `clean-architecture` | Clean Architecture |
| Secondary | `code-complete` | Code Complete |
| Companion | `guided` | start, which-book, config, review (across books), conflicts, ci-setup |

**Why these.** A Philosophy of Software Design judges module depth and interfaces; Clean Architecture sets boundaries; Code Complete covers construction detail. Every pair is rated Complementary in the compatibility guide, so the books can run side by side; the primary book decides if they ever disagree.

## Use it

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install guided-system-design@guided-plugins
/guided:config system-design            # writes .guided-plugins.json with this primary and secondary
/philosophy-of-design:review                 # a review of your current diff
/guided:review                       # one review across all 3 books
```

Uninstalling the bundle leaves the plugins installed; remove them one by one with `/plugin uninstall`. More: [the repository](https://github.com/Nouran99/guidedplugins).

MIT licensed, unofficial, not endorsed by the authors or publishers of the books. See the repository NOTICE.
