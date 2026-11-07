#!/bin/zsh
# Gemini 3.1 Flash-Lite, the stacking step on the ninth (Roger, 2026-11-05: "Use 1/9 here too", approved at about $87):
# (1) one axis a call at 20 answers on part 18, finishing the 32 axes the credit stopped (a finished axis resumes at no
# cost), so that the left-out axes have one-axis scores on the whole ninth; (2) plain stacking (rk_pn) at k = 2, 4, 6,
# 20 answers a call, all 61 axes, on parts 0, 9 and 18 of split 27 (together the ninth), each batch's 61 axes regrouped
# at random (seed 1).  Flex, implicit cache: the request layout of every Gemini run so far.  Caps 300 + 150 k.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
M=gemini-3.1-flash-lite
B=(--judge_model $M --transport flex --axes_per_call 61 --shuffle_seed 1 --axes_file scripts/tier_eval_axes.tsv
   --instructions_dir /tmp/claude-501/corpus_2026-05-24/data --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot"
   --response_split 27 --response_design question --max_in_flight 40 --entities_per_call 20)
one() {   # axis
  local label=@r1_pnn20_s27p18g61_a$1c
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${B[@]}" --rubric r1_pn --directions responses --response_part 18 \
      --max_tokens 300 --cell_label $label --axis_index $1 --budget_usd 1.0 >> "$L/$M$label.log" 2>&1
  echo "    exit $? $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1)"
}
stack() {  # part, k
  local label=@rk_pnn20_s27p$1g61_k$2
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${B[@]}" --rubric rk_pn --stack $2 --response_part $1 \
      --max_tokens $(( 300 + 150 * $2 )) --cell_label $label --budget_usd 20 >> "$L/$M$label.log" 2>&1
  echo "    exit $? $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1)"
}
R=({0..60})
( for i in ${R[1,21]}; do one $i; done ) &
( for i in ${R[22,41]}; do one $i; done ) &
( for i in ${R[42,61]}; do one $i; done ) &
wait
for part in 0 9 18; do
  stack $part 2 & stack $part 4 & stack $part 6 &
  wait
done
echo "=== done $(date -u +%FT%TZ)"
