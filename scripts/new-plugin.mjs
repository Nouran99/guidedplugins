#!/usr/bin/env node
// Scaffolds the mechanical parts of a plugin so authors only write the intellectual content.
//   node scripts/new-plugin.mjs <slug> --upstream <path to a clone of ciembor/agent-rules-books> [--force]
// Creates: manifest, LICENSE, NOTICE.md, CHANGELOG.md, hook + script, vendored upstream rules
// (skills/principles/references/{full,mini,nano}.md), README stub with markers, docs/ dir.
// Does NOT create skills, agents or output styles.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { PLUGINS_DIR, REGISTRY } from './lib.mjs';
import { README_END, README_START } from './catalog-lib.mjs';

const args = process.argv.slice(2);
const slug = args.find((a) => !a.startsWith('--'));
const up = args.includes('--upstream') ? args[args.indexOf('--upstream') + 1] : null;
const force = args.includes('--force');
const mp = REGISTRY.marketplace;
const book = REGISTRY.books.find((b) => b.slug === slug);
if (!book || !up) { console.error('usage: new-plugin.mjs <slug> --upstream <dir> [--force]\nslugs: ' + REGISTRY.books.map((b) => b.slug).join(', ')); process.exit(2); }

const dir = path.join(PLUGINS_DIR, slug);
if (fs.existsSync(dir) && !force) { console.error(`${dir} already exists (use --force to re-scaffold)`); process.exit(1); }

const srcDir = path.join(path.resolve(up), book.upstream);
const srcFiles = { 'full.md': `${book.upstream}.md`, 'mini.md': `${book.upstream}.mini.md`, 'nano.md': `${book.upstream}.nano.md` };
for (const f of Object.values(srcFiles)) if (!fs.existsSync(path.join(srcDir, f))) { console.error(`missing upstream file ${path.join(srcDir, f)}`); process.exit(1); }
let sha = 'unknown';
try { sha = execFileSync('git', ['-C', path.resolve(up), 'rev-parse', 'HEAD'], { encoding: 'utf8' }).trim(); } catch { /* clone without git metadata */ }

// With --force on an existing plugin, never overwrite files an author has written by hand.
const existed = fs.existsSync(dir);
const KEEP = new Set(['.claude-plugin/plugin.json', 'README.md', 'CHANGELOG.md', 'NOTICE.md']);
const w = (rel, text, mode) => {
  const f = path.join(dir, rel);
  if (existed && KEEP.has(rel) && fs.existsSync(f)) { console.log(`kept existing ${rel}`); return; }
  fs.mkdirSync(path.dirname(f), { recursive: true });
  fs.writeFileSync(f, text.endsWith('\n') ? text : `${text}\n`, mode ? { mode } : undefined);
};

const repoUrl = `https://github.com/${mp.githubRepo}`;
const manifest = {
  name: slug,
  displayName: book.title,
  version: '1.0.0',
  description: `${book.title} by ${book.bookAuthor} as a Claude Code toolkit: skills, subagents and output styles built on its rule set. ${book.usefulWhen}`.slice(0, 300),
  author: { name: mp.owner },
  homepage: `${repoUrl}/tree/main/plugins/${slug}`,
  repository: repoUrl,
  license: 'MIT',
  keywords: book.keywords,
  userConfig: {
    inject_rules: {
      type: 'boolean',
      title: 'Inject the compact rules at session start',
      description: `Adds the short ${book.title} rule set to every session as always-on context. Leave off when you use several book plugins; the skills load the rules on demand.`,
      default: false,
    },
  },
};
w('.claude-plugin/plugin.json', JSON.stringify(manifest, null, 2));

w('LICENSE', `MIT License

Copyright (c) 2026 ${mp.owner}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
`);

w('NOTICE.md', `# Notice and attribution

## What this plugin is built on

The skills, subagents and output styles in this plugin are original work by ${mp.owner}. They are built on the
**${book.title}** rule sets published in [${mp.upstreamRepo.replace('https://github.com/', '')}](${mp.upstreamRepo}) by ${mp.upstreamAuthor}
(upstream commit \`${sha}\`).

The three files in \`skills/principles/references/\` are unmodified copies of the upstream \`${book.upstream}\` rule sets:

| File here | Upstream file |
| --- | --- |
| \`full.md\` | \`${book.upstream}/${srcFiles['full.md']}\` |
| \`mini.md\` | \`${book.upstream}/${srcFiles['mini.md']}\` |
| \`nano.md\` | \`${book.upstream}/${srcFiles['nano.md']}\` |

They are redistributed under the upstream MIT license, reproduced below as that license requires.

## Not an official product

*${book.title}* is by ${book.bookAuthor}. This plugin is **not** affiliated with, endorsed by, or approved by the book's
author(s), its publisher, or the upstream rule-set maintainer. The rule sets paraphrase the book as working rules; they do
not reproduce its text and are not a substitute for reading it. Book and site names are used only to identify the source.

## Upstream license (MIT)

MIT License

Copyright (c) 2026 ${mp.upstreamAuthor}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
`);

w('CHANGELOG.md', `# Changelog

All notable changes to this plugin are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org/).

## [1.0.0]

### Added
- Initial release of the ${book.title} plugin: skills, subagents and output styles built on the upstream rule set.
- Opt-in SessionStart hook that injects the compact rules (\`inject_rules\` option, off by default).
- Vendored upstream rule sets (full, mini, nano) with traceability from every component to the upstream sections.
`);

w('hooks/hooks.json', JSON.stringify({
  hooks: {
    SessionStart: [{
      matcher: 'startup|clear|compact',
      hooks: [{ type: 'command', command: '"${CLAUDE_PLUGIN_ROOT}/scripts/session-context.sh"' }],
    }],
  },
}, null, 2));

w('scripts/session-context.sh', `#!/usr/bin/env bash
# SessionStart hook. Prints the compact ${book.title} rules so Claude Code adds them to the session context.
# Disabled unless the plugin option "inject_rules" is true (Claude Code exports it as CLAUDE_PLUGIN_OPTION_INJECT_RULES).
set -eu

case "\${CLAUDE_PLUGIN_OPTION_INJECT_RULES:-false}" in
  true|TRUE|True|1|yes|on) ;;
  *) exit 0 ;;
esac

root="\${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
nano="$root/skills/principles/references/nano.md"
[ -r "$nano" ] || exit 0

printf '%s\\n\\n' "Always-on rules from the ${book.title} plugin (${slug}). Apply them to every code change in this session. The ${slug}:principles skill holds the longer rule set."
cat "$nano"
`, 0o755);

for (const [dst, src] of Object.entries(srcFiles)) {
  const f = path.join(dir, 'skills', 'principles', 'references', dst);
  fs.mkdirSync(path.dirname(f), { recursive: true });
  fs.copyFileSync(path.join(srcDir, src), f);
}

w('README.md', `# ${book.title}\n\n${README_START}\n\n${README_END}\n`);
fs.mkdirSync(path.join(dir, 'docs'), { recursive: true });

console.log(`scaffolded plugins/${slug} from upstream ${sha.slice(0, 8)}`);
console.log('next: write skills/, agents/, output-styles/, the README, then run');
console.log(`  node scripts/gen-catalog.mjs plugins/${slug} && node scripts/validate-plugin.mjs plugins/${slug}`);
