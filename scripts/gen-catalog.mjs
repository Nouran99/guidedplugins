#!/usr/bin/env node
// Regenerates everything that is derived from the components:
//   per plugin : docs/COMPONENTS.md, docs/TRACEABILITY.md, the COMPONENTS block inside README.md
//   repo level : .claude-plugin/marketplace.json and the plugin table in README.md
// Usage: node scripts/gen-catalog.mjs [plugins/<slug> ...]   (no args = every plugin + repo level)
//        node scripts/gen-catalog.mjs --root                  (repo level only)
import fs from 'node:fs';
import path from 'node:path';
import { ROOT, listPluginDirs, loadPlugin, readIf } from './lib.mjs';
import {
  CATALOG_END, CATALOG_START, buildMarketplace, renderCatalogBlock, renderComponentsDoc,
  renderRootCatalog, renderTraceabilityDoc, replaceReadmeBlock,
} from './catalog-lib.mjs';

function write(file, text) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  const body = text.endsWith('\n') ? text : `${text}\n`;
  if (readIf(file) !== body) { fs.writeFileSync(file, body); return true; }
  return false;
}

function genPlugin(dir) {
  const plugin = loadPlugin(dir);
  if (!plugin.manifest) { console.error(`skip ${dir}: no manifest`); return; }
  const changed = [
    write(path.join(plugin.dir, 'docs', 'COMPONENTS.md'), renderComponentsDoc(plugin)),
    write(path.join(plugin.dir, 'docs', 'TRACEABILITY.md'), renderTraceabilityDoc(plugin)),
  ];
  const readmePath = path.join(plugin.dir, 'README.md');
  const readme = readIf(readmePath);
  if (readme != null) {
    const next = replaceReadmeBlock(readme, renderCatalogBlock(plugin));
    if (next == null) console.error(`warn ${plugin.slug}: README.md has no COMPONENTS markers`);
    else changed.push(write(readmePath, next));
  }
  console.log(`${plugin.slug}: ${changed.some(Boolean) ? 'updated' : 'up to date'}`);
}

function genRoot() {
  const changed = [write(path.join(ROOT, '.claude-plugin', 'marketplace.json'), JSON.stringify(buildMarketplace(), null, 2))];
  const readmePath = path.join(ROOT, 'README.md');
  const readme = readIf(readmePath);
  if (readme && readme.includes(CATALOG_START) && readme.includes(CATALOG_END)) {
    const s = readme.indexOf(CATALOG_START);
    const e = readme.indexOf(CATALOG_END);
    const next = `${readme.slice(0, s + CATALOG_START.length)}\n\n${renderRootCatalog().trim()}\n\n${readme.slice(e)}`;
    changed.push(write(readmePath, next));
  }
  console.log(`repo: ${changed.some(Boolean) ? 'updated' : 'up to date'}`);
}

const args = process.argv.slice(2);
if (args.includes('--root')) genRoot();
else if (args.length) args.forEach((a) => genPlugin(path.resolve(a)));
else { listPluginDirs().forEach(genPlugin); genRoot(); }
