#!/bin/zsh
# Jev, the question asked per answer and axis (Roger, 2026-11-05: "we need to test relative vs absolute ... let's
# experiment a bit and see what works best"; "let's do all this at 61 axes level, this work is cheap"): the 61 axes,
# 20 answers x up to 12 axes a request (six even chunks of 10-11 axes), the ninth cut by question, seed 1, so every arm
# asks about the same batches; only --batch_question differs: relative (yes/no against the others), noul (yes/no
# between the ends), score5, choice11, relative_score5.  About $45 (dry runs).  Run from the root.
set -u
L=roger/axis_judge_experiments/response_pilot_logs
C=(--axes_file scripts/tier_eval_axes.tsv --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot"
   --response_split 9 --response_part 0 --response_design question --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --design relative --shuffle_seed 1 --answers_per_request 20 --axes_per_request 12 --max_in_flight 24)
run() {
  local q=$1 label=@jb61_$1_a20m12_s9p0
  echo "=== $label $(date -u +%FT%TZ)"
  uv run python scripts/judge_responses_jev.py "${C[@]}" --batch_question $q --cell_label $label --budget_usd 15 > $L/$label.log 2>&1
  echo "    exit $? $(grep -E 'usage' $L/$label.log | tail -1 | cut -c1-200)"
}
for q in relative noul score5 relative_score5 choice11; do run $q; done
echo "=== done $(date -u +%FT%TZ)"
