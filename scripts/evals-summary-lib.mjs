// Turns the result of one `claude plugin eval` pass into the compact summary that is committed (evals/summary/<slug>.json).
// A run's "defect score" is the share, by weight, of the graders about planted problems that passed. The slash variants carry extra graders
// that check the report format (names starting with "slash-"); they are reported separately so that the workflow is compared with the baseline
// on the same graders and not credited for a free format check.
const mean = (xs) => { const v = xs.filter((x) => typeof x === 'number'); return v.length ? Math.round((v.reduce((a, b) => a + b, 0) / v.length) * 1000) / 1000 : null; };
const isFormat = (g) => g.name.startsWith('slash-');
const scoredDefects = (run) => (run.graders ?? []).filter((g) => g.scored !== false && !isFormat(g));
export function defectScore(run) {
  const gs = scoredDefects(run);
  const total = gs.reduce((n, g) => n + (g.weight ?? 1), 0);
  return total ? gs.filter((g) => g.passed).reduce((n, g) => n + (g.weight ?? 1), 0) / total : null;
}
function formatOk(runs) {
  const rs = runs.map((r) => (r.graders ?? []).filter(isFormat)).filter((g) => g.length);
  return rs.length ? mean(rs.map((g) => (g.every((x) => x.passed) ? 1 : 0))) : null;
}
function firedShare(runs) {
  const hits = runs.map((r) => (r.graders ?? []).find((g) => g.name === 'skill-fired')).filter(Boolean);
  return hits.length ? Math.round((hits.filter((g) => g.passed).length / hits.length) * 100) / 100 : null;
}
export function failedRunErrors(res) {
  return (res.cases ?? []).flatMap((c) => ['with', 'without'].flatMap((arm) => (c.arms?.[arm] ?? []).filter((r) => r.error).map((r) => r.error)));
}
export function compact(id, ablation, res, model, runs) {
  const cases = (res.cases ?? []).map((c) => ({
    name: c.name,
    defectWith: mean((c.arms?.with ?? []).map(defectScore)),
    defectWithout: mean((c.arms?.without ?? []).map(defectScore)),
    formatOk: formatOk(c.arms?.with ?? []),
    skillFired: firedShare(c.arms?.with ?? []),
    scoreAllGraders: c.aggregates?.score ?? null,
  }));
  return {
    id, ablation, model, runsPerCase: runs,
    claudeVersion: res.claudeVersion ?? null,
    costUsd: res.costUsd ?? null,
    partial: !!res.partial,
    cases,
  };
}
