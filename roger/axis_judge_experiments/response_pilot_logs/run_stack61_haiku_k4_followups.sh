#!/bin/zsh
# Haiku 5.5 at its new settled design, k = 4 with the worst 25% one axis a call (Roger, 2026-11-07: "Haiku should be
# k=4, 25% -- which is a change"; "redo the follow-up plots and show them to me"): the two cells the follow-up figures
# (judge_response_pareto_formats_settled_haiku.png, ..._answers_settled_haiku.png) still lack at k = 4.
#   1. axis by axis at k = 4 (@rk_pan20_s9p0g61_k4): run on 2026-11-05 by run_stack61_haiku_formats.sh and left with
#      120 calls unanswered ("rerun to ask them"); the same command resumes it from its partial answers (cents).
#   2. 40 answers a call at k = 4 (@rk_pnn40_s9p0g61_k4), as the k = 2 cell of run_stack61_settled.sh (rk_pn, 40,
#      max_tokens 1200 = 2 x (300 + 150 k)) at k = 4: max_tokens 1800.  About $6 by Message Batches (k = 2: $7.52).
# Everything else as run_stack61_haiku_batch.sh: Message Batches, the ninth cut by question (part 0 of split 9), seed 1.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
C=(--judge_model claude-haiku-5-5 --transport batch --axes_per_call 61 --shuffle_seed 1
   --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 9 --response_part 0
   --response_design question --batch_poll_seconds 60)
( label=@rk_pan20_s9p0g61_k4
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --rubric rk_pa --stack 4 --entities_per_call 20 \
      --max_tokens 1100 --budget_usd 12 --cell_label $label >> "$L/claude-haiku-5-5$label.log" 2>&1
  echo "rk_pa k=4 resume: exit $? $(grep -A1 '^Summary:' "$L/claude-haiku-5-5$label.log" | tail -1)" ) &
( label=@rk_pnn40_s9p0g61_k4
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --rubric rk_pn --stack 4 --entities_per_call 40 \
      --max_tokens 1800 --budget_usd 12 --cell_label $label > "$L/claude-haiku-5-5$label.log" 2>&1
  echo "rk_pn 40 k=4: exit $? $(grep -A1 '^Summary:' "$L/claude-haiku-5-5$label.log" | tail -1)" ) &
wait
echo "=== done $(date -u +%FT%TZ)"
