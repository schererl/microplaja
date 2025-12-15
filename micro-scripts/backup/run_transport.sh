data_dir=~/Desktop/PlaJa-RRL-Dataset/transport
model_dir=~/Desktop/PlaJa-RRL-Dataset/models/transport
run_dir=~/Desktop/PlaJa-RRL-Dataset/plaja_eval/transport
mkdir -p "$run_dir"

jani_file="$data_dir/linetrack.jani"
property_file="$data_dir/pa_linetrack_random_starts_1000.jani"
interface_file="$data_dir/linetrack_64_64.jani2nnet"
model_file1="$model_dir/linetrack_64_64@8/sym_model.json"
model_file2="$model_dir/linetrack_64_64@16/sym_model.json"
model_file3="$model_dir/linetrack_64_64@32/sym_model.json"
model_file4="$model_dir/linetrack_64_64@32@32/sym_model.json"
model_file5="$model_dir/linetrack_64_64@64/sym_model.json"
model_file6="$model_dir/linetrack_64_64@64@32/sym_model.json"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file1" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/linetrack_64_64@8.log"

 
python3 -m runner \
  --policy rrl \
  --sym_model "$model_file2" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/linetrack_64_64@16.log"


python3 -m runner \
  --policy rrl \
  --sym_model "$model_file3" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/linetrack_64_64@32.log"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file4" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/linetrack_64_64@32@32.log"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file5" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/linetrack_64_64@64.log"

python3 -m runner \
  --policy rrl \
  --sym_model "$model_file6" \
  --jani "$jani_file" \
  --property "$property_file" \
  --interface "$interface_file" \
  --episodes 10 >> "$run_dir/linetrack_64_64@64@32.log"
