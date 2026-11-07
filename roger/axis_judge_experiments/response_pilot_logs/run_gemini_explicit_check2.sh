#!/bin/zsh
# Gemini's explicit cache, the paired quality check (Roger, 2026-11-05: "Good point, run that"): one axis a call (r1_pn,
# --stack 1: each batch's 61 calls in turn, so one cachedContents prefix serves them), 20 answers, part 9 of split 27,
# Flex, --gemini_cache explicit: the same batches and coins as the implicit cells @r1_pnn20_s27p9g61_a{i}c, so only the
# request layout (the prefix as its own cached turn) and the cache differ.  Reads its cost and cache share too.  About
# $8-12.  (v2: --stack sets its own directions, so no --directions; v1 of this driver stops at that argparse error at no cost.)  Waits for run_stack61_gemini_ninth.sh (Gemini's tokens-a-minute limit).
set -u
L=roger/axis_judge_experiments/response_pilot_logs
until grep -q "^=== done" $L/run_stack61_gemini_ninth.out 2>/dev/null; do sleep 60; done
label=@r1_pnn20_s27p9g61_st1e
echo "=== $label $(date -u +%FT%TZ)"
.venv/bin/python results_analysis/judge_tier_cost_eval.py --judge_model gemini-3.1-flash-lite --transport flex \
    --gemini_cache explicit --rubric r1_pn --stack 1 --axes_per_call 61 --shuffle_seed 1 \
    --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data \
    --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 27 --response_part 9 \
    --response_design question --entities_per_call 20 --max_tokens 300 --max_in_flight 40 \
    --cell_label $label --budget_usd 20 > "$L/gemini-3.1-flash-lite$label.log" 2>&1
echo "    exit $? $(grep -A1 '^Summary:' "$L/gemini-3.1-flash-lite$label.log" | tail -1)"
echo "=== done $(date -u +%FT%TZ)"
