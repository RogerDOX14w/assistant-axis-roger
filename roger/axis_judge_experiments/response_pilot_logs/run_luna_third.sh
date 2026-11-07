#!/bin/zsh
# Luna's settled design measured at a third, to check the extrapolation (Roger, 2026-11-05: "take whichever is the
# cheaper of Luna or Gemini from 1/9 to 1/3, and compare the actual result to the extrapolation"; option A, about $48).
# A third is the ninth (split 9 part 0) plus parts 3 and 6 of split 9 (by question, as the ninth).  On each new part:
# plain stacking k=4 (rk_pn) on all 61 axes, and one axis a call (r1_pn, --stack 1: each batch's 61 calls in turn, the
# prefix cached) on all 61 axes, so the worst 20% can be re-chosen by cross-fitting on the third's own data.  Flex, 20
# answers a call, seed 1, each call's direction a coin; caps as Luna's runs on the ninth.
set -u
L=roger/axis_judge_experiments/response_pilot_logs
C=(--judge_model gpt-5.6-luna --transport flex --axes_per_call 61 --entities_per_call 20 --shuffle_seed 1
   --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 9 --response_design question
   --max_in_flight 50)
run() {   # label, args...
  local label=$1; shift
  echo "=== $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --cell_label $label "$@" >> $L/$label.log 2>&1
  echo "    exit $? $(grep -A1 '^Summary:' $L/$label.log | tail -1)"
}
( run @rk_pnn20_s9p3g61_k4 --response_part 3 --rubric rk_pn --stack 4 --max_tokens 680 --budget_usd 12 ) &
( run @rk_pnn20_s9p6g61_k4 --response_part 6 --rubric rk_pn --stack 4 --max_tokens 680 --budget_usd 12 ) &
( run @r1_pnn20_s9p3g61_st1 --response_part 3 --rubric r1_pn --stack 1 --max_tokens 300 --budget_usd 25 ) &
( run @r1_pnn20_s9p6g61_st1 --response_part 6 --rubric r1_pn --stack 1 --max_tokens 300 --budget_usd 25 ) &
wait
echo "=== done $(date -u +%FT%TZ)"
