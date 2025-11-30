docker run --rm -it  \
 -v "$HOME/Desktop/plaja-fault_analysis_policy_iteration:/ws"\
 -v "$HOME/Desktop/plaja-benchmarks/benchmarks:/dataset"\
 -w /ws chaahatjain/plaja_dependencies:MRv0.3  /bin/bash
