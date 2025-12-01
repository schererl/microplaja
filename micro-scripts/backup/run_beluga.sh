#!/usr/bin/env bash

ROOT="/home/mago/Desktop/microPlaJa"
DOMAIN_DIR="/home/mago/Desktop/PlaJa-RRL-Dataset/beluga"
MODEL_DIR="/home/mago/Desktop/PlaJa-RRL-Dataset/models"
EVAL_DIR="/home/mago/Desktop/PlaJa-RRL-Dataset/microplaja_eval"

PARAMS=(
  "model@1@8"
  "model@1@16"
  "model@1@32"
  "model@1@64"
  "model@1@32@32"
  "model@1@64@32"
)

PROBLEMS=(
  "beluga_4_2"
  "beluga_5_2"
  "beluga_6_2"
)

cd "$ROOT" || exit 1

for p_name in "${PROBLEMS[@]}"; do
  for param in "${PARAMS[@]}"; do
    mkdir -p "${EVAL_DIR}/${p_name}"
    python -m testing_stuff.test_sym_model \
      --npz "${MODEL_DIR}/${p_name}/${param}/pred_dump.npz" \
      --model "${MODEL_DIR}/${p_name}/${param}/sym_model.json" \
      >> "${EVAL_DIR}/${p_name}/eval-${param}.log"
  done
done

for p_name in "${PROBLEMS[@]}"; do
  jani_file="${DOMAIN_DIR}/${p_name}/${p_name}.jani"
  property_file="${DOMAIN_DIR}/${p_name}/pa_${p_name}_random_starts_1000.jani"
  matches=( "${DOMAIN_DIR}/${p_name}/${p_name}"*.jani2nnet )
  interface_file="${matches[0]}"
  #interface_file="${DOMAIN_DIR}/${p_name}/${p_name}${*}.jani2nnet"

  run_dir="${EVAL_DIR}/${p_name}"
  mkdir -p "$run_dir"

  for param in "${PARAMS[@]}"; do
    sym_model="${MODEL_DIR}/${p_name}/${param}/sym_model.json"
    python3 -m runner \
      --policy rrl \
      --sym_model "$sym_model" \
      --jani "$jani_file" \
      --property "$property_file" \
      --interface "$interface_file" \
      --episodes 100 \
      >> "${run_dir}/run-${param}.log"
  done
done


# today=$(date +%d_%m_%Y)
# summary_file="${EVAL_DIR}/summary_beluga_${today}"

# # header
# echo "problem;model;sym_acc;predict_agreement" > "$summary_file"

# # helper: extract last value of a key (sym_acc=..., pred_agreement=...)
# extract_value () {
#   local key="$1"
#   local file="$2"
#   awk -v key="$key" '
#     /\[cmp\]/ {
#       for (i = 1; i <= NF; i++) {
#         if ($i ~ "^" key "=") {
#           split($i, a, "=")
#           val = a[2]
#         }
#       }
#     }
#     END { if (val != "") print val }
#   ' "$file"
# }

# # 3) Parse each log and append to summary
# for problem in "${PROBLEMS[@]}"; do
#   for param in "${PARAMS[@]}"; do
#     log_file="${EVAL_DIR}/${problem}/eval-${param}.log"

#     if [[ -f "$log_file" ]]; then
#       sym_acc=$(extract_value "sym_acc" "$log_file")
#       pred_agreement=$(extract_value "pred_agreement" "$log_file")

#       echo "${problem};${param};${sym_acc};${pred_agreement}" >> "$summary_file"
#     else
#       echo "Warning: missing log file ${log_file}" >&2
#     fi
#   done
# done
