#!/bin/zsh
# Gemini's third, relaunched 2026-11-06 23:30 UTC with the two one-axis parts IN PARALLEL.  run_third_gemini_anchor6.sh
# ran them one after the other, and a one-axis part of split 9 takes about six hours at the explicit-cache pace (the
# dispatcher keeps only 2-4 requests in flight for that design, as it did on the ninth's cells), so the chain would have
# ended about 08:30 UTC; this ends about 05:30.  State when stopped: k6 part 3 done ($11.04); k6 part 6 at 54% and the
# one-axis part 3 at about 50%, both resumed here from their answers.partial.jsonl (the last line checked valid JSON);
# the one-axis part 6 not started.  Settings as that script (Flex, explicit caches, max_tokens 300 / 1200, 40 in flight).
set -u
L=roger/axis_judge_experiments/response_pilot_logs
M=gemini-3.1-flash-lite
G=(--judge_model $M --transport flex --gemini_cache explicit --max_in_flight 40 --shuffle_seed 1 --entities_per_call 20
   --instructions_dir /tmp/claude-501/corpus_2026-05-24/data --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot"
   --response_design question --axes_file scripts/tier_eval_axes.tsv --axes_per_call 61 --response_split 9)
run() {  # label flags...
  local label=$1; shift
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${G[@]}" "$@" --cell_label $label >> "$L/$M$label.log" 2>&1
  echo "    exit $? $label $(date -u +%FT%TZ) $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1 | cut -c1-160)"
}
run @r1_pnn20_s9p3g61_st1e --response_part 3 --rubric r1_pn --stack 1 --max_tokens 300 --budget_usd 38 &
run @r1_pnn20_s9p6g61_st1e --response_part 6 --rubric r1_pn --stack 1 --max_tokens 300 --budget_usd 38 &
run @rk_pnn20_s9p6g61_k6 --response_part 6 --rubric rk_pn --stack 6 --max_tokens 1200 --budget_usd 20 &
wait
echo "=== done third $(date -u +%FT%TZ)"
