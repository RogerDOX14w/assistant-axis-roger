#!/bin/zsh
# Finish Gemini's 40-answer arm on the 61 axes: the 17 axes the prepaid credit stopped on 2026-11-05 05:16 UTC
# (Roger, same day: "Gemini still has some credit").  Settings exactly as run_answers_hg61.sh gemini (real time,
# about $0.42 an axis, about $7); a partly judged axis resumes.  Run from the root.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
M=gemini-3.1-flash-lite
C=(--judge_model $M --transport realtime --rubric r1_pn --directions responses --axes_per_call 61 --shuffle_seed 1
   --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 27 --response_part 0
   --response_design question --max_in_flight 40 --max_tokens 600)
run() {
  local label=@r1_pnn40_s27p0g61_a$1c
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --entities_per_call 40 --cell_label $label \
      --axis_index $1 --budget_usd 1.5 >> "$L/$M$label.log" 2>&1
  echo "    exit $? $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1)"
}
run 19
( for i in 20 21 22 24 18; do run $i; done ) &
( for i in 42 43 44 45 46; do run $i; done ) &
( for i in 47 48 49 50 52 53; do run $i; done ) &
wait
echo "=== done $(date -u +%FT%TZ)"
