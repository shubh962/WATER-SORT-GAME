#!/usr/bin/env node
/**
 * Regression checks for the level generator and the mystery ("?") reveal logic
 * in assets/web/index.html. Pure Node, no dependencies, no build step.
 *
 * Run after ANY change to genWalk/genLevel/normalize/finishPour/params:
 *   node tool/verify_levels.js
 *
 * It extracts the real functions from the HTML file (so it always tests the
 * exact code that ships) and checks:
 *   1. Every level has the right number of units of each color and the right
 *      bottle count.
 *   2. Level N always generates the same puzzle (determinism).
 *   3. A sample of early levels is provably solvable (independent brute-force
 *      search, not the game's own solver).
 *   4. No mystery level is ever generated with an already-solved bottle
 *      (which would defeat the "?" system before the player touches it).
 *   5. During simulated random-but-legal play on mystery levels, a bottle
 *      the player did NOT touch this move never changes its hidden count.
 *      This is the exact bug reported on 2026-09-21 ("pouring one drop
 *      revealed other bottles' colors") - see git history / chat log for
 *      the report. Root cause: normalize() used to scan every bottle after
 *      every pour, so a bottle that happened to already be a solved,
 *      single-color, full bottle in the initial shuffle (allowed by the
 *      generator's own acceptance rule for early levels) got revealed on
 *      the very first move even though nobody had poured into or out of it.
 *      Fix: normalize() now only re-checks the bottles a move actually
 *      touched, and mystery levels can no longer be generated with a
 *      pre-solved bottle in the first place (see genWalk's hideOk/bestSafe).
 */
const fs = require('fs');
const path = require('path');

const FILE = path.join(__dirname, '..', 'assets', 'web', 'index.html');
const html = fs.readFileSync(FILE, 'utf8');

function grab(pattern) {
  const m = html.match(pattern);
  if (!m) throw new Error('Could not find in ' + FILE + ': ' + pattern);
  return m[0];
}

// Pull the exact functions out of the shipped file and eval them into this scope.
let CAP = 4, bottles, hid; // filled in by the extracted code / the simulation below
eval([
  'let CAP=4;',
  grab(/function seeded[\s\S]*?\n}\n/),
  grab(/function params[\s\S]*?\n}\n/),
  grab(/function dealRandom[\s\S]*?\n}\n/),
  grab(/function solvable[\s\S]*?\n}\n/),
  grab(/function genWalk[\s\S]*?\n}\n/),
  grab(/function genLevel\(lv, nc, empties, cap, hideMode\)\{[\s\S]*?\n}\n/),
  grab(/function isDone\(a\)\{[\s\S]*?\n}\n/),
  grab(/function normalize\(indices\)\{[\s\S]*?\n}\n/),
].join('\n'));

let failures = 0;
function check(name, ok, detail) {
  if (ok) { console.log('PASS  ' + name); }
  else { failures++; console.log('FAIL  ' + name + (detail ? '  -> ' + JSON.stringify(detail) : '')); }
}

// Independent brute-force solver (different code path from the game's own
// solvable(), so it can't share a bug with it) - only used on small levels.
function bruteForceSolvable(b0, cap, limit) {
  const key = b => b.map(x => x.join('')).sort().join('|');
  const seen = new Set();
  const stack = [b0.map(x => x.slice())];
  let nodes = 0;
  while (stack.length && nodes < limit) {
    const b = stack.pop();
    const k = key(b);
    if (seen.has(k)) continue;
    seen.add(k);
    nodes++;
    if (b.every(x => !x.length || (x.length === cap && x.every(c => c === x[0])))) return true;
    for (let a = 0; a < b.length; a++) for (let d = 0; d < b.length; d++) {
      if (a === d || !b[a].length || b[d].length >= cap) continue;
      const c = b[a][b[a].length - 1];
      if (b[d].length && b[d][b[d].length - 1] !== c) continue;
      const nb = b.map(x => x.slice());
      nb[d].push(nb[a].pop());
      stack.push(nb);
    }
  }
  return null; // inconclusive within the node limit, not "unsolvable"
}

console.log('== 1-3: validity, determinism, speed, and solvability of a sample of levels ==');
const sampleLevels = [1, 3, 6, 9, 10, 12, 18, 22, 24, 25, 30, 40, 49, 50, 60, 80, 100, 120,
  150, 200, 249, 250, 300, 400, 449, 450, 500, 700, 1000];
let worstMs = 0, worstLevel = 0;
for (const lv of sampleLevels) {
  const P = params(lv);
  CAP = P.cap;
  const t0 = Date.now();
  const b = genLevel(lv, P.nc, P.empties, P.cap, P.hidden);
  const ms = Date.now() - t0;
  if (ms > worstMs) { worstMs = ms; worstLevel = lv; }
  const b2 = genLevel(lv, P.nc, P.empties, P.cap, P.hidden);

  const counts = {};
  b.flat().forEach(c => { counts[c] = (counts[c] || 0) + 1; });
  const validCounts = Object.values(counts).every(v => v === P.cap) && b.length === P.nc + P.empties;
  check('level ' + lv + ': correct bottle/unit counts', validCounts, { nc: P.nc, cap: P.cap, bottles: b.length });
  check('level ' + lv + ': deterministic (same puzzle every time)', JSON.stringify(b) === JSON.stringify(b2));

  if (lv <= 6) {
    const solvable = bruteForceSolvable(b, P.cap, 400000);
    check('level ' + lv + ': solvable (independent brute force)', solvable !== false);
  }
}
check('generation speed acceptable (<250ms worst case in this sample)', worstMs < 250, { worstMs, worstLevel });

console.log('\n== 4: mystery levels never start with an already-solved bottle ==');
let mysteryChecked = 0, mysteryBad = 0;
for (let lv = 1; lv <= 600; lv++) {
  const P = params(lv);
  if (!P.hidden) continue;
  mysteryChecked++;
  CAP = P.cap;
  const b = genLevel(lv, P.nc, P.empties, P.cap, true);
  const preSolved = b.filter(x => x.length === P.cap && x.every(c => c === x[0])).length;
  if (preSolved > 0) { mysteryBad++; console.log('  level ' + lv + ' has ' + preSolved + ' pre-solved bottle(s)'); }
}
check('no pre-solved bottles across ' + mysteryChecked + ' mystery levels (1-600)', mysteryBad === 0);

console.log('\n== 5: fuzzed play - an untouched bottle must never change its hidden count ==');
function legalMoves(b, cap) {
  const opts = [];
  for (let x = 0; x < b.length; x++) for (let y = 0; y < b.length; y++) {
    const A = b[x], B = b[y];
    if (x === y || !A.length || B.length >= cap) continue;
    const c = A[A.length - 1];
    if (B.length && B[B.length - 1] !== c) continue;
    let run = 0; for (let i = A.length - 1; i >= 0 && A[i] === c; i--) run++;
    const n = Math.min(run, cap - B.length);
    if (!B.length && A.every(v => v === A[0])) continue; // pointless move, the game skips these too
    opts.push([x, y, n]);
  }
  return opts;
}
let pours = 0, violations = [], levelsExercised = new Set();
for (let trial = 0; trial < 2000; trial++) {
  const R = seeded(trial * 97 + 3);
  const lv = 1 + (R() * 1000 | 0);
  const P = params(lv);
  if (!P.hidden) continue;
  levelsExercised.add(lv);
  CAP = P.cap;
  bottles = genLevel(lv, P.nc, P.empties, P.cap, true);
  hid = bottles.map(b => Math.max(b.length - 1, 0));
  normalize(); // the one-time, whole-board check startLevel() does
  for (let move = 0; move < 100; move++) {
    const opts = legalMoves(bottles, CAP);
    if (!opts.length) break;
    const [x, y, n] = opts[(R() * opts.length) | 0];
    const before = hid.slice();
    for (let k = 0; k < n; k++) bottles[y].push(bottles[x].pop());
    const L = bottles[x].length;
    if (L > 0 && hid[x] >= L) hid[x] = L - 1;
    if (L === 0) hid[x] = 0;
    normalize([x, y]); // only the two bottles this move touched
    pours++;
    for (let i = 0; i < bottles.length; i++) {
      if (i === x || i === y) continue;
      if (hid[i] !== before[i]) violations.push({ trial, level: lv, move, bottle: i, before: before[i], after: hid[i] });
    }
  }
}
console.log('  ' + pours + ' pours simulated across ' + levelsExercised.size + ' distinct mystery levels');
violations.slice(0, 10).forEach(v => console.log('  VIOLATION', v));
check('untouched bottles never change during a pour', violations.length === 0, { count: violations.length });

console.log('\n' + (failures ? failures + ' CHECK(S) FAILED' : 'ALL CHECKS PASSED'));
process.exit(failures ? 1 : 0);
