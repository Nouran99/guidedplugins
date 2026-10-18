// Cursor target (EXPERIMENTAL: written to Cursor's documented plugin format; Cursor is not installed where this was built).
//  dist/cursor/<plugin>/.cursor-plugin/plugin.json, skills/ (universal), agents/ (name, description, model: inherit, readonly), rules/<plugin>-rules.mdc
//  .cursor-plugin/marketplace.json at the repository root lists them for Cursor team marketplaces.
import {
  DIST, REGISTRY, ROOT, VERSION, agentBodyFor, bt, cleanDir, copyFile, flat, frontmatter, neutralText, path, rewriteDescription, writeFile,
} from './core.mjs';
import { emitFlatSkills, flatDialect } from './agent-skills.mjs';

// Cursor shows this text to the model to decide whether to apply the rule, so it must say WHEN.
const lowerFirst = (s) => s.replace(/^[A-Z](?![A-Z])/, (c) => c.toLowerCase());
const ruleDescription = (book) => `${book.title} rules, compact form. Apply them when ${lowerFirst(book.usefulWhen.replace(/\.$/, ''))}.`;

const dialect = () => flatDialect({ agentRead: (p, n) => `Load the ${bt(flat(p.slug, n))} skill` });

export function buildCursor(model) {
  const out = path.join(DIST, 'cursor');
  cleanDir(out);
  const d = dialect();
  const mp = REGISTRY.marketplace;
  const entries = [];
  for (const plugin of model) {
    const root = path.join(out, plugin.slug);
    emitFlatSkills(plugin, path.join(root, 'skills'));
    const preloadLine = (skills) => `Before you start, load these skills: ${skills.map((n) => bt(flat(plugin.slug, n))).join(', ')}.`;
    for (const a of plugin.agents) {
      const body = agentBodyFor(plugin, a, d, { preloadLine });
      writeFile(path.join(root, 'agents', `${flat(plugin.slug, a.name)}.md`), frontmatter({
        name: flat(plugin.slug, a.name),
        description: rewriteDescription(a.fm.description, plugin, d, { from: 'agent' }),
        model: 'inherit',
        readonly: a.readOnly,
      }) + body);
    }
    writeFile(path.join(root, 'rules', `${plugin.slug}-rules.mdc`), frontmatter({
      description: ruleDescription(plugin.book),
      alwaysApply: false,
    }) + (plugin.refs.nano ?? ''));
    writeFile(path.join(root, '.cursor-plugin', 'plugin.json'), JSON.stringify({
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
    entries.push({ name: plugin.slug, source: `./dist/cursor/${plugin.slug}`, description: neutralText(plugin.manifest.description) });
  }
  writeFile(path.join(ROOT, '.cursor-plugin', 'marketplace.json'), JSON.stringify({
    name: mp.name,
    owner: { name: mp.owner },
    metadata: { description: neutralText(mp.description), version: VERSION },
    plugins: entries,
  }, null, 2));
  return model;
}
