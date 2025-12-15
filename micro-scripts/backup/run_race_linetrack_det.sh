#!/usr/bin/env bash

ROOT="/home/mago/Desktop/microPlaJa"
DOMAIN_DIR="/home/mago/Desktop/PlaJa-RRL-Dataset/race_linetrack/det"
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
  "race_linetrack_17_10"
)

cd "$ROOT" || exit 1

for p_name in "${PROBLEMS[@]}"; do
  for param in "${PARAMS[@]}"; do
    run_dir="${EVAL_DIR}/${p_name}_det"
    mkdir -p "$run_dir"
    python -m testing_stuff.test_sym_model \
      --npz "${MODEL_DIR}/${p_name}_det/${param}/pred_dump.npz" \
      --model "${MODEL_DIR}/${p_name}_det/${param}/sym_model.json" \
      >> "${run_dir}/eval-${param}.log"
  done
done

for p_name in "${PROBLEMS[@]}"; do
  jani_file="${DOMAIN_DIR}/${p_name}/${p_name}.jani"
  property_file="${DOMAIN_DIR}/${p_name}/pa_${p_name}_random_starts_1000.jani"
  matches=( "${DOMAIN_DIR}/${p_name}/${p_name}"*.jani2nnet )
  interface_file="${matches[0]}"
  #interface_file="${DOMAIN_DIR}/${p_name}/${p_name}${*}.jani2nnet"
  run_dir="${EVAL_DIR}/${p_name}_det"
  mkdir -p "$run_dir"

  for param in "${PARAMS[@]}"; do
    sym_model="${MODEL_DIR}/${p_name}_det/${param}/sym_model.json"
    python3 -m runner \
      --policy rrl \
      --sym_model "$sym_model" \
      --jani "$jani_file" \
      --property "$property_file" \
      --interface "$interface_file" \
      --episodes 100 \
      --max_steps 1000 \
      >> "${run_dir}/run-${param}.log"
  done
done