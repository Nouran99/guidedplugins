#!/usr/bin/env node
// Composes an AGENTS.md from the always-on rule files of one or more books.
//   node scripts/compose-rules.mjs clean-code refactoring --size nano --out AGENTS.md
// The first book is the primary; the others are marked as secondary so the agent knows which one decides a conflict.
// Warns above 32 KiB, the combined AGENTS.md cap in Codex.
import { DIST, fs, parseArgs, path, pickPlugins } from './install-lib.mjs';

const { flags, positional } = parseArgs(process.argv.slice(2), ['size', 'out']);
const slugs = pickPlugins(positional);
const size = flags.size ?? 'nano';
if (!['nano', 'mini'].includes(size)) { console.error('--size must be nano or mini'); process.exit(2); }
const parts = slugs.map((slug, i) => {
  const text = fs.readFileSync(path.join(DIST, 'rules', slug, `AGENTS.${size}.md`), 'utf8').trim();
  const role = i === 0 ? 'PRIMARY rule set: it decides when rule sets disagree.' : 'SECONDARY rule set: apply it for the decisions it covers; defer to the primary when they conflict.';
  return `<!-- ${role} -->\n${text}`;
});
const out = `${parts.join('\n\n---\n\n')}\n`;
if (Buffer.byteLength(out) > 32 * 1024) console.error(`warning: ${Buffer.byteLength(out)} bytes exceeds Codex's 32 KiB AGENTS.md cap; use --size nano or fewer books`);
if (flags.out) { fs.writeFileSync(flags.out, out); console.error(`wrote ${flags.out} (${Buffer.byteLength(out)} bytes, ${slugs.length} book(s), ${size})`); } else process.stdout.write(out);
