data_dir=~/Desktop/PlaJa-RRL-Dataset/mod_transport/det/mod_linetrack_17_10
model_dir=~/Desktop/PlaJa-RRL-Dataset/models/mod_linetrack_17_10_det
run_dir=~/Desktop/PlaJa-RRL-Dataset/microplaja_eval/mod_linetrack_17_10_det
mkdir -p "$run_dir"

jani_file="$data_dir/mod_linetrack_17_10.jani"
property_file="$data_dir/pa_mod_linetrack_17_10_random_starts_1000.jani"
interface_file="$data_dir/mod_linetrack_17_10_crazy_long.jani2nnet"
model_file1="$model_dir/mod_linetrack_17_10_det@8/sym_model.json"
model_file2="$model_dir/mod_linetrack_17_10_det@16/sym_model.json"
model_file3="$model_dir/mod_linetrack_17_10_det@32/sym_model.json"
model_file4="$model_dir/mod_linetrack_17_10_det@32@32/sym_model.json"
model_file5="$model_dir/mod_linetrack_17_10_det@64/sym_model.json"
model_file6="$model_dir/mod_linetrack_17_10_det@64@32/sym_model.json"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file1" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/mod_linetrack_17_10_det@8.log"


python3 -m runner \
  --policy rrl \
  --sym_model "$model_file2" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/mod_linetrack_17_10_det@16.log"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file3" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/mod_linetrack_17_10_det@32.log"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file4" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/mod_linetrack_17_10_det@32@32.log"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file5" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/mod_linetrack_17_10_det@64.log"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file6" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/mod_linetrack_17_10_det@64@32.log"