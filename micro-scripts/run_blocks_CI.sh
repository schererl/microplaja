data_dir=~/Desktop/PlaJa-RRL-Dataset/blocksworld/blocks_4_3
model_dir=~/Desktop/PlaJa-RRL-Dataset/models/blocksworld_4_3_CI
run_dir=~/Desktop/PlaJa-RRL-Dataset/plaja_eval/blocksworld
mkdir -p "$run_dir"

jani_file="$data_dir/blocksworld_4_3.jani"
property_file="$data_dir/CI/pa_compact_starts_no_predicates_blocksworld_4_3_64_64_0.jani"
interface_file="$data_dir/blocksworld_4_3_64_64.jani2nnet"
model_file1="$model_dir/blocksworld_4_3_CI@8/sym_model.json"
model_file2="$model_dir/blocksworld_4_3_CI@16/sym_model.json"
model_file3="$model_dir/blocksworld_4_3_CI@32/sym_model.json"
model_file4="$model_dir/blocksworld_4_3_CI@32@32/sym_model.json"
model_file5="$model_dir/blocksworld_4_3_CI@64/sym_model.json"
model_file6="$model_dir/blocksworld_4_3_CI@64@32/sym_model.json"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file1" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/blocksworld_4_3_CI@8.log"