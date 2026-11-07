#!/bin/zsh
# Haiku 5.5's third at its settled design (Roger, 2026-11-07: "Haiku should be k=4, 25% -- which is a change"; "Add the
# extra $10-or so you suggested"): plain stacking at k=4 on parts 3 and 6 of split 9 (cut by question), the two cells
# haiku3 lacks at k=4 (its part 0 is the ninth's @rk_pnn20_s9p0g61_k4; the one-axis-a-call cells of parts 3 and 6
# exist, so the worst 25% composes from them).  Everything as the k=2 cells of run_third_haiku_jev_anchor6.sh
# (Message Batches, 20 answers a call, seed 1) at --stack 4; max_tokens 900 = 300 + 150 k, where the ninth's k=4 cell
# used 680 and the third's k=2 cells 600 (the cap only cuts rare long replies, which are then scored as missing).
# About $5 a cell from the ninth's k=4 cell ($4.99 for 22,805 calls); each run capped at $12.
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
  ( run claude-haiku-5-5 @rk_pnn20_s9p${part}g61_k4 "${D[@]}" "${H[@]}" --response_split 9 --response_part $part \
        --rubric rk_pn --stack 4 --max_tokens 900 --budget_usd 12 ) &
done
wait
echo "=== done $(date -u +%FT%TZ)"
