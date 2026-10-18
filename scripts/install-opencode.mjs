#!/usr/bin/env node
// Installs the OpenCode skills and agents of one or more plugins. Run it from a clone of this repository (it copies from dist/opencode
// next to this script); it needs Node 20 or later.
//   node scripts/install-opencode.mjs clean-code refactoring            # into ./.opencode of the CURRENT directory
//   node scripts/install-opencode.mjs clean-code --project ~/work/app   # into ~/work/app/.opencode
//   node scripts/install-opencode.mjs clean-code --global               # into ~/.config/opencode
//   node scripts/install-opencode.mjs clean-code --link                 # symlink instead of copy (follows git pulls)
//   node scripts/install-opencode.mjs clean-code --uninstall
// Flags: --no-skills, --no-agents, --dry-run, --dest <dir>. Every skill and agent name starts with the plugin slug, so plugins never collide.
// Each plugin's LICENSE and NOTICE.md (the MIT notice for the vendored rule text and the book credits) are copied to <root>/guided-plugins/<plugin>/.
import { DIST, copyTree, fs, home, listDir, parseArgs, path, pickPlugins } from './install-lib.mjs';

const { flags, positional } = parseArgs(process.argv.slice(2), ['project', 'dest']);
const slugs = pickPlugins(positional);
const root = flags.dest ?? (flags.global
  ? path.join(process.env.XDG_CONFIG_HOME ?? path.join(home(), '.config'), 'opencode')
  : path.join(path.resolve(flags.project && flags.project !== true ? flags.project : '.'), '.opencode'));
const dry = !!flags['dry-run'];
const present = (p) => { try { fs.lstatSync(p); return true; } catch { return false; } };

let skills = 0; let agents = 0;
for (const slug of slugs) {
  const base = path.join(DIST, 'opencode', slug);
  const before = skills + agents;
  if (!flags['no-skills']) {
    for (const e of listDir(path.join(base, 'skills')).filter((x) => x.isDirectory())) {
      const target = path.join(root, 'skills', e.name);
      if (flags.uninstall) {
        if (!present(target)) continue; // count only what is really there
        if (!dry) fs.rmSync(target, { recursive: true, force: true });
      } else if (!dry) copyTree(path.join(base, 'skills', e.name), target, { link: !!flags.link });
      skills++;
    }
  }
  if (!flags['no-agents']) {
    for (const e of listDir(path.join(base, 'agents')).filter((x) => x.isFile())) {
      const target = path.join(root, 'agents', e.name);
      if (flags.uninstall) {
        if (!present(target)) continue;
        if (!dry) fs.rmSync(target, { force: true });
      } else if (!dry) {
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.rmSync(target, { force: true });
        if (flags.link) fs.symlinkSync(path.join(base, 'agents', e.name), target); else fs.copyFileSync(path.join(base, 'agents', e.name), target);
      }
      agents++;
    }
  }
  const notices = path.join(root, 'guided-plugins', slug);
  if (flags.uninstall) {
    if (!dry) fs.rmSync(notices, { recursive: true, force: true });
  } else if (!dry && skills + agents > before) {
    fs.mkdirSync(notices, { recursive: true });
    for (const f of ['LICENSE', 'NOTICE.md']) fs.copyFileSync(path.join(base, f), path.join(notices, f));
  }
}
if (flags.uninstall && !dry) {
  // leave no empty folders behind, but never remove the root itself
  for (const d of ['skills', 'agents', 'guided-plugins']) {
    const dir = path.join(root, d);
    if (present(dir) && fs.readdirSync(dir).length === 0) fs.rmdirSync(dir);
  }
}
console.log(`${flags.uninstall ? 'removed' : 'installed'} ${skills} skill folder(s) and ${agents} agent file(s) ${dry ? '(dry run) ' : ''}${flags.uninstall ? 'from' : 'into'} ${root}`);
