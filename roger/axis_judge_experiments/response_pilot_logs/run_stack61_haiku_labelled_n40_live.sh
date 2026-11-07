#!/bin/zsh
# Haiku 5.5, the labelled format (rk_pl) stacked 4 axes a call at 40 answers a call on the ninth, in real time: the cell
# the answers-a-call decision under the labelled format needs (Roger, 2026-11-07: "Start with the k= and percentage,
# and then the number of responses in a batch"; on the ETA: "the cost for doing it live is not that high?").  As the
# plain 40-answer k=4 cell of run_stack61_haiku_k4_followups.sh (20 answers x 2, max_tokens 2 x (300 + 200 k) for the
# labelled format) by --transport realtime at 40 in flight (run_answers_hg61.sh).  About $14 live (the plain cell
# cost $6.53 by Message Batches); capped at $20.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
C=(--judge_model claude-haiku-5-5 --transport realtime --max_in_flight 40 --axes_per_call 61 --shuffle_seed 1
   --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 9 --response_part 0
   --response_design question --budget_usd 20)
k=4; fmt=rk_pl
label=@${fmt}n40_s9p0g61_k$k
echo "=== claude-haiku-5-5 $label $(date -u +%FT%TZ)"
.venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --rubric $fmt --stack $k --entities_per_call 40 \
    --max_tokens $(( 2 * (300 + 200 * k) )) --cell_label $label > "$L/claude-haiku-5-5$label.log" 2>&1
echo "    $fmt 40 answers k=$k: exit $? $(grep -A1 '^Summary:' "$L/claude-haiku-5-5$label.log" | tail -1)"
echo "=== done $(date -u +%FT%TZ)"
