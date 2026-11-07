#!/bin/zsh
# Jev on responses with its relative yes/no question (Roger, 2026-11-04: "see if you can get the same working for
# response judging"; approved, about $12): the twelve axes, the ninth cut by question as the Luna cells, seed 1, a
# batch of answers to one question and some axes a request, one Noul per answer and axis, each axis's direction a
# coin per request, the axes' order shuffled per request.  B20: 20 answers (Luna's batches) x all 12 axes; B40: 40
# answers x 6 axes (12 would pass Jev's 64k-token limit on the longest batches); A40: 40 answers x 1 axis, so that
# A40 against B40 isolates sharing a state between axes.  Run from the root.
set -u
L=roger/axis_judge_experiments/response_pilot_logs
C=(--axes_file scripts/tier_eval_axes_responses12.tsv --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot"
   --response_split 9 --response_part 0 --response_design question --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --design relative --shuffle_seed 1 --max_in_flight 24)
run() {
  local label=$1; shift
  echo "=== $label $(date -u +%FT%TZ)"
  uv run python scripts/judge_responses_jev.py "${C[@]}" --cell_label $label "$@" > $L/$label.log 2>&1
  echo "    exit $? $(grep -E 'usage|rho=' $L/$label.log | tail -1 | cut -c1-200)"
}
run @jrel_a20m12_s9p0 --answers_per_request 20 --axes_per_request 12 --budget_usd 4
run @jrel_a40m6_s9p0 --answers_per_request 40 --axes_per_request 6 --budget_usd 5
run @jrel_a40m1_s9p0 --answers_per_request 40 --axes_per_request 1 --budget_usd 12
echo "=== done $(date -u +%FT%TZ)"
