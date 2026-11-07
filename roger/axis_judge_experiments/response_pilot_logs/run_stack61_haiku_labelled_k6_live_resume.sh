#!/bin/zsh
# Haiku 5.5, the labelled format (rk_pl) stacked 6 axes a call on the ninth, in real time: the same cell as
# run_stack61_haiku_labelled_k6.sh, whose Message Batches (submitted 15:56 UTC, nothing succeeded by 16:10) were
# cancelled and their work directory set aside, after Roger (2026-11-07, on an ETA of hours): "the cost for doing it
# live is not that high?".  --transport realtime at 40 in flight (run_answers_hg61.sh); about $8 live (plain k=6 cost
# $4.18 by batch); capped at $15.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
C=(--judge_model claude-haiku-5-5 --transport realtime --max_in_flight 40 --axes_per_call 61 --entities_per_call 20 --shuffle_seed 1
   --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 9 --response_part 0
   --response_design question --budget_usd 6)
k=6; fmt=rk_pl
label=@${fmt}n20_s9p0g61_k$k
echo "=== claude-haiku-5-5 $label live resume $(date -u +%FT%TZ)"
.venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --rubric $fmt --stack $k --max_tokens $(( 300 + 200 * k )) \
    --cell_label $label >> "$L/claude-haiku-5-5$label.log" 2>&1
echo "    $fmt k=$k live: exit $? $(grep -A1 '^Summary:' "$L/claude-haiku-5-5$label.log" | tail -1)"
echo "=== done $(date -u +%FT%TZ)"
