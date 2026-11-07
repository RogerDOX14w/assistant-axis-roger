#!/bin/zsh
# Jev yes/no at 20 answers x 24 axes a request on the 61 axes, the ninth (Roger, 2026-11-05: "unless we find 12 is
# clearly worse than 6, I think the next step would be to test 24 axes at once"; 6 against 12 was +0.0011, n.s., at 34%
# more cost).  61 axes at 24 are three requests of 20-21 axes; largest request about 41k tokens; about $6.  Waits for
# run_jev_noul_grid61.sh.
set -u
L=roger/axis_judge_experiments/response_pilot_logs
until grep -q "^=== done" $L/run_jev_noul_grid61.out 2>/dev/null; do sleep 30; done
label=@jb61_noul_a20m24_s9p0
echo "=== $label $(date -u +%FT%TZ)"
uv run python scripts/judge_responses_jev.py --axes_file scripts/tier_eval_axes.tsv \
    --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 9 --response_part 0 \
    --response_design question --instructions_dir /tmp/claude-501/corpus_2026-05-24/data --design relative \
    --batch_question noul --shuffle_seed 1 --max_in_flight 24 --answers_per_request 20 --axes_per_request 24 \
    --cell_label $label --budget_usd 12 > $L/$label.log 2>&1
echo "    exit $? $(grep -E 'usage' $L/$label.log | tail -1 | cut -c1-200)"
echo "=== done $(date -u +%FT%TZ)"
