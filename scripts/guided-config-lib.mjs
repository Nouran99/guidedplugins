// The project settings file, .guided-plugins.json (docs/guided-plugins.schema.json, docs/PROJECT_CONFIG.md): loading, validation, the
// compatibility verdict of two books, and the ignore globs. Zero dependencies.
import fs from 'node:fs';
import path from 'node:path';
import { REGISTRY, ROOT } from './lib.mjs';

export const CONFIG_FILE = '.guided-plugins.json';
export const STRICTNESS = ['relaxed', 'normal', 'strict'];
export const FAIL_ON = ['blocker', 'major', 'minor', 'nit', 'never'];
export const DEFAULTS = { version: 1, primary: null, secondary: [], strictness: 'normal', ignore: [], maxFindings: 15, failOn: 'major' };
export const SLUGS = REGISTRY.books.map((b) => b.slug);

// ------------------------------------------------------------------ pair verdicts, from the table in docs/COMPATIBILITY.md section 3
let pairs = null;
export function pairTable() {
  if (pairs) return pairs;
  pairs = new Map();
  const text = fs.readFileSync(path.join(ROOT, 'docs', 'COMPATIBILITY.md'), 'utf8');
  for (const m of text.matchAll(/^\| `([a-z-]+)` \| `([a-z-]+)` \| (\*\*)?(Complementary|Overlap|Conflicting)(\*\*)? \| (\d+)% \| (\d+)% \| (\d+)% \|$/gm)) {
    const row = { a: m[1], b: m[2], verdict: m[4], conflict: Number(m[6]), overlap: Number(m[7]), complementarity: Number(m[8]) };
    pairs.set(`${m[1]}|${m[2]}`, row);
    pairs.set(`${m[2]}|${m[1]}`, row);
  }
  return pairs;
}
export const pairVerdict = (a, b) => pairTable().get(`${a}|${b}`) ?? null;

// ------------------------------------------------------------------ validation
export function validateConfig(cfg) {
  const problems = []; const notes = [];
  if (cfg === null || typeof cfg !== 'object' || Array.isArray(cfg)) return { problems: ['the file must contain a JSON object'], notes };
  const known = new Set(['$schema', ...Object.keys(DEFAULTS)]);
  for (const k of Object.keys(cfg)) if (!known.has(k)) problems.push(`unknown setting "${k}" (known: ${[...known].filter((x) => x !== '$schema').join(', ')})`);
  if (cfg.version !== undefined && cfg.version !== 1) problems.push('version must be 1');
  if (cfg.primary !== undefined && cfg.primary !== null && !SLUGS.includes(cfg.primary)) problems.push(`primary "${cfg.primary}" is not one of the books: ${SLUGS.join(', ')}`);
  if (cfg.secondary !== undefined) {
    if (!Array.isArray(cfg.secondary)) problems.push('secondary must be a list of book slugs');
    else {
      for (const s of cfg.secondary) if (!SLUGS.includes(s)) problems.push(`secondary "${s}" is not one of the books`);
      if (new Set(cfg.secondary).size !== cfg.secondary.length) problems.push('secondary lists a book twice');
      if (cfg.primary && cfg.secondary.includes(cfg.primary)) problems.push('the primary book must not also be listed in secondary');
      if (cfg.secondary.length > 3) problems.push('secondary lists more than 3 books; every extra book adds reviewers, cost and disagreements');
      if (cfg.secondary.length && !cfg.primary) problems.push('secondary needs a primary book to arbitrate');
    }
  }
  if (cfg.strictness !== undefined && !STRICTNESS.includes(cfg.strictness)) problems.push(`strictness must be one of ${STRICTNESS.join(', ')}`);
  if (cfg.failOn !== undefined && !FAIL_ON.includes(cfg.failOn)) problems.push(`failOn must be one of ${FAIL_ON.join(', ')}`);
  if (cfg.maxFindings !== undefined && !(Number.isInteger(cfg.maxFindings) && cfg.maxFindings >= 1 && cfg.maxFindings <= 100)) problems.push('maxFindings must be an integer from 1 to 100');
  if (cfg.ignore !== undefined && !(Array.isArray(cfg.ignore) && cfg.ignore.every((g) => typeof g === 'string' && g.length))) problems.push('ignore must be a list of glob strings');
  else for (const g of cfg.ignore ?? []) { const why = unsupportedIgnore(g); if (why) problems.push(`ignore "${g}" ${why}; supported: * ? ** a leading / a trailing /`); }
  // The compatibility verdict of every pair of chosen books is a note, not an error: the user may know better.
  const chosen = [cfg.primary, ...(Array.isArray(cfg.secondary) ? cfg.secondary : [])].filter(Boolean);
  for (let i = 0; i < chosen.length; i++) for (let j = i + 1; j < chosen.length; j++) {
    const p = pairVerdict(chosen[i], chosen[j]);
    if (p && p.verdict !== 'Complementary') notes.push(`${chosen[i]} + ${chosen[j]}: ${p.verdict} (conflict ${p.conflict}%, overlap ${p.overlap}%). ${chosen[i] === cfg.primary || chosen[j] === cfg.primary ? 'The primary book decides where they disagree; use the other only for a narrow, named decision.' : 'Two secondary books overlap; keep one.'}`);
  }
  return { problems, notes };
}

export function loadConfig(root) {
  const file = path.join(root, CONFIG_FILE);
  if (!fs.existsSync(file)) return { config: { ...DEFAULTS }, file: null, problems: [], notes: [] };
  let raw;
  try { raw = JSON.parse(fs.readFileSync(file, 'utf8')); } catch (e) { return { config: { ...DEFAULTS }, file, problems: [`${CONFIG_FILE} is not valid JSON: ${e.message}`], notes: [] }; }
  const { problems, notes } = validateConfig(raw);
  return { config: { ...DEFAULTS, ...raw }, file, problems, notes };
}

// ------------------------------------------------------------------ ignore globs: ** crosses folders, * and ? stay inside one
export function globToRegExp(glob) {
  let re = '';
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i];
    if (c === '*') {
      if (glob[i + 1] === '*') { i++; if (glob[i + 1] === '/') { i++; re += '(?:.*/)?'; } else re += '.*'; } else re += '[^/]*';
    } else if (c === '?') re += '[^/]';
    else re += c.replace(/[.+^${}()|[\]\\]/g, '\\$&');
  }
  return new RegExp(`^${re}$`);
}
export function isIgnored(file, patterns) {
  const f = file.replace(/\\/g, '/').replace(/^\.\//, '');
  // like .gitignore for the supported syntax: a leading slash anchors the pattern at the root; a pattern with no other slash matches the name
  // at any depth; a trailing slash means the whole folder; ** crosses folders
  return patterns.some((g) => {
    let gg = g.replace(/^\.\//, '');
    const anchored = gg.startsWith('/');
    if (anchored) gg = gg.slice(1);
    const folder = gg.endsWith('/');
    if (folder) gg = gg.slice(0, -1);
    if (!anchored && !gg.includes('/')) gg = `**/${gg}`;
    return globToRegExp(folder ? `${gg}/**` : gg).test(f) || (!folder && globToRegExp(`${gg}/**`).test(f));
  });
}
// Syntax that .gitignore has and this matcher does not: say so when the file is validated instead of silently never matching.
export const unsupportedIgnore = (g) => (/^[!#]/.test(g) ? 'starts with ! or # (negation and comments are not supported)' : /[[\]\\]/.test(g) ? 'uses [ ], or a backslash (character classes and escapes are not supported)' : null);
