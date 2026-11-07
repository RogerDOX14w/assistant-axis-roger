#!/bin/zsh
# At each judge's settled stacking (Roger, 2026-11-05: "Luna k=4, 20% left out; Haiku k=2, 10% left out ... For Haiku,
# redo 20 vs 40 at those settings (new graph, not a replacement), and also compare stacking styles at those settings.
# Ditto for Luna at its settings"): the cells those comparisons still lack, on the 61 axes, the ninth cut by question,
# seed 1, all 61 axes (the left-out share is chosen afterwards, cross-fitted).  Luna's formats at k=4 exist.
#   Haiku (Message Batches): plain k=2 at 40 answers (about $6.5), labelled and axis by axis k=2 at 20 (about $16)
#   Luna (Flex): plain k=4 at 40 answers (about $6.5)
# Caps: the 20-answer runs' caps, doubled for 40 answers; formats 300 + 200 k.  Run from the root.
set -u
E=roger/axis_judge_experiments; L=$E/response_pilot_logs
B=(--axes_per_call 61 --shuffle_seed 1 --axes_file scripts/tier_eval_axes.tsv
   --instructions_dir /tmp/claude-501/corpus_2026-05-24/data --responses_dir "runpod_workspace/qwen/qwen-3-32b Roger 8slot"
   --response_split 9 --response_part 0 --response_design question)
H=(--judge_model claude-haiku-5-5 --transport batch --batch_poll_seconds 60 --budget_usd 14)
LU=(--judge_model gpt-5.6-luna --transport flex --max_in_flight 50 --budget_usd 14)
run() {   # model, label, args...
  local m=$1 label=$2; shift 2
  echo "=== $m $label $(date -u +%FT%TZ)"
  .venv/bin/python results_analysis/judge_tier_cost_eval.py "${B[@]}" --cell_label $label "$@" > "$L/$m$label.log" 2>&1
  echo "    $m $label exit $? $(grep -A1 '^Summary:' "$L/$m$label.log" | tail -1)"
}
( run claude-haiku-5-5 @rk_pnn40_s9p0g61_k2 "${H[@]}" --rubric rk_pn --stack 2 --entities_per_call 40 --max_tokens 1200 ) &
( run claude-haiku-5-5 @rk_pln20_s9p0g61_k2 "${H[@]}" --rubric rk_pl --stack 2 --entities_per_call 20 --max_tokens 700 ) &
( run claude-haiku-5-5 @rk_pan20_s9p0g61_k2 "${H[@]}" --rubric rk_pa --stack 2 --entities_per_call 20 --max_tokens 700 ) &
( run "" @rk_pnn40_s9p0g61_k4 "${LU[@]}" --rubric rk_pn --stack 4 --entities_per_call 40 --max_tokens 1360 ) &
wait
echo "=== done $(date -u +%FT%TZ)"
