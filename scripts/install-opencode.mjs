#!/usr/bin/env node
// Installs the OpenCode skills and agents of one or more plugins.
//   node scripts/install-opencode.mjs clean-code refactoring            # project: ./.opencode
//   node scripts/install-opencode.mjs clean-code --project ~/work/app   # that project's .opencode
//   node scripts/install-opencode.mjs clean-code --global               # ~/.config/opencode
//   node scripts/install-opencode.mjs clean-code --link                 # symlink instead of copy (follows git pulls)
//   node scripts/install-opencode.mjs clean-code --uninstall
// Flags: --no-skills, --no-agents, --dry-run. Every skill and agent name starts with the plugin slug, so plugins never collide.
import { DIST, copyTree, fs, home, listDir, parseArgs, path, pickPlugins } from './install-lib.mjs';

const { flags, positional } = parseArgs(process.argv.slice(2), ['project', 'dest']);
const slugs = pickPlugins(positional);
const root = flags.dest ?? (flags.global
  ? path.join(process.env.XDG_CONFIG_HOME ?? path.join(home(), '.config'), 'opencode')
  : path.join(path.resolve(flags.project && flags.project !== true ? flags.project : '.'), '.opencode'));
const dry = !!flags['dry-run'];

let skills = 0; let agents = 0;
for (const slug of slugs) {
  const base = path.join(DIST, 'opencode', slug);
  if (!flags['no-skills']) {
    for (const e of listDir(path.join(base, 'skills')).filter((x) => x.isDirectory())) {
      const target = path.join(root, 'skills', e.name);
      if (flags.uninstall) { if (!dry) fs.rmSync(target, { recursive: true, force: true }); } else if (!dry) copyTree(path.join(base, 'skills', e.name), target, { link: !!flags.link });
      skills++;
    }
  }
  if (!flags['no-agents']) {
    for (const e of listDir(path.join(base, 'agents')).filter((x) => x.isFile())) {
      const target = path.join(root, 'agents', e.name);
      if (flags.uninstall) { if (!dry) fs.rmSync(target, { force: true }); } else if (!dry) {
        fs.mkdirSync(path.dirname(target), { recursive: true });
        fs.rmSync(target, { force: true });
        if (flags.link) fs.symlinkSync(path.join(base, 'agents', e.name), target); else fs.copyFileSync(path.join(base, 'agents', e.name), target);
      }
      agents++;
    }
  }
}
console.log(`${flags.uninstall ? 'removed' : 'installed'} ${skills} skill folder(s) and ${agents} agent file(s) ${dry ? '(dry run) ' : ''}${flags.uninstall ? 'from' : 'into'} ${root}`);
