#!/bin/zsh
# Haiku 5.5, the labelled format ("1. SCORES: A=18, B=42", rk_pl) stacked 6 axes a call on the ninth: the one cell the
# k-and-share decision under the labelled format lacks (labelled k=2 and k=4 exist from run_stack61_settled.sh and
# run_stack61_haiku_formats.sh; the worst-X% arms compose from the one-axis-a-call cells, shared by every format).
# Roger, 2026-11-07, on labelled beating plain by 0.003 at k=4: "If we're moving Haiku to labelled, we have a bunch of
# judging and looking at plots to redo ... Start with the k= and percentage, and then the number of responses in a
# batch."  As run_stack61_haiku_formats.sh at k=6: Message Batches, 20 answers a call, seed 1, max_tokens 300 + 200 k.
# About $4-5 (plain k=6 cost $4.18 for 15,682 calls); capped at $12.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
C=(--judge_model claude-haiku-5-5 --transport batch --axes_per_call 61 --entities_per_call 20 --shuffle_seed 1
   --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 9 --response_part 0
   --response_design question --batch_poll_seconds 60 --budget_usd 12)
k=6; fmt=rk_pl
label=@${fmt}n20_s9p0g61_k$k
echo "=== claude-haiku-5-5 $label $(date -u +%FT%TZ)"
.venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --rubric $fmt --stack $k --max_tokens $(( 300 + 200 * k )) \
    --cell_label $label > "$L/claude-haiku-5-5$label.log" 2>&1
echo "    $fmt k=$k: exit $? $(grep -A1 '^Summary:' "$L/claude-haiku-5-5$label.log" | tail -1)"
echo "=== done $(date -u +%FT%TZ)"
