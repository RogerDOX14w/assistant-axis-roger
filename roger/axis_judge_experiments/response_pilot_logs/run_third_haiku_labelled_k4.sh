#!/bin/zsh
# Haiku 5.5's third at its official design (Roger, 2026-11-07: "Confirmed, Haiku is labelled. At labeled, it's k=4";
# "the official rate is 15%"): the labelled format (rk_pl) stacked 4 axes a call on parts 3 and 6 of split 9 (cut by
# question), the two cells haiku3 lacks at that design (its part 0 is the ninth's @rk_pln20_s9p0g61_k4; the one-axis
# cells of parts 3 and 6 exist, so the worst 15% composes from them).  By Message Batches, as run_third_haiku_k4.sh
# (the plain k=4 twins, in the queue since 14:25 UTC), not live: live Haiku reads the cache half as often and costs
# about 3.5x batch.  20 answers a call, seed 1, max_tokens 300 + 200 k = 1100 (run_stack61_haiku_formats.sh).  About
# $5 a cell (the labelled k=4 ninth cell cost $5.27 for 22,808 calls); each capped at $12.
set -u
L=roger/axis_judge_experiments/response_pilot_logs
D=(--axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_design question --shuffle_seed 1
   --entities_per_call 20 --axes_per_call 61)
H=(--judge_model claude-haiku-5-5 --transport batch --batch_poll_seconds 60)
run() {  # model label flags...
  local model=$1 label=$2; shift 2
  echo "=== $model $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "$@" --cell_label $label >> "$L/$model$label.log" 2>&1
  echo "    exit $? $model $label $(grep -A1 '^Summary:' "$L/$model$label.log" | tail -1 | cut -c1-160)"
}
for part in 3 6; do
  ( run claude-haiku-5-5 @rk_pln20_s9p${part}g61_k4 "${D[@]}" "${H[@]}" --response_split 9 --response_part $part \
        --rubric rk_pl --stack 4 --max_tokens 1100 --budget_usd 12 ) &
done
wait
echo "=== done $(date -u +%FT%TZ)"
