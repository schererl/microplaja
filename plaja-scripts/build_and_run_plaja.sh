#!/usr/bin/env bash
set -euo pipefail

# === CONFIGURATION ===
IMAGE="chaahatjain/plaja_dependencies:MRv0.3"
PLAJA_DIR="$HOME/Desktop/plaja-fault_analysis_policy_iteration"
MICRO_DIR="$HOME/Desktop/microplaja"
OUT_DIR="$HOME/Desktop/plaja-out"

MODEL="$MICRO_DIR/example/one_way_line_15_10.jani"
PROPS="$MICRO_DIR/example/pa_one_way_line_15_10_random_starts_1000.jani"
IFACE="$MICRO_DIR/example/one_way_line_15_10_128_128.jani2nnet"
FNN="$MICRO_DIR/example/sym_model.json"

mkdir -p "$OUT_DIR"

echo "[BUILD] Building PlaJA inside Docker container..."
docker run --rm \
  -v "$PLAJA_DIR":/ws \
  -w /ws \
  "$IMAGE" \
  bash -c "mkdir -p build && cd build && make -j4"
  #bash -c "mkdir -p build && cd build && cmake .. && make -j4"

echo "[BUILD] Done."

echo "[RUN] Running example with model: $(basename "$MODEL")"
docker run --rm \
  -u "$(id -u)":"$(id -g)" \
  -v "$PLAJA_DIR":/ws \
  -v "$MICRO_DIR/example":/dataset \
  -v "$OUT_DIR":/out \
  -w /ws/build \
  "$IMAGE" \
  ./PlaJA \
    --engine QL_AGENT \
    --model-file "/dataset/$(basename "$MODEL")" \
    --additional-properties "/dataset/$(basename "$PROPS")" \
    --fnn-interface "/dataset/$(basename "$IFACE")" \
    --fnn "/dataset/$(basename "$FNN")" \
    --prop 1 \
    --max-time 300 \
    --num-episodes 100 \
    --applicability-filtering 1 \
    --evaluation-mode \
    --print-stats

echo "[DONE] Example run finished. Output stored in: $OUT_DIR"
