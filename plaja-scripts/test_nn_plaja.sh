set -euo pipefail
trap 'echo; echo "[ABORT] Caught Ctrl-C, stopping script."; exit 130' INT

PLAJA_DIR="$HOME/Desktop/plaja-fault_analysis_policy_iteration"
DATASET_DIR="$HOME/Desktop/plaja-benchmarks/benchmarks"
OUT_ROOT="$HOME/Desktop/plaja-benchmarks/plaja_runs"
IMAGE="chaahatjain/plaja_dependencies:MRv0.3"

check_files_exist() {
    local job="$1" model="$2" props="$3" iface="$4" nnet="${5:-}"
    local missing=0

    for f in "$model" "$props" "$iface"; do
        if [[ ! -f "$DATASET_DIR/${f#/dataset/}" && ! -f "$f" ]]; then
            echo "[MISSING] $job - file not found: $f" | tee -a "$OUT_ROOT/missing_files.log"
            missing=1
        fi
    done

    # nnet is only used in run_job, you can skip this for train_job
    if [[ -n "$nnet" ]]; then
        if [[ ! -f "$DATASET_DIR/${nnet#/dataset/}" && ! -f "$nnet" ]]; then
            echo "[MISSING] $job - file not found: $nnet" | tee -a "$OUT_ROOT/missing_files.log"
            missing=1
        fi
    fi

    return $missing
}



run_job(){
    local job="$1" model="$2" props="$3" iface="$4" nnet="$5"

    local OUT_DIR="$OUT_ROOT/$job"
    mkdir -p "$OUT_DIR"
    local LOG_FILE="$OUT_DIR/run.log"
    local ACT_FILE="$OUT_DIR/dataset.json"

    if ! check_files_exist "$job" "$model" "$props" "$iface" "$nnet"; then
        echo "[SKIP] $job - missing files" | tee -a "$OUT_ROOT/failed_jobs_test.log"
        return
    fi

    echo "[RUN] $job"
    set +e
    docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$PLAJA_DIR":/plaja \
    -v "$DATASET_DIR":/dataset \
    -v "$OUT_DIR":/out \
    -w / \
    "$IMAGE" \
    /plaja/build/PlaJA \
        --engine QL_AGENT \
        --model-file "$model" \
        --additional-properties "$props" \
        --nn-interface "$iface" \
        --load-nn "$nnet" \
        --prop 1 \
        --max-time 1800 \
        --num-episodes 5000 \
        --applicability-filtering 1 \
        --evaluation-mode \
        --print-stats \
        --save-agent-actions "/out/$(basename "$ACT_FILE")" \
        --stats-file "/out/stats.csv" \
        >"$LOG_FILE" 2>&1
    
    local status=$?
    set -e
    if [[ $status -ne 0 ]]; then
        echo "[FAIL] $job - exit code $status" | tee -a "$OUT_ROOT/failed_jobs_test.log"
    else
        echo "[OK] $job"
    fi
}


##### BELUGA #####
BELUGA_PROP_DIR="/dataset/beluga/additional_properties/learning/swap_unsafe/random_starts_1000"
BELUGA_JANI_DIR="/dataset/beluga/models/swap_unsafe"
BELUGA_INTERFACE_DIR="/dataset/beluga/networks/swap_unsafe"

run_job "beluga_4_2" "$BELUGA_JANI_DIR"/beluga_4_2.jani "$BELUGA_PROP_DIR"/beluga_4_2/pa_beluga_4_2_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_4_2/beluga_4_2_128_128.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_4_2/beluga_4_2_128_128.nnet
run_job "beluga_5_2" "$BELUGA_JANI_DIR"/beluga_5_2.jani "$BELUGA_PROP_DIR"/beluga_5_2/pa_beluga_5_2_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_5_2/beluga_5_2_256_256.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_5_2/beluga_5_2_256_256.nnet
run_job "beluga_6_2" "$BELUGA_JANI_DIR"/beluga_6_2.jani "$BELUGA_PROP_DIR"/beluga_6_2/pa_beluga_6_2_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_6_2/beluga_6_2_256_256.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_6_2/beluga_6_2_256_256.nnet
# run_job "beluga_6_3" "$BELUGA_JANI_DIR"/beluga_6_3.jani "$BELUGA_PROP_DIR"/beluga_6_3/pa_beluga_6_3_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_6_3/beluga_6_3_256_256.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_6_3/beluga_6_3_256_256.nnet
# run_job "beluga_8_2" "$BELUGA_JANI_DIR"/beluga_8_2.jani "$BELUGA_PROP_DIR"/beluga_8_2/pa_beluga_8_2_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_8_2/beluga_8_2_256_256.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_8_2/beluga_8_2_256_256.nnet
# run_job "beluga_8_3" "$BELUGA_JANI_DIR"/beluga_8_3.jani "$BELUGA_PROP_DIR"/beluga_8_3/pa_beluga_8_3_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_8_3/beluga_8_3_256_256.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_8_3/beluga_8_3_256_256.nnet
# run_job "beluga_10_2" "$BELUGA_JANI_DIR"/beluga_10_2.jani "$BELUGA_PROP_DIR"/beluga_10_2/pa_beluga_10_2_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_10_2/beluga_10_2_256_128_64_32_16.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_10_2/beluga_10_2_256_128_64_32_16.nnet
# run_job "beluga_10_4" "$BELUGA_JANI_DIR"/beluga_10_4.jani "$BELUGA_PROP_DIR"/beluga_10_4/pa_beluga_10_4_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_10_4/beluga_10_4_256_128_64_32_16.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_10_4/beluga_10_4_256_128_64_32_16.nnet
# run_job "beluga_12_3" "$BELUGA_JANI_DIR"/beluga_12_3.jani "$BELUGA_PROP_DIR"/beluga_12_3/pa_beluga_12_3_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_12_3/beluga_12_3_256_128_64_32_16.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_12_3/beluga_12_3_256_128_64_32_16.nnet
# run_job "beluga_12_5" "$BELUGA_JANI_DIR"/beluga_12_5.jani "$BELUGA_PROP_DIR"/beluga_12_5/pa_beluga_12_5_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_12_5/beluga_12_5_256_128_64_32_16.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_12_5/beluga_12_5_256_128_64_32_16.nnet
# run_job "beluga_15_5" "$BELUGA_JANI_DIR"/beluga_15_5.jani "$BELUGA_PROP_DIR"/beluga_15_5/pa_beluga_15_5_random_starts_1000.jani "$BELUGA_INTERFACE_DIR"/beluga_15_5/beluga_15_5_256_128_64_32_16.jani2nnet "$BELUGA_INTERFACE_DIR"/beluga_15_5/beluga_15_5_256_128_64_32_16.nnet


##### ONE-WAY LINE #####

# deterministic
OwL_det_JANI_DIR="/dataset/one_way_line/models/det"
OwL_det_PROP_DIR="/dataset/one_way_line/additional_properties/repair/det/random_starts_1000"
OwL_det_INTERFACE_DIR="/dataset/one_way_line/networks/det"

run_job "one_way_line_15_10_det" \
    "$OwL_det_JANI_DIR"/one_way_line_15_10.jani \
    "$OwL_det_PROP_DIR"/one_way_line_15_10/pa_one_way_line_15_10_random_starts_1000.jani \
    "$OwL_det_INTERFACE_DIR"/one_way_line_15_10/one_way_line_15_10_128_128.jani2nnet \
    "$OwL_det_INTERFACE_DIR"/one_way_line_15_10/one_way_line_15_10_128_128.nnet
run_job "one_way_line_17_10_det" \
    "$OwL_det_JANI_DIR"/one_way_line_17_10.jani \
    "$OwL_det_PROP_DIR"/one_way_line_17_10/pa_one_way_line_17_10_random_starts_1000.jani \
    "$OwL_det_INTERFACE_DIR"/one_way_line_17_10/one_way_line_17_10_256_256.jani2nnet \
    "$OwL_det_INTERFACE_DIR"/one_way_line_17_10/one_way_line_17_10_256_256.nnet
run_job "one_way_line_20_10_det" \
    "$OwL_det_JANI_DIR"/one_way_line_20_10.jani \
    "$OwL_det_PROP_DIR"/one_way_line_20_10/pa_one_way_line_20_10_random_starts_1000.jani \
    "$OwL_det_INTERFACE_DIR"/one_way_line_20_10/one_way_line_20_10_256_256.jani2nnet \
    "$OwL_det_INTERFACE_DIR"/one_way_line_20_10/one_way_line_20_10_256_256.nnet

# non-deterministic no park
OwL_nod_nop_JANI_DIR="/dataset/one_way_line/models/non_det_no_park"
OwL_nod_nop_PROP_DIR="/dataset/one_way_line/additional_properties/repair/non_det_no_park/random_starts_1000"
OwL_nod_nop_INTERFACE_DIR="/dataset/one_way_line/networks/non_det_no_park"
run_job "one_way_line_15_10_nod_park" \
    "$OwL_nod_nop_JANI_DIR"/one_way_line_15_10.jani \
    "$OwL_nod_nop_PROP_DIR"/one_way_line_15_10/pa_one_way_line_15_10_random_starts_1000.jani \
    "$OwL_nod_nop_INTERFACE_DIR"/one_way_line_15_10/one_way_line_15_10_128_128.jani2nnet \
    "$OwL_nod_nop_INTERFACE_DIR"/one_way_line_15_10/one_way_line_15_10_128_128.nnet
run_job "one_way_line_17_10_nod_park" \
    "$OwL_nod_nop_JANI_DIR"/one_way_line_17_10.jani \
    "$OwL_nod_nop_PROP_DIR"/one_way_line_17_10/pa_one_way_line_17_10_random_starts_1000.jani \
    "$OwL_nod_nop_INTERFACE_DIR"/one_way_line_17_10/one_way_line_17_10_256_256.jani2nnet \
    "$OwL_nod_nop_INTERFACE_DIR"/one_way_line_17_10/one_way_line_17_10_256_256.nnet
run_job "one_way_line_20_10_nod_park" \
    "$OwL_nod_nop_JANI_DIR"/one_way_line_20_10.jani \
    "$OwL_nod_nop_PROP_DIR"/one_way_line_20_10/pa_one_way_line_20_10_random_starts_1000.jani \
    "$OwL_nod_nop_INTERFACE_DIR"/one_way_line_20_10/one_way_line_20_10_256_256.jani2nnet \
    "$OwL_nod_nop_INTERFACE_DIR"/one_way_line_20_10/one_way_line_20_10_256_256.nnet

# non-deterministic with park
OwL_nod_park_JANI_DIR="/dataset/one_way_line/models/non_det_with_park"
OwL_nod_park_PROP_DIR="/dataset/one_way_line/additional_properties/repair/non_det_with_park/random_starts_1000"
OwL_nod_park_INTERFACE_DIR="/dataset/one_way_line/networks/non_det_with_park"

run_job "one_way_line_15_10_nod_nop" \
    "$OwL_nod_park_JANI_DIR"/one_way_line_15_10.jani \
    "$OwL_nod_park_PROP_DIR"/one_way_line_15_10/pa_one_way_line_15_10_random_starts_1000.jani \
    "$OwL_nod_park_INTERFACE_DIR"/one_way_line_15_10/one_way_line_15_10_128_128.jani2nnet \
    "$OwL_nod_park_INTERFACE_DIR"/one_way_line_15_10/one_way_line_15_10_128_128.nnet
run_job "one_way_line_17_10_nod_nop" \
    "$OwL_nod_park_JANI_DIR"/one_way_line_17_10.jani \
    "$OwL_nod_park_PROP_DIR"/one_way_line_17_10/pa_one_way_line_17_10_random_starts_1000.jani \
    "$OwL_nod_park_INTERFACE_DIR"/one_way_line_17_10/one_way_line_17_10_256_256.jani2nnet \
    "$OwL_nod_park_INTERFACE_DIR"/one_way_line_17_10/one_way_line_17_10_256_256.nnet
run_job "one_way_line_20_10_nod_nop" \
    "$OwL_nod_park_JANI_DIR"/one_way_line_20_10.jani \
    "$OwL_nod_park_PROP_DIR"/one_way_line_20_10/pa_one_way_line_20_10_random_starts_1000.jani \
    "$OwL_nod_park_INTERFACE_DIR"/one_way_line_20_10/one_way_line_20_10_256_256.jani2nnet \
    "$OwL_nod_park_INTERFACE_DIR"/one_way_line_20_10/one_way_line_20_10_256_256.nnet

##### TWO-WAY LINE #####

# deterministic
TwL_det_JANI_DIR="/dataset/two_way_line/models/det"
TwL_det_PROP_DIR="/dataset/two_way_line/additional_properties/repair/det/random_starts_1000"
TwL_det_INTERFACE_DIR="/dataset/two_way_line/networks/det"

run_job "two_way_line_15_10_det" \
    "$TwL_det_JANI_DIR"/two_way_line_15_10.jani \
    "$TwL_det_PROP_DIR"/two_way_line_15_10/pa_two_way_line_15_10_random_starts_1000.jani \
    "$TwL_det_INTERFACE_DIR"/two_way_line_15_10/two_way_line_15_10_128_128.jani2nnet \
    "$TwL_det_INTERFACE_DIR"/two_way_line_15_10/two_way_line_15_10_128_128.nnet
run_job "two_way_line_17_10_det" \
    "$TwL_det_JANI_DIR"/two_way_line_17_10.jani \
    "$TwL_det_PROP_DIR"/two_way_line_17_10/pa_two_way_line_17_10_random_starts_1000.jani \
    "$TwL_det_INTERFACE_DIR"/two_way_line_17_10/two_way_line_17_10_256_256.jani2nnet \
    "$TwL_det_INTERFACE_DIR"/two_way_line_17_10/two_way_line_17_10_256_256.nnet
run_job "two_way_line_20_10_det" \
    "$TwL_det_JANI_DIR"/two_way_line_20_10.jani \
    "$TwL_det_PROP_DIR"/two_way_line_20_10/pa_two_way_line_20_10_random_starts_1000.jani \
    "$TwL_det_INTERFACE_DIR"/two_way_line_20_10/two_way_line_20_10_256_256.jani2nnet \
    "$TwL_det_INTERFACE_DIR"/two_way_line_20_10/two_way_line_20_10_256_256.nnet

# non-deterministic no park
TwL_nod_nop_JANI_DIR="/dataset/two_way_line/models/non_det_no_park"
TwL_nod_nop_PROP_DIR="/dataset/two_way_line/additional_properties/repair/non_det_no_park/random_starts_1000"
TwL_nod_nop_INTERFACE_DIR="/dataset/two_way_line/networks/non_det_no_park"

run_job "two_way_line_15_10_nod_nop" \
    "$TwL_nod_nop_JANI_DIR"/two_way_line_15_10.jani \
    "$TwL_nod_nop_PROP_DIR"/two_way_line_15_10/pa_two_way_line_15_10_random_starts_1000.jani \
    "$TwL_nod_nop_INTERFACE_DIR"/two_way_line_15_10/two_way_line_15_10_128_128.jani2nnet \
    "$TwL_nod_nop_INTERFACE_DIR"/two_way_line_15_10/two_way_line_15_10_128_128.nnet
run_job "two_way_line_17_10_nod_nop" \
    "$TwL_nod_nop_JANI_DIR"/two_way_line_17_10.jani \
    "$TwL_nod_nop_PROP_DIR"/two_way_line_17_10/pa_two_way_line_17_10_random_starts_1000.jani \
    "$TwL_nod_nop_INTERFACE_DIR"/two_way_line_17_10/two_way_line_17_10_256_256.jani2nnet \
    "$TwL_nod_nop_INTERFACE_DIR"/two_way_line_17_10/two_way_line_17_10_256_256.nnet
run_job "two_way_line_20_10_nod_nop" \
    "$TwL_nod_nop_JANI_DIR"/two_way_line_20_10.jani \
    "$TwL_nod_nop_PROP_DIR"/two_way_line_20_10/pa_two_way_line_20_10_random_starts_1000.jani \
    "$TwL_nod_nop_INTERFACE_DIR"/two_way_line_20_10/two_way_line_20_10_256_256.jani2nnet \
    "$TwL_nod_nop_INTERFACE_DIR"/two_way_line_20_10/two_way_line_20_10_256_256.nnet

# non-deterministic with park
TwL_nod_park_JANI_DIR="/dataset/two_way_line/models/non_det_with_park"
TwL_nod_park_PROP_DIR="/dataset/two_way_line/additional_properties/repair/non_det_with_park/random_starts_1000"
TwL_nod_park_INTERFACE_DIR="/dataset/two_way_line/networks/non_det_with_park"

run_job "two_way_line_15_10_nod_park" \
    "$TwL_nod_park_JANI_DIR"/two_way_line_15_10.jani \
    "$TwL_nod_park_PROP_DIR"/two_way_line_15_10/pa_two_way_line_15_10_random_starts_1000.jani \
    "$TwL_nod_park_INTERFACE_DIR"/two_way_line_15_10/two_way_line_15_10_128_128.jani2nnet \
    "$TwL_nod_park_INTERFACE_DIR"/two_way_line_15_10/two_way_line_15_10_128_128.nnet
run_job "two_way_line_17_10_nod_park" \
    "$TwL_nod_park_JANI_DIR"/two_way_line_17_10.jani \
    "$TwL_nod_park_PROP_DIR"/two_way_line_17_10/pa_two_way_line_17_10_random_starts_1000.jani \
    "$TwL_nod_park_INTERFACE_DIR"/two_way_line_17_10/two_way_line_17_10_256_256.jani2nnet \
    "$TwL_nod_park_INTERFACE_DIR"/two_way_line_17_10/two_way_line_17_10_256_256.nnet
run_job "two_way_line_20_10_nod_park" \
    "$TwL_nod_park_JANI_DIR"/two_way_line_20_10.jani \
    "$TwL_nod_park_PROP_DIR"/two_way_line_20_10/pa_two_way_line_20_10_random_starts_1000.jani \
    "$TwL_nod_park_INTERFACE_DIR"/two_way_line_20_10/two_way_line_20_10_256_256.jani2nnet \
    "$TwL_nod_park_INTERFACE_DIR"/two_way_line_20_10/two_way_line_20_10_256_256.nnet