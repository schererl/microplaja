#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/Desktop/microplaja"
BENCH_ROOT="$HOME/Desktop/plaja-benchmarks/benchmarks"
MODEL_ROOT="$HOME/Desktop/rrl/log_folder"
EVAL_ROOT="$HOME/Desktop/plaja-benchmarks/microplaja_eval"

# --- PROBLEMS (ORDER MATTERS) ---
PROBLEMS=(
  beluga_4_2
  beluga_5_2
  beluga_6_2
  one_way_line_15_10_det
  one_way_line_15_10_nod_nop
  one_way_line_15_10_nod_park
  one_way_line_17_10_det
  one_way_line_17_10_nod_nop
  one_way_line_17_10_nod_park
  one_way_line_20_10_det
  one_way_line_20_10_nod_nop
  one_way_line_20_10_nod_park
  two_way_line_15_10_det
  two_way_line_15_10_nod_nop
  two_way_line_15_10_nod_park
  two_way_line_17_10_det
  two_way_line_17_10_nod_nop
  two_way_line_17_10_nod_park
  two_way_line_20_10_det
  two_way_line_20_10_nod_nop
  two_way_line_20_10_nod_park
)

SPECS=(
  "1@16"
  "1@32"
  "1@64"
  "1@128"
  "1@32@32"
  "1@64@64"
  "1@128@128"
)

# --- JANI FILES (SAME ORDER AS PROBLEMS) ---
JANI_FILES=(
  # beluga
  "$BENCH_ROOT/beluga/models/swap_unsafe/beluga_4_2.jani"
  "$BENCH_ROOT/beluga/models/swap_unsafe/beluga_5_2.jani"
  "$BENCH_ROOT/beluga/models/swap_unsafe/beluga_6_2.jani"

  # one_way_line 15_10
  "$BENCH_ROOT/one_way_line/models/det/one_way_line_15_10.jani"
  "$BENCH_ROOT/one_way_line/models/non_det_no_park/one_way_line_15_10.jani"
  "$BENCH_ROOT/one_way_line/models/non_det_with_park/one_way_line_15_10.jani"

  # one_way_line 17_10
  "$BENCH_ROOT/one_way_line/models/det/one_way_line_17_10.jani"
  "$BENCH_ROOT/one_way_line/models/non_det_no_park/one_way_line_17_10.jani"
  "$BENCH_ROOT/one_way_line/models/non_det_with_park/one_way_line_17_10.jani"

  # one_way_line 20_10
  "$BENCH_ROOT/one_way_line/models/det/one_way_line_20_10.jani"
  "$BENCH_ROOT/one_way_line/models/non_det_no_park/one_way_line_20_10.jani"
  "$BENCH_ROOT/one_way_line/models/non_det_with_park/one_way_line_20_10.jani"

  # two_way_line 15_10
  "$BENCH_ROOT/two_way_line/models/det/two_way_line_15_10.jani"
  "$BENCH_ROOT/two_way_line/models/non_det_no_park/two_way_line_15_10.jani"
  "$BENCH_ROOT/two_way_line/models/non_det_with_park/two_way_line_15_10.jani"

  # two_way_line 17_10
  "$BENCH_ROOT/two_way_line/models/det/two_way_line_17_10.jani"
  "$BENCH_ROOT/two_way_line/models/non_det_no_park/two_way_line_17_10.jani"
  "$BENCH_ROOT/two_way_line/models/non_det_with_park/two_way_line_17_10.jani"

  # two_way_line 20_10
  "$BENCH_ROOT/two_way_line/models/det/two_way_line_20_10.jani"
  "$BENCH_ROOT/two_way_line/models/non_det_no_park/two_way_line_20_10.jani"
  "$BENCH_ROOT/two_way_line/models/non_det_with_park/two_way_line_20_10.jani"
)

# --- PROPERTY FILES (SAME ORDER AS PROBLEMS) ---
PROP_FILES=(
  # beluga
  "$BENCH_ROOT/beluga/additional_properties/learning/swap_unsafe/random_starts_1000/beluga_4_2/pa_beluga_4_2_random_starts_1000.jani"
  "$BENCH_ROOT/beluga/additional_properties/learning/swap_unsafe/random_starts_1000/beluga_5_2/pa_beluga_5_2_random_starts_1000.jani"
  "$BENCH_ROOT/beluga/additional_properties/learning/swap_unsafe/random_starts_1000/beluga_6_2/pa_beluga_6_2_random_starts_1000.jani"

  # one_way_line 15_10
  "$BENCH_ROOT/one_way_line/additional_properties/repair/det/random_starts_1000/one_way_line_15_10/pa_one_way_line_15_10_random_starts_1000.jani"
  "$BENCH_ROOT/one_way_line/additional_properties/repair/non_det_no_park/random_starts_1000/one_way_line_15_10/pa_one_way_line_15_10_random_starts_1000.jani"
  "$BENCH_ROOT/one_way_line/additional_properties/repair/non_det_with_park/random_starts_1000/one_way_line_15_10/pa_one_way_line_15_10_random_starts_1000.jani"

  # one_way_line 17_10
  "$BENCH_ROOT/one_way_line/additional_properties/repair/det/random_starts_1000/one_way_line_17_10/pa_one_way_line_17_10_random_starts_1000.jani"
  "$BENCH_ROOT/one_way_line/additional_properties/repair/non_det_no_park/random_starts_1000/one_way_line_17_10/pa_one_way_line_17_10_random_starts_1000.jani"
  "$BENCH_ROOT/one_way_line/additional_properties/repair/non_det_with_park/random_starts_1000/one_way_line_17_10/pa_one_way_line_17_10_random_starts_1000.jani"

  # one_way_line 20_10
  "$BENCH_ROOT/one_way_line/additional_properties/repair/det/random_starts_1000/one_way_line_20_10/pa_one_way_line_20_10_random_starts_1000.jani"
  "$BENCH_ROOT/one_way_line/additional_properties/repair/non_det_no_park/random_starts_1000/one_way_line_20_10/pa_one_way_line_20_10_random_starts_1000.jani"
  "$BENCH_ROOT/one_way_line/additional_properties/repair/non_det_with_park/random_starts_1000/one_way_line_20_10/pa_one_way_line_20_10_random_starts_1000.jani"

  # two_way_line 15_10
  "$BENCH_ROOT/two_way_line/additional_properties/repair/det/random_starts_1000/two_way_line_15_10/pa_two_way_line_15_10_random_starts_1000.jani"
  "$BENCH_ROOT/two_way_line/additional_properties/repair/non_det_no_park/random_starts_1000/two_way_line_15_10/pa_two_way_line_15_10_random_starts_1000.jani"
  "$BENCH_ROOT/two_way_line/additional_properties/repair/non_det_with_park/random_starts_1000/two_way_line_15_10/pa_two_way_line_15_10_random_starts_1000.jani"

  # two_way_line 17_10
  "$BENCH_ROOT/two_way_line/additional_properties/repair/det/random_starts_1000/two_way_line_17_10/pa_two_way_line_17_10_random_starts_1000.jani"
  "$BENCH_ROOT/two_way_line/additional_properties/repair/non_det_no_park/random_starts_1000/two_way_line_17_10/pa_two_way_line_17_10_random_starts_1000.jani"
  "$BENCH_ROOT/two_way_line/additional_properties/repair/non_det_with_park/random_starts_1000/two_way_line_17_10/pa_two_way_line_17_10_random_starts_1000.jani"

  # two_way_line 20_10
  "$BENCH_ROOT/two_way_line/additional_properties/repair/det/random_starts_1000/two_way_line_20_10/pa_two_way_line_20_10_random_starts_1000.jani"
  "$BENCH_ROOT/two_way_line/additional_properties/repair/non_det_no_park/random_starts_1000/two_way_line_20_10/pa_two_way_line_20_10_random_starts_1000.jani"
  "$BENCH_ROOT/two_way_line/additional_properties/repair/non_det_with_park/random_starts_1000/two_way_line_20_10/pa_two_way_line_20_10_random_starts_1000.jani"
)

# --- INTERFACE FILES (.jani2nnet, SAME ORDER AS PROBLEMS) ---
IFACE_FILES=(
  # beluga
  "$BENCH_ROOT/beluga/networks/swap_unsafe/beluga_4_2/beluga_4_2_128_128.jani2nnet"
  "$BENCH_ROOT/beluga/networks/swap_unsafe/beluga_5_2/beluga_5_2_256_256.jani2nnet"
  "$BENCH_ROOT/beluga/networks/swap_unsafe/beluga_6_2/beluga_6_2_256_256.jani2nnet"

  # one_way_line 15_10
  "$BENCH_ROOT/one_way_line/networks/det/one_way_line_15_10/one_way_line_15_10_128_128.jani2nnet"
  "$BENCH_ROOT/one_way_line/networks/non_det_no_park/one_way_line_15_10/one_way_line_15_10_128_128.jani2nnet"
  "$BENCH_ROOT/one_way_line/networks/non_det_with_park/one_way_line_15_10/one_way_line_15_10_128_128.jani2nnet"

  # one_way_line 17_10
  "$BENCH_ROOT/one_way_line/networks/det/one_way_line_17_10/one_way_line_17_10_256_256.jani2nnet"
  "$BENCH_ROOT/one_way_line/networks/non_det_no_park/one_way_line_17_10/one_way_line_17_10_256_256.jani2nnet"
  "$BENCH_ROOT/one_way_line/networks/non_det_with_park/one_way_line_17_10/one_way_line_17_10_256_256.jani2nnet"

  # one_way_line 20_10
  "$BENCH_ROOT/one_way_line/networks/det/one_way_line_20_10/one_way_line_20_10_256_256.jani2nnet"
  "$BENCH_ROOT/one_way_line/networks/non_det_no_park/one_way_line_20_10/one_way_line_20_10_256_256.jani2nnet"
  "$BENCH_ROOT/one_way_line/networks/non_det_with_park/one_way_line_20_10/one_way_line_20_10_256_256.jani2nnet"

  # two_way_line 15_10
  "$BENCH_ROOT/two_way_line/networks/det/two_way_line_15_10/two_way_line_15_10_128_128.jani2nnet"
  "$BENCH_ROOT/two_way_line/networks/non_det_no_park/two_way_line_15_10/two_way_line_15_10_128_128.jani2nnet"
  "$BENCH_ROOT/two_way_line/networks/non_det_with_park/two_way_line_15_10/two_way_line_15_10_128_128.jani2nnet"

  # two_way_line 17_10
  "$BENCH_ROOT/two_way_line/networks/det/two_way_line_17_10/two_way_line_17_10_256_256.jani2nnet"
  "$BENCH_ROOT/two_way_line/networks/non_det_no_park/two_way_line_17_10/two_way_line_17_10_256_256.jani2nnet"
  "$BENCH_ROOT/two_way_line/networks/non_det_with_park/two_way_line_17_10/two_way_line_17_10_256_256.jani2nnet"

  # two_way_line 20_10
  "$BENCH_ROOT/two_way_line/networks/det/two_way_line_20_10/two_way_line_20_10_256_256.jani2nnet"
  "$BENCH_ROOT/two_way_line/networks/non_det_no_park/two_way_line_20_10/two_way_line_20_10_256_256.jani2nnet"
  "$BENCH_ROOT/two_way_line/networks/non_det_with_park/two_way_line_20_10/two_way_line_20_10_256_256.jani2nnet"
)

cd "$ROOT"
mkdir -p "$EVAL_ROOT"

#######################################
# 1) Compare sym_model vs NN outputs
#######################################
for problem in "${PROBLEMS[@]}"; do
  eval_dir="${EVAL_ROOT}/${problem}"
  mkdir -p "$eval_dir"

  for spec in "${SPECS[@]}"; do
    model_dir="${MODEL_ROOT}/${problem}/model@${problem}@${spec}"
    npz="${model_dir}/pred_dump.npz"
    sym_model="${model_dir}/sym_model.json"

    if [[ ! -f "$sym_model" || ! -f "$npz" ]]; then
      echo "[skip cmp] $problem spec=$spec (missing sym_model or npz)" >&2
      continue
    fi

    echo "[cmp] $problem  spec=$spec"
    python3 -m debug_scripts.test_sym_model \
      --npz "$npz" \
      --model "$sym_model" \
      >> "${eval_dir}/eval-${spec}.log"
  done
done

#######################################
# 2) Run microPlaJa with each sym_model
#######################################
for i in "${!PROBLEMS[@]}"; do
  problem="${PROBLEMS[$i]}"
  jani_file="${JANI_FILES[$i]}"
  property_file="${PROP_FILES[$i]}"
  interface_file="${IFACE_FILES[$i]}"

  run_dir="${EVAL_ROOT}/${problem}"
  mkdir -p "$run_dir"

  for spec in "${SPECS[@]}"; do
    model_dir="${MODEL_ROOT}/${problem}/model@${problem}@${spec}"
    sym_model="${model_dir}/sym_model.json"

    if [[ ! -f "$sym_model" ]]; then
      echo "[skip run] $problem spec=$spec (missing sym_model)" >&2
      continue
    fi

    echo "[run] $problem  spec=$spec"
    python3 -m runner \
      --policy rrl \
      --sym_model "$sym_model" \
      --jani "$jani_file" \
      --property "$property_file" \
      --interface "$interface_file" \
      --episodes 100 \
      >> "${run_dir}/run-${spec}.log"
  done
done

