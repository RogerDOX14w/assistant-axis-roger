#!/bin/zsh
# Haiku 5.5 and Jev 1.14 from the ninth to the third (parts 3 and 6 of split 9, cut by question, as Luna's third in
# run_luna_third.sh), each at its settled design: Haiku one axis a call (r1_pn, --stack 1) and plain stacking k=2 by
# Message Batches, with the settings of its ninth cells (@..._s9p0g61_st1 / _k2: max_tokens 300 / 600); Jev yes/no at
# 20 answers x 30-31 axes a request, as jb61_noul_a20m31_s9p0.  And the six-axis anchor (scripts/tier_eval_axes_full6.tsv,
# every kept response: no --response_part) for Luna (Flex, max_tokens 300 / 680 as run_luna_third.sh), Haiku and Jev
# (6 axes a request) at their settled designs.  Gemini's third and anchor follow in run_third_gemini_anchor6.sh once its
# format recheck ends.  Roger, 2026-11-06: "OK, make it so, with your proposed optional extra".  Estimated from the
# ninth's measured cells: Haiku third $40, Jev third $11, anchors Luna $23, Haiku $18, Jev $9 (about $100); each run
# capped by --budget_usd at about 1.5x its estimate.
set -u
L=roger/axis_judge_experiments/response_pilot_logs
D=(--axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_design question --shuffle_seed 1
   --entities_per_call 20 --axes_per_call 61)
A6=(--axes_file scripts/tier_eval_axes_full6.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
    --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_design question --shuffle_seed 1
    --entities_per_call 20 --axes_per_call 6)
H=(--judge_model claude-haiku-5-5 --transport batch --batch_poll_seconds 60)
LU=(--judge_model gpt-5.6-luna --transport flex --max_in_flight 50)
run() {  # model label flags...
  local model=$1 label=$2; shift 2
  echo "=== $model $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "$@" --cell_label $label >> "$L/$model$label.log" 2>&1
  echo "    exit $? $model $label $(grep -A1 '^Summary:' "$L/$model$label.log" | tail -1 | cut -c1-160)"
}
jev() {  # label flags...
  local label=$1; shift
  echo "=== jev-1.14.0 $label $(date -u +%FT%TZ)"
  .venv/bin/python scripts/judge_responses_jev.py --instructions_dir /tmp/claude-501/corpus_2026-05-24/data \
      --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_design question --design relative \
      --batch_question noul --shuffle_seed 1 --max_in_flight 24 --answers_per_request 20 "$@" --cell_label $label \
      >> "$L/jev-1.14.0$label.log" 2>&1
  echo "    exit $? jev-1.14.0 $label $(tail -1 "$L/jev-1.14.0$label.log" | cut -c1-160)"
}
# Haiku's third: four batch runs at once
for part in 3 6; do
  ( run claude-haiku-5-5 @r1_pnn20_s9p${part}g61_st1 "${D[@]}" "${H[@]}" --response_split 9 --response_part $part \
        --rubric r1_pn --stack 1 --max_tokens 300 --budget_usd 20 ) &
  ( run claude-haiku-5-5 @rk_pnn20_s9p${part}g61_k2 "${D[@]}" "${H[@]}" --response_split 9 --response_part $part \
        --rubric rk_pn --stack 2 --max_tokens 600 --budget_usd 12 ) &
done
# Jev's third one part at a time (its rate limit is unread), then its anchor
( jev @jb61_noul_a20m31_s9p3 --axes_file scripts/tier_eval_axes.tsv --response_split 9 --response_part 3 --axes_per_request 31 --budget_usd 10
  jev @jb61_noul_a20m31_s9p6 --axes_file scripts/tier_eval_axes.tsv --response_split 9 --response_part 6 --axes_per_request 31 --budget_usd 10
  jev @jb6_noul_a20m6_all --axes_file scripts/tier_eval_axes_full6.tsv --axes_per_request 6 --budget_usd 15 ) &
# The six-axis anchor, every kept response: Luna by Flex, Haiku by batch
( run gpt-5.6-luna @r1_pnn20_allg6_st1 "${A6[@]}" "${LU[@]}" --rubric r1_pn --stack 1 --max_tokens 300 --budget_usd 25 ) &
( run gpt-5.6-luna @rk_pnn20_allg6_k4 "${A6[@]}" "${LU[@]}" --rubric rk_pn --stack 4 --max_tokens 680 --budget_usd 12 ) &
( run claude-haiku-5-5 @r1_pnn20_allg6_st1 "${A6[@]}" "${H[@]}" --rubric r1_pn --stack 1 --max_tokens 300 --budget_usd 18 ) &
( run claude-haiku-5-5 @rk_pnn20_allg6_k2 "${A6[@]}" "${H[@]}" --rubric rk_pn --stack 2 --max_tokens 600 --budget_usd 10 ) &
wait
echo "=== done $(date -u +%FT%TZ)"
