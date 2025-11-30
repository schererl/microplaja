data_dir=~/Desktop/PlaJa-RRL-Dataset/race_transport/non_det_icy_drop_park
model_dir=~/Desktop/PlaJa-RRL-Dataset/models/race_linetrack_17_10_icy
run_dir=~/Desktop/PlaJa-RRL-Dataset/microplaja_eval/race_linetrack_17_10_icy
mkdir -p "$run_dir"

jani_file="$data_dir/race_linetrack_17_10.jani"
property_file="$data_dir/pa_race_linetrack_17_10_random_starts_1000.jani"
interface_file="$data_dir/race_linetrack_17_10_128_128.jani2nnet"
#model_file1="$model_dir/race_linetrack_17_10_icy@8/sym_model.json"
#model_file2="$model_dir/race_linetrack_17_10_icy@16/sym_model.json"
#model_file3="$model_dir/race_linetrack_17_10_icy@32/sym_model.json"
#model_file4="$model_dir/race_linetrack_17_10_icy@32@32/sym_model.json"
#model_file5="$model_dir/race_linetrack_17_10_icy@64/sym_model.json"
model_file1="$model_dir/race_linetrack_17_10_icy@64/sym_model.json"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file1" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 100 >> "$run_dir/race_linetrack_17_10_icy@64.log"


# python3 -m runner \
#   --policy rrl \
#   --sym_model "$model_file2" \
#   --jani "$jani_file" \
#   --property "$property_file" \
#   --interface "$interface_file" \
#   --episodes 10 >> "$run_dir/race_linetrack_17_10_icy@16.log"

# python3 -m runner \
#   --policy rrl \
#   --sym_model "$model_file3" \
#   --jani "$jani_file" \
#   --property "$property_file" \
#   --interface "$interface_file" \
#   --episodes 10 >> "$run_dir/race_linetrack_17_10_icy@32.log"

# python3 -m runner \
#   --policy rrl \
#   --sym_model "$model_file4" \
#   --jani "$jani_file" \
#   --property "$property_file" \
#   --interface "$interface_file" \
#   --episodes 10 >> "$run_dir/race_linetrack_17_10_icy@32@32.log"

# python3 -m runner \
#   --policy rrl \
#   --sym_model "$model_file5" \
#   --jani "$jani_file" \
#   --property "$property_file" \
#   --interface "$interface_file" \
#   --episodes 10 >> "$run_dir/race_linetrack_17_10_icy@64.log"

# python3 -m runner \
#   --policy rrl \
#   --sym_model "$model_file6" \
#   --jani "$jani_file" \
#   --property "$property_file" \
#   --interface "$interface_file" \
#   --episodes 10 >> "$run_dir/race_linetrack_17_10_icy@64@32.log"