#!/bin/zsh
# 20 answers a call against 40 for Haiku 5.5 and Gemini 3.1 Flash-Lite on the 61 axes (Roger, 2026-11-05: redo the
# Luna decision tree for each, step by step, starting here; Gemini on its 1/27 share, "for this step, that should be
# enough"; about $45 Haiku, $62 Gemini).  r1_pn, a coin per call, all 61 axes of scripts/tier_eval_axes.tsv as one group
# (seed 1), the ninth cut by question (Haiku) or its round-robin third (Gemini, split 27 part 0), real time (the tool
# cannot yet send grouped runs through a batch API).  20 answers on the 49 axes outside the twelve (the twelve's cells
# exist), then 40 on all 61; in each phase the first axis alone writes the prefixes, then three streams read them
# (Haiku's cache lives five minutes).  Usage: run_answers_hg61.sh haiku|gemini.  Run from the root.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
case $1 in
  haiku)  M=claude-haiku-5-5; SPLIT=9; LBL=s9p0; FIRST=3; EACH=1.2 ;;
  gemini) M=gemini-3.1-flash-lite; SPLIT=27; LBL=s27p0; FIRST=2; EACH=1.5 ;;
esac
C=(--judge_model $M --transport realtime --rubric r1_pn --directions responses --axes_per_call 61 --shuffle_seed 1
   --axes_file scripts/tier_eval_axes.tsv --instructions_dir /tmp/claude-501/corpus_2026-05-24/data
   --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot" --response_split $SPLIT --response_part 0
   --response_design question --max_in_flight 40 --max_tokens 600)
run() {   # answers a call, axis, budget
  local label=@r1_pnn$1_${LBL}g61_a$2c
  echo "=== $M $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${C[@]}" --entities_per_call $1 --cell_label $label \
      --axis_index $2 --budget_usd $3 > "$L/$M$label.log" 2>&1
  echo "    exit $? $(grep -A1 '^Summary:' "$L/$M$label.log" | tail -1)"
}
TWELVE=(0 7 14 23 26 28 35 42 45 48 52 53)
OTHERS=(1 2 3 4 5 6 8 9 10 11 12 13 15 16 17 18 19 20 21 22 24 25 27 29 30 31 32 33 34 36 37 38 39 40 41 43 44 46 47 49 50 51 54 55 56 57 58 59 60)
phase() {   # answers a call, then the axes
  local n=$1; shift
  local axes=("$@")
  run $n ${axes[1]} $FIRST
  local rest=(${axes[2,-1]})
  local per=$(( (${#rest} + 2) / 3 ))
  ( for i in ${rest[1,$per]}; do run $n $i $EACH; done ) &
  ( for i in ${rest[$((per+1)),$((2*per))]}; do run $n $i $EACH; done ) &
  ( for i in ${rest[$((2*per+1)),-1]}; do run $n $i $EACH; done ) &
  wait
}
phase 20 ${OTHERS[@]}
phase 40 ${OTHERS[@]} ${TWELVE[@]}
echo "=== done $(date -u +%FT%TZ)"
