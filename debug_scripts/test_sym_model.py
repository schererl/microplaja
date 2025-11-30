from __future__ import annotations

from pathlib import Path
import argparse

import numpy as np
import pandas as pd

from jani_environment import load_env
from symbolic_model import SymbolicModel
from model_adapter import RRLAdapter


def vec_to_atom_dict(vec: np.ndarray, atoms: list[str]) -> dict[str, bool]:
    return {atoms[j]: bool(vec[j] == 1.0) for j in range(len(atoms))}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", required=True, help="symbolic model (.json)")
    parser.add_argument("--df", help="raw .data file (optional if using --npz)")
    parser.add_argument("--interface", help=".jani2nnet (optional if using --npz)")
    parser.add_argument("--jani", help=".jani (optional if using --npz)")
    parser.add_argument("--prop", help=".jani property (optional if using --npz)")
    parser.add_argument(
        "--samples", type=int, default=None, help="cap number of evaluated samples"
    )
    parser.add_argument(
        "--npz", help="npz dump with X,y,logits from original env (np.savez)"
    )
    parser.add_argument(
        "--print-rules",
        action="store_true",
        help="print compiled rules and exit",
    )
    args = parser.parse_args()

    sm = SymbolicModel.load(args.model)
    atoms = sm.atoms

    if args.print_rules:
        print(sm.compiled_source(module=True))
        return

    # ------------------------------------------------------------------
    # Path A: verify against original npz dump (X, y, logits)
    # ------------------------------------------------------------------
    if args.npz:
        D = np.load(args.npz)
        X = D["X"]            # (N, n_atoms)
        Y_oh = D["y"]         # (N, n_classes)
        Z_repo = D["logits"]  # (N, n_classes)
        D.close()

        if args.samples is not None and args.samples < len(X):
            X = X[:args.samples]
            Y_oh = Y_oh[:args.samples]
            Z_repo = Z_repo[:args.samples]

        n, d = X.shape
        if d != len(atoms):
            raise RuntimeError(
                f"Atom count mismatch: npz has {d}, model has {len(atoms)}"
            )

        n_classes = Y_oh.shape[1]
        print(f"[npz] N={n}, atoms={d}, classes={n_classes}")

        z_sym_all = np.zeros_like(Z_repo, dtype=np.float32)
        y_true = np.argmax(Y_oh, axis=1)
        y_pred_repo = np.argmax(Z_repo, axis=1)

        mismatches = 0
        worst = (0.0, -1)

        for i in range(n):
            A = vec_to_atom_dict(X[i], atoms)
            _, _, scores = sm.forward(A)
            z_sym = np.array(
                [scores.get(f"class_{c}", 0.0) for c in range(n_classes)],
                dtype=np.float32,
            )
            z_sym_all[i] = z_sym

            mae = float(np.max(np.abs(z_sym - Z_repo[i])))
            if mae > worst[0]:
                worst = (mae, i)

            if int(np.argmax(z_sym)) != int(y_pred_repo[i]):
                mismatches += 1

        agree = 1.0 - mismatches / n
        acc_sym = float(np.mean(np.argmax(z_sym_all, axis=1) == y_true))
        acc_repo = float(np.mean(y_pred_repo == y_true))

        print(
            f"[cmp] repo_acc={acc_repo:.4f}  "
            f"sym_acc={acc_sym:.4f}  "
            f"pred_agreement={agree:.4f}"
        )
        print(
            f"[cmp] worst per-sample |logits_sym - logits_repo|_inf = "
            f"{worst[0]:.6g} at i={worst[1]}"
        )

        if mismatches:
            i = worst[1]
            print("\n[first-diff sample diagnostics]")
            print(
                f"  index: {i}, "
                f"y_true={y_true[i]}, "
                f"repo_pred={y_pred_repo[i]}, "
                f"sym_pred={int(np.argmax(z_sym_all[i]))}"
            )
            diffs = np.abs(z_sym_all[i] - Z_repo[i])
            topk = np.argsort(-diffs)[:5]
            print("  top-5 class diffs (cls: sym, repo, |Δ|):")
            for c in topk:
                print(
                    f"    {c}: "
                    f"{z_sym_all[i][c]:.6f}, "
                    f"{Z_repo[i][c]:.6f}, "
                    f"{diffs[c]:.6f}"
                )

        return

    # ------------------------------------------------------------------
    # Path B: original .data + JANI + interface
    # ------------------------------------------------------------------
    if not (args.df and args.interface and args.jani and args.prop):
        raise SystemExit(
            "Either --npz or all of --df/--interface/--jani/--prop must be provided."
        )

    M = load_env(args.jani, args.prop)
    adapter = RRLAdapter(var_bounds=M.variables, interface_path=args.interface)

    df = pd.read_csv(Path(args.df), header=None)
    if args.samples is not None:
        k = max(0, min(int(args.samples), len(df)))
        if k < len(df):
            print(
                f"[info] --samples={args.samples} -> "
                f"evaluating first {k} of {len(df)} rows"
            )
        df = df.iloc[:k].copy()

    Xraw = df.iloc[:, :-1].astype(int).values
    y = df.iloc[:, -1].astype(int).values
    n = len(Xraw)
    preds = np.empty(n, dtype=int)
    correct = 0

    for i in range(n):
        proxy_state = {
            adapter.input_names[j]: int(Xraw[i][j])
            for j in range(len(adapter.input_names))
        }
        A = adapter.encode(proxy_state)
        _, _, scores = sm.forward(A)
        best_label = max(scores, key=scores.get)
        pred_idx = int(best_label.split("_", 1)[1])
        preds[i] = pred_idx
        if pred_idx == int(y[i]):
            correct += 1

    acc = correct / n if n else 0.0
    print(f"correct={correct} / {n}  accuracy={acc:.4f}")

    labels, counts = np.unique(y, return_counts=True)
    pred_labels, pred_counts = (
        np.unique(preds, return_counts=True) if n else ([], [])
    )
    print(
        "labels_counts:",
        {int(k): int(v) for k, v in zip(labels, counts)},
    )
    print(
        "predicted_counts:",
        {int(k): int(v) for k, v in zip(pred_labels, pred_counts)},
    )


if __name__ == "__main__":
    main()
 