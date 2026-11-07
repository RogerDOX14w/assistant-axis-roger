#!/bin/zsh
# Jev's plain yes/no question (noul, the winner of run_jev_batch_questions61.sh) at other shapes, and with a style-aware
# task (Roger, 2026-11-05: "Yes" to 40 x 12, 20 x 6 and the style wording, about $26).  The 61 axes, the ninth cut by
# question, seed 1, as there.  Next, unless 12 axes a request proves clearly worse than 6: 24 axes a request.
set -u
L=roger/axis_judge_experiments/response_pilot_logs
C=(--axes_file scripts/tier_eval_axes.tsv --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot"
   --response_split 9 --response_part 0 --response_design question --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --design relative --shuffle_seed 1 --max_in_flight 24)
run() {   # question, answers, axes
  local label=@jb61_$1_a$2m$3_s9p0
  echo "=== $label $(date -u +%FT%TZ)"
  uv run python scripts/judge_responses_jev.py "${C[@]}" --batch_question $1 --answers_per_request $2 --axes_per_request $3 \
      --cell_label $label --budget_usd 15 > $L/$label.log 2>&1
  echo "    exit $? $(grep -E 'usage' $L/$label.log | tail -1 | cut -c1-200)"
}
run noul 40 12
run noul 20 6
run noul_style 20 12
echo "=== done $(date -u +%FT%TZ)"
