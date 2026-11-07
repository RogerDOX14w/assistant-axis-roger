#!/bin/zsh
# Gemini 3.1 Flash-Lite, the formats at its settled stacking (Roger, 2026-11-06: "Gemini: K=6", 20% left out): labelled
# (rk_pl) and axis by axis (rk_pa) at k=6, 20 answers a call, all 61 axes, on parts 0, 9 and 18 of split 27 (together the
# ninth), each batch's 61 axes regrouped at random (seed 1), as the plain cells @rk_pnn20_s27p{0,9,18}g61_k6.  The left-out
# 20% come from the one-axis cells already judged.  Flex with explicit caches: the explicit-cache check of 2026-11-06 gave
# the same quality as the implicit cache (rho -0.0002 [-0.0017, +0.0013] over 61 axes) at 43% of the cost (94% of the
# input read from the cache against 53%).  Estimated about $30; caps $10 a run.  Approved by Roger, 2026-11-06 ("approved").
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
M=gemini-3.1-flash-lite
B=(--judge_model $M --transport flex --gemini_cache explicit --axes_per_call 61 --shuffle_seed 1 --axes_file scripts/tier_eval_axes.tsv
   --instructions_dir /tmp/claude-501/corpus_2026-05-24/data --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot"
   --response_split 27 --response_design question --max_in_flight 40 --entities_per_call 20)
run() {  # format, part
  local label=@$1n20_s27p$2g61_k6
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${B[@]}" --rubric $1 --stack 6 --response_part $2 \
      --max_tokens 1500 --cell_label $label --budget_usd 10 >> "$L/$M$label.log" 2>&1
  echo "    exit $? $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1)"
}
for part in 0 9 18; do
  run rk_pl $part & run rk_pa $part &
  wait
done
echo "=== done $(date -u +%FT%TZ)"
# And the recheck of 40 answers at the settled stacking (Roger, 2026-11-05: "we'll recheck 40 at the end"): plain, k=6, 40
# answers a call on parts 0, 9 and 18; and part 18's one-axis cells at 40 answers, for the left-out axes (parts 0 and 9
# have them), as one --stack 1 run.  Explicit caches as above; estimated about $20.
run40() {  # part
  local label=@rk_pnn40_s27p$1g61_k6
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${B[@]}" --rubric rk_pn \
      --stack 6 --response_part $1 --entities_per_call 40 --max_tokens 3600 --cell_label $label --budget_usd 10 >> "$L/$M$label.log" 2>&1
  echo "    exit $? $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1)"
}
one40() {
  local label=@r1_pnn40_s27p18g61_st1e
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${B[@]}" --rubric r1_pn --stack 1 --response_part 18 \
      --entities_per_call 40 --max_tokens 600 --cell_label $label --budget_usd 15 >> "$L/$M$label.log" 2>&1
  echo "    exit $? $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1)"
}
one40 & run40 0 & run40 9 &
wait
run40 18
echo "=== done 40 $(date -u +%FT%TZ)"
