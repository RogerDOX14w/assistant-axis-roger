#!/bin/zsh
# Gemini 3.1 Flash-Lite, 20 / 40 / 80 answers a call taken from the 1/27 share to the ninth (Roger, 2026-11-05: "take
# that Gemini analysis up to 1/9"; "Gemini to 1/9: cost approved", about $100 by Flex).  The ninth (split 9, part 0, by
# question) is split 27 parts 0, 9 and 18 ((question + entity rank) % 27); part 0 is judged, so this judges parts 9 and
# 18, nothing twice.  Settings as run_answers_gemini61_n80.sh (one axis a call, r1_pn, a coin per call, Flex), caps
# 300 / 600 / 1200.  Order: part 9 at 20, 40, 80, then part 18, so a stop leaves every count at 2/27.  Each (count,
# part): axis 0 alone (it writes the implicit cache), then three streams, so the 61 axes read the same prefixes while
# they live.  Waits for the 80-answer part-0 run first (Gemini's 4M tokens a minute).  Run from the root.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
M=gemini-3.1-flash-lite
until grep -q "^=== done" $L/run_answers_gemini61_n80.out 2>/dev/null; do sleep 60; done
C=(--judge_model $M --transport flex --rubric r1_pn --directions responses --axes_per_call 61 --shuffle_seed 1
   --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split 27
   --response_design question --max_in_flight 40)
run() {   # answers, part, axis, budget
  local label=@r1_pnn$1_s27p$2g61_a$3c
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --entities_per_call $1 --response_part $2 \
      --max_tokens $(( 15 * $1 )) --cell_label $label --axis_index $3 --budget_usd $4 >> "$L/$M$label.log" 2>&1
  echo "    exit $? $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1)"
}
R=({1..60})
for part in 9 18; do
  for n in 20 40 80; do
    run $n $part 0 1.5
    ( for i in ${R[1,20]}; do run $n $part $i 1.0; done ) &
    ( for i in ${R[21,40]}; do run $n $part $i 1.0; done ) &
    ( for i in ${R[41,60]}; do run $n $part $i 1.0; done ) &
    wait
  done
done
echo "=== done $(date -u +%FT%TZ)"
