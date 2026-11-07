#!/bin/zsh
# Jev yes/no at 20 answers x 30-31 axes a request (--axes_per_request 31: the 61 axes in two requests), the ninth (Roger,
# 2026-11-05: "test 20 x 30-31"), after the fix of 2026-11-05 that lets a request hold more than 26 axes.  About $6.
set -u
L=roger/axis_judge_experiments/response_pilot_logs
label=@jb61_noul_a20m31_s9p0
echo "=== $label $(date -u +%FT%TZ)"
uv run python scripts/judge_responses_jev.py --axes_file scripts/tier_eval_axes.tsv \
    --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 9 --response_part 0 \
    --response_design question --instructions_dir /tmp/claude-501/corpus_2026-05-24/data --design relative \
    --batch_question noul --shuffle_seed 1 --max_in_flight 24 --answers_per_request 20 --axes_per_request 31 \
    --cell_label $label --budget_usd 12 > $L/$label.log 2>&1
echo "    exit $? $(grep -E 'usage' $L/$label.log | tail -1 | cut -c1-200)"
echo "=== done $(date -u +%FT%TZ)"
