// GitHub Copilot target (verified with Copilot CLI 1.0.101 in an isolated COPILOT_HOME: marketplace add, browse, install, list; no model session).
// Copilot looks for a marketplace file in this order: marketplace.json, .plugin/, .github/plugin/, .claude-plugin/. This repository's
// .github/plugin/marketplace.json therefore wins over the Claude one and points at this build, whose text and agents are rewritten for Copilot.
//   copilot plugin marketplace add Nouran99/guidedplugins   then   copilot plugin install clean-code@guided-plugins
import {
  DIST, REGISTRY, ROOT, VERSION, agentBodyFor, bt, cleanDir, copyFile, flat, modeName, neutralText, path, rewrite, rewriteDescription, writeFile, yaml,
} from './core.mjs';
import { emitFlatSkills, flatDialect, skillDescription } from './agent-skills.mjs';

const TOOL = { Read: 'read', Grep: 'search', Glob: 'search', Bash: 'execute', Edit: 'edit', Write: 'edit' };
const dialect = () => flatDialect({ agentRead: (p, n) => `Load the ${bt(flat(p.slug, n))} skill` });

function agentMd({ name, description, tools, body, userInvocable }) {
  const l = ['---', `name: ${name}`, `description: ${yaml(description)}`];
  if (tools) l.push(`tools: [${tools.join(', ')}]`);
  // a mode is a persona the user picks with /agent; it must never be chosen for delegation by its description
  if (userInvocable) l.push('user-invocable: true', 'disable-model-invocation: true');
  l.push('---', '');
  return `${l.join('\n')}${body}\n`;
}

export function buildCopilot(model) {
  const out = path.join(DIST, 'copilot');
  cleanDir(out);
  const d = dialect();
  const entries = [];
  for (const plugin of model) {
    const root = path.join(out, plugin.slug);
    emitFlatSkills(plugin, path.join(root, 'skills'));
    const preloadLine = (skills) => `Before you start, load these skills: ${skills.map((n) => bt(flat(plugin.slug, n))).join(', ')}.`;
    const roNote = 'Operating constraint: this is a read-only role. Never create, edit, move or delete files; inspect with read-only commands (git diff, git log, git show, git status, ls, grep) and report.';
    for (const a of plugin.agents) {
      const tools = [...new Set(a.tools.map((t) => TOOL[t]).filter(Boolean))];
      writeFile(path.join(root, 'agents', `${flat(plugin.slug, a.name)}.agent.md`), agentMd({
        name: flat(plugin.slug, a.name),
        description: rewriteDescription(a.fm.description, plugin, d, { from: 'agent' }),
        tools, body: agentBodyFor(plugin, a, d, { preloadLine, readOnlyNote: roNote }),
      }));
    }
    for (const m of plugin.styles) {
      const name = flat(plugin.slug, modeName(m.name));
      writeFile(path.join(root, 'agents', `${name}.agent.md`), agentMd({
        name, description: skillDescription(rewriteDescription(m.fm.description, plugin, d, { from: 'agent' }), true), userInvocable: true,
        body: rewrite(m.body.replace(/^\s+/, ''), plugin, d, { from: 'agent' }),
      }));
    }
    writeFile(path.join(root, 'plugin.json'), JSON.stringify({
      name: plugin.slug,
      description: neutralText(plugin.manifest.description),
      version: plugin.manifest.version,
      author: plugin.manifest.author,
      homepage: plugin.manifest.homepage,
      repository: plugin.manifest.repository,
      license: 'MIT',
      keywords: plugin.manifest.keywords,
    }, null, 2));
    copyFile(path.join(plugin.dir, 'LICENSE'), path.join(root, 'LICENSE'));
    writeFile(path.join(root, 'NOTICE.md'), plugin.notice ?? '');
    entries.push({ name: plugin.slug, source: `./dist/copilot/${plugin.slug}`, description: neutralText(plugin.manifest.description), version: plugin.manifest.version });
  }
  const mp = REGISTRY.marketplace;
  writeFile(path.join(ROOT, '.github', 'plugin', 'marketplace.json'), JSON.stringify({
    name: mp.name,
    owner: { name: mp.owner },
    metadata: { description: neutralText(mp.description), version: VERSION },
    plugins: entries,
  }, null, 2));
  return model;
}
