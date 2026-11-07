# Production response judging, all four judges: the plan (draft, 2026-11-06)

Written for Roger to approve before an Opus agent builds it.  Nothing here has been run; no code was changed.  Terms as in [response_judging_plan.md](./response_judging_plan.md): a *response* is one answer Qwen-3-32B gave as an entity to one of the 100 questions under one of its five instructions; *kept* means step 3 scored it 3; *ρ* is the Spearman correlation, over an axis's entities, between the judge's per-entity mean and the activation projection; a *slot* is one (question, instruction) pair; a *share* is a golden part j of J of the slots.  Other jargon: [glossary.md](../trait_gap_generation/glossary.md).

## 1. Goal

One production driver that judges every kept October response (or a golden share of them) on the 321 October axes with any of the four judges, under the balanced slot schedule, and writes per-axis cells the existing readers take.  The mix (which judges take which share, and the weights) is **not** decided and stays a separate step.  Jev's part is built first and tested on the May ninth; the three LLM judges share the schedule and batching and differ by backend parameters.

Scope found while reading: **combinations are out.**  The projection corpus ([`load_corpus`](../../results_analysis/axis_judge_correlation.py)) reads `{roles,traits}/vectors` only, no axis has a combination pole, and no reader keys combinations; the 1,800 October combination entities stay unjudged by this tool.  Traits and roles: 932 + 339 entities, 541,109 kept responses in 500 slots of 678–1,235 (the brief's 636,500 is the total before the filter; 1,271 entities, not 1,273).  Two entities are below 100 kept ([brown_eyed](../../data/traits/instructions/brown_eyed.json) 71, [body_confident](../../data/traits/instructions/body_confident.json) 93).

## 2. Decisions taken as fixed, with sources

| Decision | Source |
|---|---|
| Jev's question: the plain Noul between the ends, "is the persona behind answer k nearer the *hi* end of axis X than the *lo* end?" (`--batch_question noul`, the default since 2026-11-05) | [judge_responses_jev.py](../../scripts/judge_responses_jev.py); [working_with_jev.md](./working_with_jev.md) § 4 |
| Jev: 20 answers a request, never fewer; up to 34 axes a request as even chunks; reroll a batch's answers that do not fit; a lower cap for wordy questions; split the axes last, never the answers | [AGENT_NOTES.md](../../AGENT_NOTES.md) "Fitting a batch under Jev's limit"; `split_axes_to_fit` |
| The schedule: slots (question, instruction); batches of 20 within a slot from different entities; one schedule per slot (grouping, order, directions), balanced: greedy social-golfer grouping, Hungarian positions, each axis half its slots each way | AGENT_NOTES "The schedule: balanced, not random" |
| Padding: last batch to 20 with repeats not already in it; a slot under 20 padded from the same question's other instructions; at least 30 in all or error out loudly; a repeat averaged before the entity mean | AGENT_NOTES "No batch smaller than 20" |
| Directions never fixed; Jev pinned to `jev-1.14.0` (`--expect_model`) | judging rule; `DEFAULT_MODEL` |
| Any split between judges is golden, frac((5Q+p)/φ), never by question | [response_judging_plan.md](./response_judging_plan.md) § 4e |
| LLM judges: 20 answers a call from different entities, scores alone, the cached-prefix rubrics `r1_pn` (one axis) and `rk_pn` (stacked, plain); Luna Flex k=4 worst 20%; Haiku Message Batches k=2 worst 10%; Gemini Batch API with explicit caches k=6 worst 20% (format and 20/40 answers under recheck; parameters) | § 4d, § 4e; [judge_tier_rubrics.py](../../results_analysis/judge_tier_rubrics.py) |
| The axis list: every opposed pair in the corpus's `arrangement` fields: 297 trait pairs, the four corner squares' diagonals (8), the MBTI 4-cube's antipodes (8), 6 role pairs and Berry's square's diagonals (2): **321 axes** (313 trait, 8 role) | Roger, 2026-11-06 |
| Usage logging on every backend; batch or Flex as a flag; over $20 needs Roger's go with parameters listed | [CLAUDE.md](../../CLAUDE.md) hard rules |

## 3. Design

### 3.1 Shape: three layers, nothing rewritten

The repository's production pattern is [judge_descriptions.py](../../results_analysis/judge_descriptions.py): a thin driver holding the settled constants, running [judge_tier_cost_eval.py](../../results_analysis/judge_tier_cost_eval.py) (the LLM judges: transports, batch runners, explicit caches, answer logs, stall restarts, cells) and the Jev tool as subprocesses, then averaging with [judge_tier_average.py](../../results_analysis/judge_tier_average.py).  Follow it:

1. **A schedule module**, [`assistant_axis/response_schedule.py`](../../assistant_axis/response_schedule.py) (does not exist yet): slots, slot batching with padding, the balanced schedule (grouping, positions, directions), its JSON form, and the repeat-key helpers.  Pure functions on item lists; no I/O but load/save; imported by both judging tools.
2. **The two judging tools gain a schedule mode.**  [judge_responses_jev.py](../../scripts/judge_responses_jev.py) `--schedule balanced` (default `fixed`, today's `relative_requests`, so the `jb61_*` cells resume unchanged), plus the token model, per-question caps, rerolls and the compact log.  [judge_tier_cost_eval.py](../../results_analysis/judge_tier_cost_eval.py) `--schedule balanced` and `--batch_by slot` (defaults `random` and `question`, today's `stack_plan` and `item_groups`), the schedule replacing the per-batch random regrouping and the per-call direction coin.  Why extend rather than write a new tool: the A/B test the TODO asks for is the same tool with one flag changed; the transports, caches, logs and cells (3,400 lines, all exercised this month) are reused; and [judge_descriptions.py](../../results_analysis/judge_descriptions.py) already shows the driver shape.
3. **The driver**, [`results_analysis/judge_responses.py`](../../results_analysis/judge_responses.py) (does not exist yet): the per-judge constants, the axis list from the corpus, the share flag, the worst-axes pilot, the two runs per LLM judge (stacked, and the worst axes one axis a call), labels, the per-judge merge of pilot and main cells, `--dry_run` with the cost, and (off by default, since the mix is undecided) the blend.

### 3.2 The slot schedule, shared by every judge

Built once per run from (axis list, slot list, seed, groups per slot), in seconds, and stored with the run (`schedule.json` in the run's work directory; a resume loads it and refuses a run whose axes or slots differ).  A judge's schedule covers only the slots its share holds.  Per slot: a partition of the axes into even groups, each group's order (positions, so letters), and each axis's direction.  The LLM judges' stacked runs use groups of k; the worst-axes runs use only the directions; Jev uses ceil(N / cap_q) groups per slot (10 groups of 32–33 at N = 321, cap 34).  The simulation's balance ([design.py](/tmp/claude-501/golfer/design.py), a throwaway sketch; 200 axes, 6 groups, 500 slots) is what the tests pin: pair meetings 81 ± 1.5 against random's ± 8.3, positions ± 0.18 against ± 3.9, per entity after the 15% filter ± 4.7% against 11%.

### 3.3 Slot batching and padding

Within a slot the kept responses are shuffled by seed and cut into batches of 20; the remainder is padded with repeats; a slot under 20 is padded from the same question's other instructions.  On October this is 27,281 batches a pass, 4,611 repeats (0.85%).  Every batch holds 20 distinct responses from 20 distinct entities.  A repeat carries a marked key (`<key>~2`) so the two scores are kept apart until the per-item average.

### 3.4 Jev

Requests from the schedule: per batch, one request per group (its axes in position order, letters A…AH, directions from the schedule).  Before sending, the token model sizes every request; the few questions whose batches run long get a lower cap (more, smaller groups, so a different schedule group count for those slots); batches still over the limit are rerolled by swapping answers within the slot; what is left is split by axes.  Nothing Jev reads changes in form (§ 4.7).  The answer log keeps every value as an integer 0–100 in a compact record (§ 5), resumes as today, and the settings header carries the schedule digest and the caps.

### 3.5 The LLM judges

Two runs per judge on the same slot batches: the stacked run (`rk_pn`, `--stack k`, every axis not in the judge's worst set) and the worst-axes run (`r1_pn`, `--stack 1`, one axis a call, a batch's calls one after another so the prefix stays cached).  The schedule supplies the stacked groups, their letter order and every direction; `stack_plan` and the per-call coin are bypassed under `--schedule balanced`.  Transports as today (`--transport auto`: Luna Flex, Haiku Message Batches, Gemini Batch API), caches as today (OpenAI's two-part prompt with the breakpoint between prefix and axis; Gemini `--gemini_cache explicit`, a prefix under 1,024 tokens sent whole).  Gemini's format (`rk_pn` / `rk_pl` / `rk_pa`) and answers per call (20 / 40) are driver parameters, defaults plain and 20.

**The worst X% (the rule production needs).**  In the experiments the worst axes were chosen by stacking penalty, cross-fitted over nine question folds of cells judged both ways ([judge_response_pareto.py](../../scripts/judge_response_pareto.py) `worst_out`).  Production rule: **a pilot share, judged both ways, ranks the axes; the rest of the share runs on the ranking.**  The pilot is the first 1/27 golden part inside the judge's share (27 = 3 × 9 nests in thirds and ninths; about 18 slots, 20,000 responses, 3.7% of the run), judged stacked at the judge's k on every axis and one axis a call on every axis; per axis the penalty is ρ(stacked) − ρ(one axis a call), the mean over the 12 projection variants on the pilot's items; the worst X% by penalty are the judge's worst set, written to `<work>/worst_axes_<judge>.tsv` and used for the remaining 26/27.  The pilot's scores count toward coverage: on pilot items an axis keeps both arms' scores, averaged (§ 4.5).  Cost: the arm not kept, about 1/27 of a one-axis-a-call run (§ 7).  Per judge, since the bad axes differ by judge.  The cheaper 1/81 pilot the plan once named is the alternative (§ 9).

### 3.6 Shares, the mix and the blend

The driver takes `--judge_model` (repeatable) and `--share j/J` (golden; `all` for everything) and runs each judge on that share.  The combination is a separate step.  **What [judge_tier_average.py](../../results_analysis/judge_tier_average.py) does today:** `average_cells` takes each judge's per-entity mean over its own cells, then `combine_tier_judges`, which **renormalises the weights over the judges that scored the entity** (an entity one judge missed takes the others' weights); weights come from `tier_judge_weights(judges, mode)` with the mode read from the scores file name; a source holding under 90% of the axis's entities is refused.  So a mix of golden shares blends correctly once the weights exist: [judge_score_combine.py](../../assistant_axis/judge_score_combine.py) `TIER_JUDGE_WEIGHTS_BY_MODE` has no `"responses"` entry, so Jev would weigh 3 like Haiku and Gemini.  The weights are an open decision (§ 9).

### 3.7 The axis list and October projections

The list is derived in code from [arrangements.py](../../assistant_axis/arrangements.py) (`load_corpus_arrangements`, `canonical_kind`): every `pair` (297 traits, 6 roles); every `axes` entry of an orthoplex or square (all already pairs today; the rule takes an octahedron's axes if one appears); the two diagonals of each square without `axes` (Bartle, attachment, Baumrind, DISC, Berry: 10); the 4-cube's antipodes (the MBTI code with all four letters flipped: 8).  Deduplicated by unordered pole pair: 321.  Checked: every pole has an October vector; no entity is in two axes.  The corner squares record no `axes`, so their diagonals need a rule: **recommendation: record `axes` in the corpus** (the schema already carries it for Inglehart–Welzel and the orthoplexes; 20 member files, a data change for Roger's go), and until then an explicit five-square table in the driver that warns when used and is deleted once the corpus records them.  The MBTI antipodes stay a code rule (the cube records no coordinates).

Projections: the tools read `<experiments_dir>/<axis_dir>/gpt/projections.json`, which for the 61 May axes are May projections.  October needs its own experiments directory, [`roger/axis_judge_experiments_october/`](../../roger/axis_judge_experiments_october/) (does not exist yet; git-ignored like its sibling), with projections written by [axis_judge_correlation.py](../../results_analysis/axis_judge_correlation.py) `--projections_only --data_dir` <../../runpod_workspace/qwen/qwen-3-32b%20Roger%20October/> per axis.  That path loads every vector (1,271 × 10.5 MB) per axis; time one axis before running 321, and if it is minutes, add a multi-axis `--projections_only` that loads the corpus once (build step 7).  The pos/neg order and `pair_type` of each axis go into an axes file the driver writes, `<experiments_dir>/axes_october.tsv`, in the tools' four-column form.

## 4. Algorithms

Notation: an item is `(etype, key, (question text, answer))` with key `name|p{p}q{q}` as today; Q = `absolute_question(text)` (the records' `question_id`, 3 × `question_index` on both trees); a slot is `(Q, p)`; T slots; N axes in axes-file order.

### 4.1 Slots and shares
- `slot(item) = (absolute_question(text), p)`.  The golden point depends on (Q, p) only, so a share is a set of whole slots: slot ∈ share j of J iff `golden_part(Q, p, J) == j`.  `--response_split J --response_part j` already does this per item; the schedule module groups the surviving items by slot.
- Invariant: every item of a run lies in exactly one slot; the union of the J shares is every slot once.

### 4.2 Batches with padding
Inputs: the slot's items `S` (one per entity), the slot's question pool `P` = items of every slot `(Q, p')`, `p' ≠ p`, available to this run, seed.
1. `rng = Random(f"slot|{seed}|{Q}|{p}")`; shuffle `S`; cut into full batches of 20; remainder `r = |S| mod 20`.
2. If `|S| ≥ 20` and `r > 0`: pad the last batch with `20 − r` items drawn without replacement by `rng` from `S` minus the last batch, each under key `<key>~2`.
3. If `|S| < 20`: one batch of `S` plus `20 − |S|` items drawn from `P` (keys unmarked; they are items of other slots, judged here once more and averaged like repeats).
4. **Error** (`SystemExit`, naming the slot and the counts) if `|S| + |P| < 30`.  Checked for every slot, before any request.
Invariants: every batch has exactly 20 entries, 20 distinct underlying keys, 20 distinct entities; the multiset of unmarked keys over a slot's batches is `S` exactly once each; marked keys are each in `S` and appear at most once; a marked key never shares a batch with its original.

### 4.3 The schedule
Inputs: axes `A[0..N)`, slots `s_1..s_T` in sorted order, `seed`, `groups(s)` (an integer per slot).  State: `C` (N × N meeting counts), `P` (N × maxpos position counts).  For each slot in order:
1. **Grouping.** `rng = Random(f"group|{seed}|{Q}|{p}")`.  Sizes: `groups(s)` even parts of N (floor/ceil).  Start from a random partition; then up to 4 sweeps over the axes in random order: for axis a in group g, the best single swap with an axis b in another group by the change in Σ(same-group C) (as `greedy_slot` in the sketch, O(N) per axis with the S[x, k] table); apply when it lowers the sum; stop a sweep early when nothing moved.  Then `C[a, b] += 1` for every same-group pair.
2. **Positions.** Per group, `linear_sum_assignment` on `P[group, 0..|group|)`; assign; `P[a, pos] += 1`.  Letter = position (A…Z, AA…AH, as `axis_letters`).
3. **Directions.** Independently of 1–2: per axis a, `Random(f"dir|{seed}|{a}")` permutes the slot list; the first ⌊T/2⌋ are "own", the rest "swapped" (an odd T leaves one extra, by the permutation).  (The Hadamard variant is optional and not planned.)
Output: `{"axes": [...], "slots": [[Q, p], ...], "seed": s, "groups": {slot: [[axis index in position order], ...]}, "swapped": {slot: [bool per axis]}, "digest": sha256 of the above}`.
Invariants a test checks (N = 200, groups 6, T = 500, seed 1; and N = 40, k = 2, T = 60): every axis in exactly one group per slot; group sizes differ by at most 1; per axis the own/swapped counts differ by at most 1; per axis every position count within mean ± 1 for the 6-group case; pair-meeting sd ≤ 2.5 and range within [70, 92]; a second build from the same inputs is byte-identical; build time under 60 s.

### 4.4 Jev: the token model, caps, rerolls, split
- **Token model** (additive, [working_with_jev.md](./working_with_jev.md) § 1 "Limits"): `tokens(request) = F + Σ_answers t(answer) + Σ_axes x(axis) + 20 × Σ_axes y(axis)`, with `t(answer) = len(text) / 4.5`, `x` and `y` the rendered axis-state and question texts at 4.5 characters a token, `F = 374`.  Constants in the Jev tool, recalibrated on the smoke test (step 2 of § 6): least squares of Jev's billed `input_tokens` on the request parts; accept when the model is within 2% on every smoke request, else the fitted constants replace these.
- **Limit**: `LIMIT = 64,000 × 0.98`.
- **Per-question cap** `cap_q`: starting from the global cap (34), the largest `M` such that at most 5% of the question's batches exceed `LIMIT` at `M` axes with the mean axis text; the slot's group count is `ceil(N / cap_q)`.  Acceptance on October: the TODO's figures (95 questions at 34, three at 33, two at 32; 17 batches over the limit before rerolls; 23 swaps) within a few of each.
- **Reroll** (per slot, after the schedule): while a batch B is over `LIMIT` with its largest group: take B's longest answer a; over the slot's other batches in `Random(f"reroll|{seed}|{Q}|{p}")` order, find the shortest answer b with B − a + b and B' − b + a both under `LIMIT`; swap (marked and unmarked keys alike, keeping the distinct-entity invariant: skip a swap that would put an entity twice in a batch).  If none in the slot, try the question's other slots the same way.  Each swap strictly shortens B, so the loop ends.  Count the swaps in the header.
- **Split** (last resort): a request still over `LIMIT` is split by its axes as `split_axes_to_fit` does, every part keeping all 20 answers and its letters; counted in the header (`axis_split_requests`).
- Invariants: after fitting, every request is under `LIMIT` or is a one-axis request; the set of (batch, axis) pairs is unchanged by rerolls and splits; batches keep § 4.2's invariants.
- **Requests and ids**: `s{Q}p{p}|b{i}|g{j}` (`|a0`, `|a1` after a split), plus a 12-hex digest of the batch's keys so a changed batch is never taken for an old answer.

### 4.5 Repeats, cells and merges
- `write_cells` (Jev) and `write_member_cells` (LLM): per item key, average the scores of its unmarked and marked (`~2`) copies, and of both arms on pilot items; then `entity_means`; `_provenance` gains `n_repeats`, `n_padded_from_other_instructions`, `schedule` (`balanced` / `fixed` / `random`, with the digest), `caps` (Jev), `swaps`, and the direction counts per axis as today.
- Per LLM judge the driver merges, per axis, the pilot cells (both arms) and the main cell into one cell `<judge>@rp_<share>_<design>` by item union (averaging items present twice); usage summed; `correlations.json` recomputed.  Implement as `judge_tier_average.merge_cells` (union, not mean of means), next to `average_cells`.

### 4.6 The pilot's ranking
`penalty[a] = mean over the 12 variants of (ρ_stacked[a] − ρ_one[a])` on the pilot items; the worst `round(X × N)` by `penalty` are the judge's worst set.  Recorded with the penalties in `worst_axes_<judge>.tsv`; a resume reads the file rather than recomputing.

### 4.7 What Jev receives
Nothing Jev reads changes in form: the state is still `{"task", "question", "axes": {letter: {"from", "to", "ends": {...}}}, "answers": {"1".."20"}}` and each question is the plain Noul of the `jb61_noul_*` headers ([the m31 header](../../roger/axis_judge_experiments/_tier_eval_jev/jb61_noul_a20m31_s9p0/answers.jsonl)).  What changes is composition: which axes share a state (the schedule's group), their letters (position, not a per-request shuffle), their directions (per slot, not per request), 32–33 axes a request instead of 12 or 31, and batches drawn within a slot.  So no new rendered sample is needed; the dry run prints one request as today.

## 5. Outputs

| Path (under the October experiments dir) | Written by | Holds |
|---|---|---|
| `axes_october.tsv` | driver | the 321 axes, four columns |
| `<axis>/gpt/projections.json` | `axis_judge_correlation.py --projections_only` | October projections, all slots |
| `<axis>_tier_eval/<judge>@<label>/scores_responses.json`, `correlations.json`, `usage.json` | the tools, per run | per-item scores (after repeat averaging), per-entity means, provenance; ρ per slot; the run's usage shared equally over the run's axes |
| `_tier_eval_multi/<group>/<judge>@<label>/` | [judge_tier_cost_eval.py](../../results_analysis/judge_tier_cost_eval.py) | the stacked run's answer log and `schedule.json` |
| `_tier_eval_jev/<label>/answers.jsonl`, `schedule.json`, `usage.json` | Jev tool | the compact log, the schedule with caps, usage |
| `<axis>_tier_eval/<judge>@rp_<share>_<design>/` | driver merge | one cell per judge per axis (pilot + main) |
| `<axis>_tier_eval/<judge>+<judge>...@rp_<share>...` | `judge_tier_average` (later) | the blend, once the mix is decided |

Logging, every run: the schedule's balance statistics at build time (pair-meeting sd and range, position sd, direction counts), per question its cap, the batches over the limit, swaps and splits (Jev), a progress line per slot batch of slots, `warn_if_low_parse_rate` at the end and the `[usage]` line; the driver logs each run's command line, exit status and `usage.json` total.

Labels: `@rp_n20_g{J}p{j}_k{k}w{X}` (LLM; `_pilot1`, `_pilot_one`, `_worst` for the pilot and worst-axes runs), `@rp_noul_a20m34_g{J}p{j}` (Jev); `all` for a whole run.  Jev's compact answer record: `{"kind": "answer", "key": id, "model", "items": [20 keys], "axes": {letter: [axis_dir, swapped]}, "values": {letter: [20 ints 0..100 or null]}, "input_tokens", "output_tokens", "at", "elapsed_s"}` (about 4 KB, 1.1 GB for a full run; gzipped when the cells are written, as the LLM tool does; today's per-key dict form would be about five times that).  The older readers (`load_response_scores`, the weight sweeps, [add-judged-axis](../../.claude/skills/add-judged-axis/SKILL.md)) are not wired, as § 5 of the response plan says; `pair_list_responses.json` is not touched by this build.

## 6. Tests, then live steps

**Unit tests on fakes, no network** (the `world` fixture and `_script` loader of [test_judge_tier_cost_eval.py](../../results_analysis/tests/test_judge_tier_cost_eval.py); the schedule's own file [`test_response_schedule.py`](../../assistant_axis/tests/test_response_schedule.py), not yet written):
1. Slot batching: § 4.2's invariants on a fake tree of 7 entities × 2 questions × 5 instructions; the `~2` keys; the cross-instruction pad when a slot has 12; the ≥ 30 error with its message.
2. Schedule: § 4.3's invariants at both sizes; byte-identical rebuild; load/save round trip; refusal of a stored schedule whose axes or slots differ.
3. Jev fitting on synthetic lengths: a per-question cap that lowers for a wordy question; a reroll that fixes an over-limit batch by one swap, the multiset of answers unchanged; a split only when no swap exists; every request under the limit.
4. Jev end to end with `FakeJevRelative`: every kept item scored exactly once per share (repeats aside), repeats averaged, directions mapped back, cells written, `usage.json` written; a second run asks nothing; the `jb61` form (`--schedule fixed`) reproduces the existing header digest of a jb61 log and resumes it with zero requests (fixture: a two-line copy of a real log's header).
5. LLM tool with the existing fake clients: `--batch_by slot --schedule balanced` on `rk_pn --stack 2` and on `r1_pn --stack 1`: groups and directions from the schedule, every item once per run, the member cells' direction counts balanced, the batch transport's rebuilt groups equal to the live path's; old cells and logs (no schedule key) still resume.
6. Driver: the 321-axis list from the real [data/](../../data/) (count, the five squares, the eight MBTI antipodes, no pole twice); labels; the pilot ranking on synthetic ρ; the merge; `--dry_run` cost lines; the share flags passed through.
7. Usage: every run writes `usage.json`; a Jev record's cost at `price_for_model("jev-1.14.0")`.

**Live steps**, in order, each under $20 and in real time unless said (October axes need the projections first; the Jev grouping test uses the May ninth and its existing projections):

| Step | What | Cost | Needs Roger's go |
|---|---|---:|---|
| L1 | Jev grouping test on the May ninth, 61 axes, `--response_design question` part 0 of 9 as the `jb61` cells: B = balanced schedule + slot batches at cap 31 (two groups a slot, to match [jb61_noul_a20m31_s9p0](../../roger/axis_judge_experiments/_tier_eval_jev/jb61_noul_a20m31_s9p0/usage.json), $5.69); optional C = slot batches with fixed grouping, to separate the two changes | $6 (B), $12 with C | no (under $20) |
| L2 | Smoke on October: six axes, share 1/27, all four judges, both LLM arms; checks the token model (§ 4.4), padding, the explicit Gemini cache, the cells, the logs | about $8 in all (Jev $0.75, Luna $3, Haiku $1.5, Gemini $2.5) | no |
| L3 | Each LLM judge's pilot on its share (§ 3.5) | per judge, all responses: Luna $93, Haiku $77, Gemini $123; a third share: a third of each | yes, as part of the full run |
| L4 | A full run of a judge on its share | § 7 | yes, parameters listed |

L1's reading: the mean ρ over the 61 axes should not move (within the ninth's noise, about ± 0.003) and the per-axis differences between B and the m31 cell should be smaller than between the m12 and m31 cells (the grouping effect's sd 0.006).  The May corpus for L1 is the pinned `instructions_dir` the jb61 runs used (`/tmp/claude-501/corpus_2026-05-24/data`; if gone, check out commit `1448a84c`'s `data/` into the scratchpad).

## 7. Cost and time, 321 axes

Unit costs measured on the May ninth ([judge_response_pareto_61.json](../../roger/axis_judge_experiments/response_pareto/judge_response_pareto_61.json) `unit_costs`, USD per million response-axes; October lengths add 3.4% Luna, 4.2% Haiku, 3.3% Gemini, 1.7% Jev).  Response-axes a full run: 541,109 × 321 = 173.7 M.

| Judge | One axis a call | Stacked | Full run, every response | A third share | Calls or requests | Time |
|---|---:|---:|---:|---:|---:|---|
| Jev (10 groups of 32–33; by the token model: 27,281 batches × 10 × about 52k tokens = 14.2 G) | | | **about $600** | $200 | 273,000 requests | 10–13 h at the measured 300–400k tokens/s, 24 in flight; the org's rate limit is unread (console) |
| Luna, k=4, worst 20% | 10.17 | 4.13 (+ 46.95 per M responses once) | **about $985** | $330 | 3.5 M calls | about 11 calls/s on Flex in the 61-axis runs: days; `--transport batch` for a full run |
| Haiku, k=2, worst 10% | 7.61 | 4.29 | **about $835** | $280 | 4.8 M requests in 10,000-request batches | 1–2 days of batches |
| Gemini, k=6, worst 20% | 13.93 | about 5.15 (from § 4e's $747 at 200) | **about $1,240** | $410 | 2.9 M requests, a cache per batch | 1–2 days |

Pilots (§ 3.5, 1/27 both ways; the extra over production is the arm not kept, about 80% of the one-axis arm): Luna +$57, Haiku +$47, Gemini +$79 on every response; a third of each on a third share.  Jev's bill is three quarters question text (61 tokens per answer-axis), so a shorter wording would cut it by about a third; that is a quality experiment, not a setting (§ 9).

## 8. Build order (each step with its tests; an Opus agent's checklist)

1. [`assistant_axis/response_schedule.py`](../../assistant_axis/response_schedule.py) (new): slots, batches with padding, the schedule, JSON load/save, `pad_key` / `real_key`.  Tests 1–2.
2. [judge_responses_jev.py](../../scripts/judge_responses_jev.py): `--schedule balanced|fixed`, the token model and `fit_requests` (caps, rerolls, split), the compact log and its reader (the old record form still read), repeat averaging in `write_cells`, header keys added only under `balanced`.  Tests 3–4.
3. L1 on the May ninth; readout as a short section appended to [working_with_jev.md](./working_with_jev.md) § 4 by the agent, with the numbers.
4. [judge_tier_cost_eval.py](../../results_analysis/judge_tier_cost_eval.py): `--batch_by slot` in `item_groups`, `--schedule balanced` in `stack_plan` / `stack_slots` / `axis_groups` (the group count per batch from the schedule), `CHECKPOINT_DEFAULTS` for the new keys, repeat averaging in `write_member_cells`, `schedule.json` beside the group's log.  Test 5.
5. [judge_tier_average.py](../../results_analysis/judge_tier_average.py) `merge_cells`.  Test 6 (merge part).
6. [`results_analysis/judge_responses.py`](../../results_analysis/judge_responses.py) (new): constants, the axis list, labels, the pilot and ranking, the runs, the merge, `--dry_run`.  Test 6.
7. Projections for October: time one axis; add the multi-axis `--projections_only` if needed; write all 321.
8. L2, then the report to Roger with L3/L4 parameters for his go.
9. README rows: [results_analysis/README.md](../../results_analysis/README.md) (the driver, as the description and instruction methods have), and the AGENT_NOTES TODO closed with a pointer here.

## 9. Open questions for Roger, with recommendations

1. **Squares' diagonals: corpus or table?**  Recommend recording `axes` on the five squares (a 20-file data change, your go), the table as a stopgap that warns.
2. **Pilot size for the worst axes: 1/27 or 1/81?**  Recommend 1/27 (about 18 slots; the ranking noise at 1/81's 6 slots is near the penalty spread near the cut).  Per judge.  Alternative: Luna's May ranking for the 50-odd axes it covers and the pilot only for the rest; not recommended (two rules).
3. **The ≥ 30 rule's reading.**  Taken as: the slot's own responses plus the same question's other instructions available to the run, checked for every slot.  Confirm, or say it applies only when a slot is under 20.
4. **Pads from outside the share.**  Taken as: only from the run's own items (so every score is for an item this run judges).  Confirm.
5. **Jev at 32–33 axes a request** is above the tested 31.  Recommend accepting (the cost difference to 31 is 1.6%); L1 at cap 31 keeps the comparison clean.  If you want 34 vs 31 measured, a second L1 cell at the production cap costs $6.
6. **Jev's question wording** is three quarters of its bill; a shorter wording (about a third off) needs its own quality test on the ninth (about $6 a wording).  Not in this build; list it or drop it.
7. **Gemini's parameters** (format, 20/40) stay parameters with defaults plain and 20 until the recheck lands; the driver constants are changed then.
8. **Where the October cells live**: `roger/axis_judge_experiments_october/`.  Confirm the name.
9. **The mix and the weights**: the driver runs a judge on a share, and `TIER_JUDGE_WEIGHTS_BY_MODE["responses"]` needs an entry before any blend.  **Decided 2026-11-07 (Roger): the default and subset modes are a Haiku + Gemini + Jev golden split, the high and maximal modes all four**, for now, to be revisited on the October data ([AGENT_NOTES.md](../../AGENT_NOTES.md), "TODO: revisit the response-judging mix on the October data"); the weights within a blend stay the table's (Luna 4, the others 3) until the October dumps allow a sweep.  Haiku's settled design is labelled (`rk_pl`), k=4, worst 15% since the same evening ([response_judging_plan.md](./response_judging_plan.md) § 4e).
10. **Jev's in-flight count**: read the org's rate limit in TypeSafe's console and allow `--max_in_flight 48–64` if it permits; the full run is 10+ hours at 24.
11. **Full-run transports for Luna**: Flex at the observed rate is days; recommend `--transport batch` for a full Luna run (same price), Flex for the share tests.

## 10. Problems seen in decided items

- **The brief's Jev cost ($40–45 a full run) was a ninth's cost**; the token model gives about $600 at 321 axes (about $370 at 200), consistent with § 4e's $370 and the measured $5.69 for 135 M tokens.  Every Jev run over the smoke test needs your go.
- **"20 answers from different entities, all their p-th instruction"** is broken only by the cross-instruction pad of a slot under 20, which never happens on October (the smallest slot has 678); it matters in tests and on small shares.
- **The LLM judges' full runs are long** (millions of calls) whichever transport; the mix decision should weigh wall time as well as price.
