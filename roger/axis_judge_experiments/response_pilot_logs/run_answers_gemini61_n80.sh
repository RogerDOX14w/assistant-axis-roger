#!/bin/zsh
# Gemini 3.1 Flash-Lite, 80 answers a call on the 61 axes (Roger, 2026-11-05: "Gemini 40 is clearly uniformly better,
# try 80 as well").  Settings as run_answers_hg61.sh gemini (one axis a call, r1_pn, a coin per call, the round-robin
# 1/27 share by question) but by Flex (Roger: "all flex or batch as appropriate"; about $11), cap 1200 (600 at 40).
# The first axis runs alone (its prefixes and the tool's first live Gemini Flex run), then three streams.  Run from the root.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
M=gemini-3.1-flash-lite
C=(--judge_model $M --transport flex --rubric r1_pn --directions responses --axes_per_call 61 --shuffle_seed 1
   --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 27 --response_part 0
   --response_design question --max_in_flight 40 --max_tokens 1200 --entities_per_call 80)
run() {
  local label=@r1_pnn80_s27p0g61_a$1c
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --cell_label $label --axis_index $1 --budget_usd $2 \
      >> "$L/$M$label.log" 2>&1
  echo "    exit $? $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1)"
}
if [[ ${1:-} == first ]]; then run 0 1.5; exit; fi
if [[ ${1:-} == second ]]; then run 1 1.0; exit; fi
R=({2..61})
( for i in ${R[1,20]}; do run $i 1.0; done ) &
( for i in ${R[21,40]}; do run $i 1.0; done ) &
( for i in ${R[41,59]}; do run $i 1.0; done ) &
wait
echo "=== done $(date -u +%FT%TZ)"
