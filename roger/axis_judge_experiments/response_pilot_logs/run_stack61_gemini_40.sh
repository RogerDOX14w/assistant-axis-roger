#!/bin/zsh
# The 40-answer recheck of run_stack61_gemini_formats.sh on its own, relaunched after the disk filled on 2026-11-06 at
# about 17:30 UTC (that script's formats stage had finished; this stage's one-axis run had 32,420 answers in and
# resumes from its answer log, its three stacked runs had not started).  Settings as that script: Flex with explicit
# caches, plain k=6 at 40 answers a call on parts 0, 9 and 18 of split 27, and part 18's one-axis cells at 40 answers
# (--stack 1) for the left-out axes (parts 0 and 9 have them).  Estimated about $20; caps below.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
M=gemini-3.1-flash-lite
B=(--judge_model $M --transport flex --gemini_cache explicit --axes_per_call 61 --shuffle_seed 1 --axes_file scripts/tier_eval_axes.tsv
   --instructions_dir /tmp/claude-501/corpus_2026-05-24/data --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot"
   --response_split 27 --response_design question --max_in_flight 40)
run40() {  # part
  local label=@rk_pnn40_s27p$1g61_k6
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${B[@]}" --rubric rk_pn --stack 6 --response_part $1 \
      --entities_per_call 40 --max_tokens 3600 --cell_label $label --budget_usd 10 >> "$L/$M$label.log" 2>&1
  echo "    exit $? $label $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1 | cut -c1-160)"
}
one40() {
  local label=@r1_pnn40_s27p18g61_st1e
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${B[@]}" --rubric r1_pn --stack 1 --response_part 18 \
      --entities_per_call 40 --max_tokens 600 --cell_label $label --budget_usd 15 >> "$L/$M$label.log" 2>&1
  echo "    exit $? $label $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1 | cut -c1-160)"
}
one40 & run40 0 & run40 9 &
wait
run40 18
echo "=== done 40 $(date -u +%FT%TZ)"
