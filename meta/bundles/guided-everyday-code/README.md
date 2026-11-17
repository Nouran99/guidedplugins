# Everyday code (Guided Plugins preset)

Teams writing and reviewing ordinary application code every day. This bundle contains no skills of its own. Installing it installs the plugins below as dependencies:

| Role | Plugin | Book |
| --- | --- | --- |
| Primary | `clean-code` | Clean Code |
| Secondary | `refactoring` | Refactoring |
| Companion | `guided` | start, which-book, config, review (across books), conflicts, ci-setup |

**Why these.** Clean Code decides readability questions; Refactoring adds the safe, small-step way to act on them. Every pair is rated Complementary in the compatibility guide, so the books can run side by side; the primary book decides if they ever disagree.

## Use it

```text
/plugin marketplace add Nouran99/guidedplugins
/plugin install guided-everyday-code@guided-plugins
/guided:config everyday-code            # writes .guided-plugins.json with this primary and secondary
/clean-code:review                 # a review of your current diff
/guided:review                       # one review across all 2 books
```

Uninstalling the bundle leaves the plugins installed; remove them one by one with `/plugin uninstall`. More: [the repository](https://github.com/Nouran99/guidedplugins).

MIT licensed, unofficial, not endorsed by the authors or publishers of the books. See the repository NOTICE.
