#!/usr/bin/env node
// Installs (or removes) the Guided Plugins pre-push hook in the git repository you run it from.
//   node /path/to/guidedplugins/scripts/install-git-hook.mjs            # ./.git/hooks/pre-push (honours core.hooksPath)
//   node /path/to/guidedplugins/scripts/install-git-hook.mjs --uninstall
// It refuses to overwrite a hook that is not its own unless --force. The hook calls guided-review-ci.mjs from THIS checkout.
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { ROOT } from './lib.mjs';

const args = process.argv.slice(2);
const git = (...a) => spawnSync('git', a, { encoding: 'utf8' });
const top = git('rev-parse', '--show-toplevel');
if (top.status !== 0) { console.error('run this inside the git repository you want the hook in'); process.exit(2); }
const hooksPath = git('rev-parse', '--git-path', 'hooks').stdout.trim();
const dir = path.resolve(process.cwd(), hooksPath); // git prints this path relative to where it ran, not to the top level (a subfolder would otherwise get the hook in its parent)
const target = path.join(dir, 'pre-push');
const MARK = '# guided-plugins-hook';
if (args.includes('--uninstall')) {
  if (fs.existsSync(target) && fs.readFileSync(target, 'utf8').includes(MARK)) { fs.rmSync(target); console.log(`removed ${target}`); } else console.log('no Guided Plugins hook to remove');
  process.exit(0);
}
if (fs.existsSync(target) && !fs.readFileSync(target, 'utf8').includes(MARK) && !args.includes('--force')) { console.error(`${target} exists and is not a Guided Plugins hook; use --force to replace it`); process.exit(2); }
const script = path.join(ROOT, 'scripts', 'guided-review-ci.mjs');
const hook = fs.readFileSync(path.join(ROOT, 'scripts', 'git-hooks', 'pre-push'), 'utf8').replace('__SCRIPT__', script.replace(/(["\\$`])/g, '\\$1'));
fs.mkdirSync(dir, { recursive: true });
fs.writeFileSync(target, hook, { mode: 0o755 });
console.log(`installed ${target}\nIt reviews the commits you push and blocks on a blocker. GUIDED_SKIP=1 git push skips it once; remove it with --uninstall.`);
