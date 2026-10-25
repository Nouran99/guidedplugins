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

// The Codex roles of one plugin ship inside the plugin, in the hidden skill install-roles. One folder per plugin, so "ddd" never picks up the
// roles of "ddd-distilled" or "ddd-implementing".
export const codexRolesDir = (slug) => path.join(DIST, 'codex', slug, 'skills', 'install-roles', 'roles');
export function codexRolesOf(slug) {
  return listDir(codexRolesDir(slug)).filter((e) => e.isFile() && e.name.endsWith('.toml')).map((e) => e.name);
}
export function copyTree(src, dst, { link = false } = {}) {
  fs.rmSync(dst, { recursive: true, force: true });
  fs.mkdirSync(path.dirname(dst), { recursive: true });
  if (link) fs.symlinkSync(src, dst, 'dir'); else fs.cpSync(src, dst, { recursive: true });
}
export { fs, path, listDir };
