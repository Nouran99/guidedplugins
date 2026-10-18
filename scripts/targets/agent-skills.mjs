// Universal target: the open Agent Skills layout (agentskills.io). Every skill and persona becomes a folder named
// <plugin>-<name> with spec-clean frontmatter. Read by Codex, OpenCode, Gemini CLI, Copilot, Cursor and ~75 other agents
// (directly, or through `npx skills add`). The other flat targets (OpenCode, Gemini, Cursor, Copilot) reuse this emitter.
import {
  DIST, MANUAL_SUFFIX, cleanDir, copyFile, flat, fs, frontmatter, modeName, path, rewrite, writeFile,
} from './core.mjs';

const bt = (s) => `\`${s}\``;

// agentRead(plugin, name, backticked) lets a target override how an AGENT is told to load a skill.
export function flatDialect({ agentRead } = {}) {
  const defaultAgentRead = (p, n) => `Load the ${bt(flat(p.slug, n))} skill`;
  const readFor = agentRead ?? defaultAgentRead;
  const hubRel = (p, ctx) => (ctx.skill === 'principles' ? '' : `../${flat(p.slug, 'principles')}/`);
  return {
    id: 'flat',
    argsLine: 'the text the user typed after the skill name (empty if none)',
    argsInline: 'the argument text',
    refSkill: (p, n) => flat(p.slug, n),
    refAgent: (p, n) => flat(p.slug, n),
    refStyle: (p, n) => flat(p.slug, modeName(n)),
    readSkill: (p, n, ctx, backticked) => {
      if (ctx.from === 'agent') return readFor(p, n, backticked);
      const rel = ctx.from === 'doc' ? `../../${flat(p.slug, n)}/SKILL.md` : `../${flat(p.slug, n)}/SKILL.md`;
      return backticked ? `Read ${bt(rel)}` : `Read ${rel}`;
    },
    skillFile: (p, n, ctx) => {
      if (ctx.from === 'agent') return { phrase: `the ${bt(flat(p.slug, n))} skill` };
      return { path: ctx.from === 'doc' ? `../../${flat(p.slug, n)}/SKILL.md` : `../${flat(p.slug, n)}/SKILL.md` };
    },
    skillsDir: (p, ctx) => (ctx.from === 'agent' ? { phrase: `the skill folders of the ${bt(p.slug)} plugin` } : { path: ctx.from === 'doc' ? '../../' : '../' }),
    refFile: (p, r, ctx) => {
      if (ctx.from === 'agent') return { phrase: `the ${bt(`references/${r}.md`)} file of the ${bt(flat(p.slug, 'principles'))} skill` };
      if (ctx.from === 'doc') return { path: `${r}.md` };
      return { path: `${hubRel(p, ctx)}references/${r}.md` };
    },
    designFile: (p, ctx) => {
      if (ctx.from === 'agent') return { phrase: `the ${bt('references/design.md')} file of the ${bt(flat(p.slug, 'principles'))} skill` };
      if (ctx.from === 'doc') return { path: 'design.md' };
      return { path: `${hubRel(p, ctx)}references/design.md` };
    },
  };
}

const PERSONA_PREFACE = 'Adopt this mode for the rest of the session, until the user asks you to stop or to switch to another mode. It changes how you respond; it does not change what you are allowed to do.\n\n';

export function skillDescription(text, manual) {
  const base = text.replace(/\s+/g, ' ').trim();
  return manual ? `${base} ${MANUAL_SUFFIX}` : base;
}

// Writes every skill and persona of one plugin as <root>/<plugin>-<name>/SKILL.md (+ references).
export function emitFlatSkills(plugin, root, dialect = flatDialect()) {
  const rw = (text, ctx) => rewrite(text, plugin, dialect, ctx);
  const meta = (extra) => ({ plugin: plugin.slug, book: plugin.book.title, ...extra });
  const written = [];

  for (const s of plugin.skills) {
    const dir = path.join(root, flat(plugin.slug, s.name));
    const ctx = { from: 'skill', skill: s.name };
    const fm = frontmatter({
      name: flat(plugin.slug, s.name),
      description: skillDescription(rw(s.fm.description, ctx), s.manual),
      license: 'MIT',
      metadata: meta({ invocation: s.manual ? 'manual' : 'auto', ...(s.fm['argument-hint'] ? { 'argument-hint': s.fm['argument-hint'] } : {}) }),
    });
    writeFile(path.join(dir, 'SKILL.md'), fm + rw(s.body, ctx));
    for (const f of s.files) copyFile(path.join(s.dir, f), path.join(dir, f)); // references/{full,mini,nano}.md, verbatim upstream
    written.push(flat(plugin.slug, s.name));
  }

  // the maintainers' component map travels with the hub because one skill points at it
  if (plugin.design) writeFile(path.join(root, flat(plugin.slug, 'principles'), 'references', 'design.md'), rw(plugin.design, { from: 'doc' }));

  for (const m of plugin.styles) {
    const name = flat(plugin.slug, modeName(m.name));
    const ctx = { from: 'skill', skill: modeName(m.name) };
    const fm = frontmatter({
      name,
      description: skillDescription(rw(m.fm.description, ctx), true),
      license: 'MIT',
      metadata: meta({ invocation: 'manual', kind: 'mode' }),
    });
    writeFile(path.join(root, name, 'SKILL.md'), fm + PERSONA_PREFACE + rw(m.body, ctx));
    written.push(name);
  }
  return written;
}

export function buildAgentSkills(model) {
  const out = path.join(DIST, 'agent-skills');
  cleanDir(out);
  const index = [];
  for (const plugin of model) {
    const names = emitFlatSkills(plugin, path.join(out, plugin.slug));
    copyFile(path.join(plugin.dir, 'LICENSE'), path.join(out, plugin.slug, 'LICENSE'));
    writeFile(path.join(out, plugin.slug, 'NOTICE.md'), plugin.notice ?? '');
    index.push({ plugin: plugin.slug, skills: names.length });
  }
  writeFile(path.join(out, 'README.md'), `# Agent Skills build

${'Generated by scripts/build-targets.mjs from plugins/ in this repository. Do not edit by hand.'}

One folder per book plugin, each holding that plugin's skills in the open [Agent Skills](https://agentskills.io) layout:
\`<plugin>/<plugin>-<name>/SKILL.md\`. Skill names are prefixed with the plugin so they never collide in agents that keep one flat list.
Install a whole plugin (its skills reference each other and the \`${'<plugin>-principles'}\` hub by relative path, so keep them together).

See [docs/AGENTS_SUPPORT.md](../../docs/AGENTS_SUPPORT.md) for per-agent instructions.

| Plugin | Skills and modes |
| --- | ---: |
${index.map((i) => `| \`${i.plugin}\` | ${i.skills} |`).join('\n')}
`);
  return index;
}
