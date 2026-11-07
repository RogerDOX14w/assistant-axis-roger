#!/bin/zsh
# Jev yes/no (noul), the rest of the answers x axes grid on the 61 axes (Roger, 2026-11-05: "Run it, except for 1, do a
# 1/27 rather than 1/9, see how different it is, and then we can discuss whether it's worth pushing it to 1/9"):
# 40 x 6 on the ninth (split 9, part 0); 20 x 1 and 40 x 1 on 1/27 (split 27, part 0, a third of the ninth, so the
# other cells can be cut to the same responses).  Seed 1, 24 in flight.  About $35.  Waits for run_jev_noul_shapes61.sh.
set -u
L=roger/axis_judge_experiments/response_pilot_logs
until grep -q "^=== done" $L/run_jev_noul_shapes61.out 2>/dev/null; do sleep 30; done
C=(--axes_file scripts/tier_eval_axes.tsv --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot"
   --response_design question --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --design relative --batch_question noul --shuffle_seed 1 --max_in_flight 24)
run() {   # answers, axes, split, label share
  local label=@jb61_noul_a$1m$2_s$3p0
  echo "=== $label $(date -u +%FT%TZ)"
  uv run python scripts/judge_responses_jev.py "${C[@]}" --answers_per_request $1 --axes_per_request $2 --response_split $3 \
      --response_part 0 --cell_label $label --budget_usd 20 > $L/$label.log 2>&1
  echo "    exit $? $(grep -E 'usage' $L/$label.log | tail -1 | cut -c1-200)"
}
run 40 6 9
run 20 1 27
run 40 1 27
echo "=== done $(date -u +%FT%TZ)"
