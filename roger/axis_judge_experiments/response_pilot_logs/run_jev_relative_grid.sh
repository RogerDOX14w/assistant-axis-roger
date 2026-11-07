#!/bin/zsh
# Jev's relative design, completing the grid of answers a request x axes a request on the twelve axes (Roger,
# 2026-11-05: "Jev, add 20 answers x 6 axes and 40 x 12 and 20 x 1"; beside 20x12, 40x6, 40x1 of run_jev_relative.sh).
# Settings as there.  40 x 12: the 6 of 737 batches whose request would pass Jev's 64k-token limit are asked in two
# halves of 20, each with the 12 axes (judge_responses_jev.py, the header's halved_requests).  About $12.  Run from the root.
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
run @jrel_a40m12_s9p0 --answers_per_request 40 --axes_per_request 12 --budget_usd 4
run @jrel_a20m6_s9p0 --answers_per_request 20 --axes_per_request 6 --budget_usd 5
run @jrel_a20m1_s9p0 --answers_per_request 20 --axes_per_request 1 --budget_usd 14
echo "=== done $(date -u +%FT%TZ)"
