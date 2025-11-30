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


def evaluate_episode(
    M: JaniEnvironment,
    pi: RandomPolicy | RRLPolicy,
    max_steps: int = 1000,
    trace: bool = False,
    trace_sink: Optional[Any] = None,
    episode_id: int = 0,
) -> Tuple[str, int]:
    s = M._sample_init()

    if trace:
        print(f"\n=== EPISODE {episode_id} ===")

        def snap(st: Dict[str, float]) -> str:
            items = list(st.items())[:12]
            fmt = lambda v: int(v) if float(v).is_integer() else round(float(v), 6)
            return ", ".join(f"{k}={fmt(v)}" for k, v in items)

        print(f"-1| <init>                 | {snap(s)}")
        if trace_sink:
            trace_sink.write(
                json.dumps(
                    {"episode": episode_id, "t": -1, "event": "init", "state": s}
                )
                + "\n"
            )

    print(f"max_steps: {max_steps}")

    for t in range(max_steps):
        if M.in_goal(s):
            if trace:
                print(f"{t:2d}| <GOAL>")
                if trace_sink:
                    trace_sink.write(
                        json.dumps(
                            {
                                "episode": episode_id,
                                "t": t,
                                "event": "goal",
                                "state": s,
                            }
                        )
                        + "\n"
                    )
            return ("goal", t)

        if M.is_unsafe(s):
            if trace:
                print(f"{t:2d}| <UNSAFE>")
                if trace_sink:
                    trace_sink.write(
                        json.dumps(
                            {
                                "episode": episode_id,
                                "t": t,
                                "event": "unsafe",
                                "state": s,
                            }
                        )
                        + "\n"
                    )
            return ("unsafe", t)

        applicable = M.applicable_actions(s)
        if not applicable:
            if trace:
                print(f"{t:2d}| <NO-APPLICABLE>")
                if trace_sink:
                    trace_sink.write(
                        json.dumps(
                            {
                                "episode": episode_id,
                                "t": t,
                                "event": "noapp",
                                "state": s,
                            }
                        )
                        + "\n"
                    )
            return ("timeout", t)

        a = pi.act(s, applicable)

        succs = M.successors(s, a)
        s2 = random.choice(succs)

        if trace:
            print(f"{t:2d}| {a}")
            print(f"{t}| <state>  | {snap(s)}")
            if trace_sink:
                trace_sink.write(
                    json.dumps(
                        {
                            "episode": episode_id,
                            "t": t,
                            "action": a,
                            "state_before": s,
                            "state_after": s2,
                            "applicable": applicable,
                        }
                    )
                    + "\n"
                )

        s = s2

    if trace:
        print(f"{max_steps:2d}| <TIMEOUT>")
        if trace_sink:
            trace_sink.write(
                json.dumps(
                    {"episode": episode_id, "t": max_steps, "event": "timeout"}
                )
                + "\n"
            )
    return ("timeout", max_steps)


def main(
    jani_file: str,
    property_file: str,
    interface_file: str,
    episodes: int = 50,
    max_steps: int = 200,
    policy_kind: str = "random",
    sym_model: Optional[str] = None,
    trace: bool = False,
    trace_file: Optional[str] = None,
):
    M = load_env(jani_file, property_file)

    if policy_kind in ("random",):
        policy: RandomPolicy | RRLPolicy = RandomPolicy()
    elif policy_kind in ("rrl", "rule-based"):
        if not sym_model:
            raise ValueError("--sym_model is required when --policy rrl")
        adapter = RRLAdapter(var_bounds=M.variables, interface_path=interface_file)
        policy = RRLPolicy(model_path=sym_model, adapter=adapter, eval_mode="compiled")
    else:
        raise ValueError(f"Unknown --policy '{policy_kind}' (use 'random' or 'rrl').")

    stats = {"goal": 0, "unsafe": 0, "timeout": 0, "steps_sum": 0}
    sink = open(trace_file, "w") if (trace and trace_file) else None
    try:
        for ep in range(episodes):
            res, steps = evaluate_episode(
                M,
                policy,
                max_steps=max_steps,
                trace=trace,
                trace_sink=sink,
                episode_id=ep,
            )
            stats[res] += 1
            stats["steps_sum"] += steps
    finally:
        if sink:
            sink.close()

    avg_steps = stats["steps_sum"] / max(1, episodes)
    print(
        f"\n[{policy_kind.upper()} x JANI] episodes={episodes}  "
        f"goal={stats['goal']}  unsafe={stats['unsafe']}  "
        f"timeout={stats['timeout']}  avg_steps={avg_steps:.1f}"
    )


if __name__ == "__main__":
    import argparse

    ap = argparse.ArgumentParser()
    ap.add_argument("--jani", required=True, help="Path to environment .jani (JSON)")
    ap.add_argument(
        "--property", required=True, help="Path to property .jani (start/goal/failure)"
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
    ap.add_argument("--trace", action="store_true", help="Print per-step trace")
    ap.add_argument("--trace-file", help="Write JSONL trace to this file")
    args = ap.parse_args()

    main(
        jani_file=args.jani,
        property_file=args.property,
        interface_file=args.interface,
        episodes=args.episodes,
        max_steps=args.max_steps,
        policy_kind=args.policy,
        sym_model=args.sym_model,
        trace=args.trace,
        trace_file=args.trace_file,
    )
