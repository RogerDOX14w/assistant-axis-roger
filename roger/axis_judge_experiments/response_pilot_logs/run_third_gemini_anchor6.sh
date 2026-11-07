#!/bin/zsh
# Gemini 3.1 Flash-Lite from the ninth to the third (parts 3 and 6 of split 9, cut by question; its ninth cells are
# parts 0, 9 and 18 of split 27, the same ninth), at its settled design: one axis a call (r1_pn, --stack 1, label
# suffix e as the explicit-cache cells) and plain stacking k=6, Flex with explicit caches, max_tokens 300 / 1200 as the
# ninth's cells; and the six-axis anchor (scripts/tier_eval_axes_full6.tsv, every kept response).  Roger, 2026-11-06:
# "OK, make it so, with your proposed optional extra".  Estimated from the measured explicit-cache cells: third $75
# (one axis a call 3 x $8.44 a ninth, k=6 about $12.4 a ninth), anchor $33; caps at about 1.5x.
# RUNS AFTER run_stack61_gemini_formats.sh ENDS (the format and 40-answer rechecks may change the settled design);
# two runs at a time at 40 in flight, as that script.
set -u
L=roger/axis_judge_experiments/response_pilot_logs
M=gemini-3.1-flash-lite
G=(--judge_model $M --transport flex --gemini_cache explicit --max_in_flight 40 --shuffle_seed 1 --entities_per_call 20
   --instructions_dir /tmp/claude-501/corpus_2026-05-24/data --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot"
   --response_design question)
run() {  # label flags...
  local label=$1; shift
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${G[@]}" "$@" --cell_label $label >> "$L/$M$label.log" 2>&1
  echo "    exit $? $label $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1 | cut -c1-160)"
}
( run @r1_pnn20_s9p3g61_st1e --axes_file scripts/tier_eval_axes.tsv --axes_per_call 61 --response_split 9 --response_part 3 --rubric r1_pn --stack 1 --max_tokens 300 --budget_usd 38
  run @r1_pnn20_s9p6g61_st1e --axes_file scripts/tier_eval_axes.tsv --axes_per_call 61 --response_split 9 --response_part 6 --rubric r1_pn --stack 1 --max_tokens 300 --budget_usd 38 ) &
( run @rk_pnn20_s9p3g61_k6 --axes_file scripts/tier_eval_axes.tsv --axes_per_call 61 --response_split 9 --response_part 3 --rubric rk_pn --stack 6 --max_tokens 1200 --budget_usd 20
  run @rk_pnn20_s9p6g61_k6 --axes_file scripts/tier_eval_axes.tsv --axes_per_call 61 --response_split 9 --response_part 6 --rubric rk_pn --stack 6 --max_tokens 1200 --budget_usd 20 ) &
wait
echo "=== done third $(date -u +%FT%TZ)"
# The six-axis anchor is NOT in this chain (2026-11-06 18:50 UTC): with 6 axes a batch instead of 61 each cached prefix is
# read 6 times (one axis a call) or once (k=6) instead of 61 or 10, so the explicit caches amortise badly; Haiku's k=2 anchor
# cost $15 against a $6 estimate for that reason.  Estimated about $55 (one axis a call about $42, k=6 without a cache about
# $12), against the $33 quoted; it waits for Roger's word.  To run it: zsh with ANCHOR=1.
if [ "${ANCHOR:-0}" = 1 ]; then
  ( run @r1_pnn20_allg6_st1e --axes_file scripts/tier_eval_axes_full6.tsv --axes_per_call 6 --rubric r1_pn --stack 1 --max_tokens 300 --budget_usd 55 ) &
  ( .venv/bin/python results_analysis/judge_tier_cost_eval.py "${G[@]}" --gemini_cache implicit --axes_file scripts/tier_eval_axes_full6.tsv \
        --axes_per_call 6 --rubric rk_pn --stack 6 --max_tokens 1200 --budget_usd 20 --cell_label @rk_pnn20_allg6_k6 \
        >> "$L/$M@rk_pnn20_allg6_k6.log" 2>&1; echo "    exit $? @rk_pnn20_allg6_k6" ) &
  wait
  echo "=== done anchor $(date -u +%FT%TZ)"
fi
