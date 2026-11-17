#!/usr/bin/env node
// Posts the review.json written by guided-review-ci.mjs to a pull request as ONE review, skipping findings that an earlier run already posted
// (each inline comment and each body bullet carries a <!-- guided-plugins:HASH --> marker; the hash is of the book, the rule, the path and the
// text of the cited line, not of the model's wording), so a re-run on a new push does not repeat itself. A finding that the model reports for a
// different line of text, or under a different rule name, is a new finding and is posted.
//   node scripts/github-post-review.mjs --repo owner/name --pr 12 --review .guided-review/review.json [--commit SHA] [--dry]
// Uses the GitHub CLI (`gh`) and its token (GH_TOKEN in Actions). The token needs pull-requests: write.
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';

const args = process.argv.slice(2);
const opt = (k) => { const i = args.indexOf(`--${k}`); return i >= 0 ? args[i + 1] : undefined; };
const repo = opt('repo'); const pr = opt('pr'); const file = opt('review');
if (!repo || !/^[\w.-]+\/[\w.-]+$/.test(repo) || !/^\d+$/.test(pr ?? '') || !file) { console.error('usage: github-post-review.mjs --repo owner/name --pr NUMBER --review review.json [--commit SHA] [--dry]'); process.exit(2); }
const gh = opt('gh') ?? process.env.GUIDED_GH ?? 'gh';
const call = (a, input) => spawnSync(gh, a, { encoding: 'utf8', input, maxBuffer: 64 * 1024 * 1024 });

const review = JSON.parse(fs.readFileSync(file, 'utf8'));
const listed = (path) => {
  const r = call(['api', '--paginate', path]);
  if (r.status !== 0) { console.error(`gh api ${path} failed: ${r.stderr.trim()}`); process.exit(2); }
  // --paginate prints one JSON array per page
  return r.stdout.trim().split(/\n(?=\[)/).flatMap((chunk) => (chunk ? JSON.parse(chunk) : []));
};
const seen = new Set();
for (const c of [...listed(`repos/${repo}/pulls/${pr}/comments`), ...listed(`repos/${repo}/pulls/${pr}/reviews`)]) for (const m of (c.body ?? '').matchAll(/<!-- guided-plugins:([0-9a-f]+) -->/g)) seen.add(m[1]);

// What counts as "already posted": an inline comment, or a bullet of the review body, carrying a marker that an earlier run left. The wording of the
// summary is not part of it, so a re-run with a different summary does not repost findings.
const markerOf = (text) => text.match(/<!-- guided-plugins:([0-9a-f]+) -->/)?.[1];
const fresh = (review.comments ?? []).filter((c) => { const m = markerOf(c.body); return !(m && seen.has(m)); });
const freshRest = (review.rest ?? []).filter((r) => !seen.has(r.fp));
if (!fresh.length && !freshRest.length) { console.log(review.rest || review.comments ? 'nothing new to post' : 'no findings; nothing to post'); process.exit(0); }
const body = review.head !== undefined
  ? `${review.head}${freshRest.length ? `\n\nNot on a changed line:\n${freshRest.map((r) => r.text).join('\n')}` : ''}${review.tail ? `\n\n${review.tail}` : ''}`
  : review.body;
const payload = { event: 'COMMENT', body, comments: fresh, ...(opt('commit') ? { commit_id: opt('commit') } : {}) };
if (args.includes('--dry')) { console.log(JSON.stringify(payload, null, 2)); process.exit(0); }
const r = call(['api', '-X', 'POST', `repos/${repo}/pulls/${pr}/reviews`, '--input', '-'], JSON.stringify(payload));
if (r.status !== 0) { console.error(`posting the review failed: ${r.stderr.trim()}`); process.exit(2); }
console.log(`posted a review with ${fresh.length} inline comment(s)`);
