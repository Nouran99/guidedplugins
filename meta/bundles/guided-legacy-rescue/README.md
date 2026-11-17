# Legacy rescue (Guided Plugins preset)

Changing code that has no tests, in a codebase you did not write. This bundle contains no skills of its own. Installing it installs the plugins below as dependencies:

| Role | Plugin | Book |
| --- | --- | --- |
| Primary | `legacy-code` | Working Effectively with Legacy Code |
| Secondary | `refactoring` | Refactoring |
| Secondary | `clean-code` | Clean Code |
| Companion | `guided` | start, which-book, config, review (across books), conflicts, ci-setup |

**Why these.** Working Effectively with Legacy Code gets the change under test first; Refactoring then restructures in small steps; Clean Code names what better looks like. Every pair is rated Complementary in the compatibility guide, so the books can run side by side; the primary book decides if they ever disagree.

## Use it

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install guided-legacy-rescue@guided-plugins
/guided:config legacy-rescue            # writes .guided-plugins.json with this primary and secondary
/legacy-code:review                 # a review of your current diff
/guided:review                       # one review across all 3 books
```

Uninstalling the bundle leaves the plugins installed; remove them one by one with `/plugin uninstall`. More: [the repository](https://github.com/Nouran99/guidedplugins).

MIT licensed, unofficial, not endorsed by the authors or publishers of the books. See the repository NOTICE.
