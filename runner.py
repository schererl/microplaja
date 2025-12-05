from __future__ import annotations
import json
import random
from typing import Dict, List, Tuple, Optional, Any

from jani_environment import JaniEnvironment, load_env
from rrl_policy import RRLPolicy
from model_adapter import RRLAdapter


class RandomPolicy:
    def act(self, state: Dict[str, float], applicable: List[str]) -> str:
        if not applicable:
            raise RuntimeError("No applicable actions in current state.")
        return random.choice(applicable)


def pad_or_trim_trace(trace: List[List[int]], fixed_size: int,
                      final_state: List[int]) -> List[List[int]]:
    if len(trace) > fixed_size:
        return trace[:fixed_size]
    elif len(trace) < fixed_size:
        return trace + [final_state] * (fixed_size - len(trace))
    return trace


def evaluate_episode(
    M: JaniEnvironment,
    pi: RandomPolicy | RRLPolicy,
    max_steps: int = 1000,
    episode_id: int = 0,
) -> Tuple[str, List[List[int]], int]:
    s = M._sample_init()
    trace: List[List[int]] = [[int(s_val) for s_val in s.values()]]

    for t in range(max_steps):
        if M.in_goal(s):
            return "goal", trace, t  # t = number of actions taken so far
        if M.is_unsafe(s):
            return "unsafe", trace, t
        applicable = M.applicable_actions(s)
        if not applicable:
            # no applicable action -> we treat as timeout
            return "timeout", trace, t

        a = pi.act(s, applicable)
        succs = M.successors(s, a)
        s2 = random.choice(succs)
        s = s2
        trace.append([float(s_val) for s_val in s.values()])

    # never hit goal/unsafe within max_steps
    return "timeout", trace, max_steps


def main(
    jani_file: str,
    property_file: str,
    interface_file: str,
    episodes: int = 50,
    max_steps: int = 200,
    policy_kind: str = "random",
    sym_model: Optional[str] = None,
    fixed_tsize: int = -1,
):
    M = load_env(jani_file, property_file)

    if policy_kind in ("random",):
        policy: RandomPolicy | RRLPolicy = RandomPolicy()
    elif policy_kind in ("rrl", "rule-based"):
        if not sym_model:
            raise ValueError("--sym_model is required when --policy rrl")
        adapter = RRLAdapter(var_bounds=M.variables,
                             interface_path=interface_file)
        policy = RRLPolicy(model_path=sym_model,
                           adapter=adapter,
                           eval_mode="compiled")
    else:
        raise ValueError(f"Unknown --policy '{policy_kind}' "
                         "(use 'random' or 'rrl').")

    stats = {"goal": 0, "unsafe": 0, "timeout": 0, "steps_sum": 0}

    # Open dataset file if we want fixed-size traces
    trace_out = None
    if fixed_tsize != -1:
        trace_out = open("episode_traces.jsonl", "w")

    try:
        for ep in range(episodes):
            res, trace, steps = evaluate_episode(
                M,
                policy,
                max_steps=max_steps,
                episode_id=ep,
            )

            stats[res] += 1
            stats["steps_sum"] += steps

            if fixed_tsize != -1:
                # last state in the (possibly shorter) trace
                final_state = trace[-1]
                trace_fixed = pad_or_trim_trace(trace, fixed_tsize, final_state)
                # OUTPUT label:
                # - GOAL if we reached goal
                # - UNSAFE otherwise (timeout or explicit unsafe)
                if res == "goal" or res == "timeout":
                    output_label = "SAFE"
                else:
                    output_label = "UNSAFE"

                row = {
                    "#VARIABLES": len(final_state),
                    "#TRACE": len(trace_fixed),      # should == fixed_tsize
                    "TRACE": trace_fixed,          # list of state vectors
                    "OUTPUT": output_label,        # "GOAL" or "UNSAFE"
                }
                trace_out.write(json.dumps(row) + "\n")
    finally:
        if trace_out is not None:
            trace_out.close()

    avg_steps = stats["steps_sum"] / max(1, episodes)
    print(
        f"\n[{policy_kind.upper()} x JANI] episodes={episodes}  "
        f"goal={stats['goal']}  unsafe={stats['unsafe']}  "
        f"timeout={stats['timeout']}  avg_steps={avg_steps:.1f}"
    )


if __name__ == "__main__":
    import argparse

    ap = argparse.ArgumentParser()
    ap.add_argument("--jani", required=True,
                    help="Path to environment .jani (JSON)")
    ap.add_argument(
        "--property", required=True,
        help="Path to property .jani (start/goal/failure)",
    )
    ap.add_argument(
        "--interface",
        required=True,
        help="Path to interface that maps jani to model (.jani2nnet)",
    )
    ap.add_argument(
        "--policy",
        choices=["random", "rrl", "rule-based"],
        default="random",
        help="Policy to run: random baseline or rule-based (RRL)",
    )
    ap.add_argument(
        "--sym_model",
        help="Path to raw symbolic model .JSON (required if --policy rrl)",
    )
    ap.add_argument("--episodes", type=int, default=10)
    ap.add_argument("--max_steps", type=int, default=100)
    ap.add_argument("--fixed_tsize", type=int, default=-1)
    args = ap.parse_args()

    # If user wants fixed trace size, also bound the rollout length
    if args.fixed_tsize != -1:
        args.max_steps = args.fixed_tsize

    main(
        jani_file=args.jani,
        property_file=args.property,
        interface_file=args.interface,
        episodes=args.episodes,
        max_steps=args.max_steps,
        policy_kind=args.policy,
        sym_model=args.sym_model,
        fixed_tsize=args.fixed_tsize,
    )
