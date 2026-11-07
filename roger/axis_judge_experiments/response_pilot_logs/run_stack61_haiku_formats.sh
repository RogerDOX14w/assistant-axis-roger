#!/bin/zsh
# Haiku 5.5, the stacking formats on the 61 axes (Roger, 2026-11-05: "Run the Haiku stacking formats, at 20%
# exclusion"): labelled (rk_pl) and axis by axis (rk_pa) at k = 4, 20 answers a call (as the plain runs, so the formats
# compare with them), through Message Batches, the ninth cut by question, seed 1, as run_stack61_haiku_batch.sh.  All
# 61 axes are judged: the 20% left out is chosen afterwards, cross-fitted, and differs by fold.  Caps 300 + 200 k (the
# labelled and axis-by-axis replies are longer than plain, where 300 + 150 k cut 140 of 439,440 at k = 4).  About $13.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
C=(--judge_model claude-haiku-5-5 --transport batch --axes_per_call 61 --entities_per_call 20 --shuffle_seed 1
   --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 9 --response_part 0
   --response_design question --batch_poll_seconds 60 --budget_usd 12)
k=4
for fmt in rk_pl rk_pa; do
  ( label=@${fmt}n20_s9p0g61_k$k
    .venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --rubric $fmt --stack $k --max_tokens $(( 300 + 200 * k )) \
        --cell_label $label > "$L/claude-haiku-5-5$label.log" 2>&1
    echo "$fmt k=$k: exit $? $(grep -A1 '^Summary:' "$L/claude-haiku-5-5$label.log" | tail -1)" ) &
done
wait
echo "=== done $(date -u +%FT%TZ)"
