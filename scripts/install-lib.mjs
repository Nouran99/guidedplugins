// Small helpers shared by the installer scripts.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { ROOT, REGISTRY, listDir } from './lib.mjs';

export const DIST = path.join(ROOT, 'dist');
export const SLUGS = REGISTRY.books.map((b) => b.slug);

export function parseArgs(argv, valueFlags = []) {
  const flags = {}; const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const k = a.slice(2);
      if (valueFlags.includes(k) && argv[i + 1] && !argv[i + 1].startsWith('--')) flags[k] = argv[++i]; else flags[k] = true;
    } else positional.push(a);
  }
  return { flags, positional };
}

export function pickPlugins(positional) {
  const want = positional.includes('all') ? SLUGS : positional;
  const unknown = want.filter((s) => !SLUGS.includes(s));
  if (!want.length || unknown.length) {
    console.error(unknown.length ? `unknown plugin(s): ${unknown.join(', ')}` : 'name at least one plugin (or "all")');
    console.error(`plugins: ${SLUGS.join(', ')}`);
    process.exit(2);
  }
  return want;
}

export const home = () => os.homedir();

// The Codex roles (dist/codex/agents/*.toml) of one plugin. Ownership is read from the generated header of each file, never guessed from
// the file name: "ddd" is a prefix of "ddd-distilled" and "ddd-implementing", and "refactoring" of "refactoring-guru".
export function codexRolesOf(slug) {
  const dir = path.join(DIST, 'codex', 'agents');
  return listDir(dir).filter((e) => e.isFile() && e.name.endsWith('.toml')).filter((e) => {
    const first = fs.readFileSync(path.join(dir, e.name), 'utf8').split('\n', 1)[0];
    return first.match(/ from plugins\/([a-z0-9-]+)\/agents\//)?.[1] === slug;
  }).map((e) => e.name);
}
export function copyTree(src, dst, { link = false } = {}) {
  fs.rmSync(dst, { recursive: true, force: true });
  fs.mkdirSync(path.dirname(dst), { recursive: true });
  if (link) fs.symlinkSync(src, dst, 'dir'); else fs.cpSync(src, dst, { recursive: true });
}
export { fs, path, listDir };
