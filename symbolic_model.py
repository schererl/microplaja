# symbolic_model.py
# Load a symbolic rule model from JSON and evaluate it using compiled Python code.

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Callable, Dict, List, Tuple, Union

Json = Dict[str, Any]


class SymbolicModel:
    def __init__(
        self,
        atoms: List[str],
        rules: Dict[str, Any],
        linear_weights: Dict[str, Dict[str, float]],
        linear_bias: Dict[str, float],
        topo_layers: List[List[str]],
        compiled_funcs: Dict[str, Callable[[Dict[str, bool], Dict[str, bool]], bool]],
        compiled_src_per_rule: Dict[str, str],
        compiled_module_src: str,
    ) -> None:
        self.atoms = atoms
        self.rules = rules
        self.linear_weights = linear_weights
        self.linear_bias = linear_bias
        self.topo_layers = topo_layers

        self._compiled_funcs = compiled_funcs
        self._compiled_src_per_rule = compiled_src_per_rule
        self._compiled_module_src = compiled_module_src

    # ----------------------------------------------------------------------
    # Loading
    # ----------------------------------------------------------------------
    @classmethod
    def load(cls, path: Union[str, Path]) -> "SymbolicModel":
        obj: Json = json.loads(Path(path).read_text())

        atoms = list(obj.get("atoms", []))
        if not atoms:
            raise ValueError("Model has empty 'atoms'.")

        rules = obj.get("rules", {})
        if not isinstance(rules, dict):
            raise ValueError("Expected 'rules' to be a dict in the JSON.")

        linear = obj.get("linear", {})
        weights = linear.get("weights", {})
        bias = linear.get("bias", {})
        if not weights or not bias:
            raise ValueError("Model is missing 'linear.weights' or 'linear.bias'.")

        topo_layers = _build_topo_layers(rules)
        funcs, src_per_rule, module_src = _compile_rule_funcs_with_src(rules)

        return cls(
            atoms=atoms,
            rules=rules,
            linear_weights=weights,
            linear_bias=bias,
            topo_layers=topo_layers,
            compiled_funcs=funcs,
            compiled_src_per_rule=src_per_rule,
            compiled_module_src=module_src,
        )

    # ----------------------------------------------------------------------
    # Evaluation (compiled)
    # ----------------------------------------------------------------------
    def forward(
        self, atom_values: Dict[str, bool]
    ) -> Tuple[Dict[str, bool], Dict[str, bool], Dict[str, float]]:
        """
        Evaluate all rules and return:
            rule_values: rule_name -> bool
            last_vals:   values of rules in the last layer
            class_scores: class_name -> float
        """
        _validate_atoms(self.atoms, atom_values)

        rule_values: Dict[str, bool] = {}
        last_layer: List[str] = []

        for layer in self.topo_layers:
            last_layer = layer
            for rname in layer:
                fn = self._compiled_funcs[rname]
                rule_values[rname] = fn(atom_values, rule_values)

        last_vals = {name: bool(rule_values.get(name, False)) for name in last_layer}
        class_scores = _linear_scores(last_vals, self.linear_weights, self.linear_bias)
        return rule_values, last_vals, class_scores

    # ----------------------------------------------------------------------
    # Introspection
    # ----------------------------------------------------------------------
    def compiled_source(self, rule_name: str | None = None, *, module: bool = False) -> str:
        if module:
            return self._compiled_module_src
        if rule_name is None:
            raise ValueError("Provide rule_name or set module=True.")
        if rule_name not in self._compiled_src_per_rule:
            raise KeyError(f"No compiled source captured for rule '{rule_name}'.")
        return self._compiled_src_per_rule[rule_name]

    def dump_compiled(self, path: Union[str, Path], *, module: bool = True) -> None:
        text = self._compiled_module_src if module else "\n\n".join(
            self._compiled_src_per_rule.values()
        )
        Path(path).write_text(text)


# ----------------------------------------------------------------------
# Helpers
# ----------------------------------------------------------------------
def _validate_atoms(declared: List[str], provided: Dict[str, bool]) -> None:
    missing = [a for a in declared if a not in provided]
    if missing:
        raise KeyError(f"Missing truth values for atoms: {missing}")


def _linear_scores(
    last_vals: Dict[str, bool],
    weights: Dict[str, Dict[str, float]],
    bias: Dict[str, float],
) -> Dict[str, float]:
    class_scores: Dict[str, float] = {}
    for clazz, wmap in weights.items():
        score = float(bias.get(clazz, 0.0))
        for feat, w in wmap.items():
            v = 1.0 if last_vals.get(feat, False) else 0.0
            score += w * v
        class_scores[clazz] = score
    return class_scores


def _extract_layer_index(rule_name: str) -> int:
    if not rule_name.startswith("L"):
        raise ValueError(f"Rule name '{rule_name}' must start with 'L'.")
    head, _ = rule_name.split("_", 1)
    return int(head[1:])


def _rule_index_key(rule_name: str) -> Tuple[int, int]:
    try:
        _, idx = rule_name.split("_", 1)
        return (_extract_layer_index(rule_name), int(idx))
    except Exception:
        return (_extract_layer_index(rule_name), 0)


def _build_topo_layers(rules: Dict[str, Any]) -> List[List[str]]:
    by_layer: Dict[int, List[str]] = {}
    for rname in rules.keys():
        layer = _extract_layer_index(rname)
        by_layer.setdefault(layer, []).append(rname)
    # sort layers by index, and rules in each layer by (layer, local_index)
    return [sorted(by_layer[k], key=_rule_index_key) for k in sorted(by_layer.keys())]


# ----------------------------------------------------------------------
# Compilation: expr -> Python code -> functions
# ----------------------------------------------------------------------
def _expr_to_py(node: Any) -> str:
    if isinstance(node, bool):
        return "True" if node else "False"

    if isinstance(node, str):
        # Atom if present in A, otherwise it MUST be a rule already computed in R.
        # If it's missing from R, this raises KeyError -> signals wrong order or missing rule.
        return f"(A[{node!r}] if {node!r} in A else R[{node!r}])"

    if not isinstance(node, dict):
        raise ValueError(f"Invalid expr node: {node!r}")

    if "ref" in node:
        ref = str(node["ref"])
        if node.get("neg"):
            return f"(not R[{ref!r}])"
        return f"R[{ref!r}]"

    if "NOT" in node:
        inner = _expr_to_py(node["NOT"])
        return f"(not ({inner}))"

    if "AND" in node:
        terms = node["AND"]
        if not isinstance(terms, list):
            raise ValueError("AND expects a list.")
        if not terms:
            return "True"
        return "(" + " and ".join(_expr_to_py(t) for t in terms) + ")"

    if "OR" in node:
        terms = node["OR"]
        if not isinstance(terms, list):
            raise ValueError("OR expects a list.")
        if not terms:
            return "False"
        return "(" + " or ".join(_expr_to_py(t) for t in terms) + ")"

    raise ValueError(f"Unknown expr form: {node!r}")


def _compile_rule_funcs_with_src(
    rules: Dict[str, Any],
) -> Tuple[
    Dict[str, Callable[[Dict[str, bool], Dict[str, bool]], bool]],
    Dict[str, str],
    str,
]:
    env: Dict[str, Any] = {}
    per_rule_src: Dict[str, str] = {}
    code_lines: List[str] = []

    def _sort_key(name: str) -> Tuple[int, int, str]:
        L = _extract_layer_index(name)
        _, idx = name.split("_", 1)
        return (L, int(idx), name)

    for rname in sorted(rules.keys(), key=_sort_key):
        rexpr = rules[rname]
        py_expr = _expr_to_py(rexpr)
        fn_name = f"_rule_{rname}"
        src = f"def {fn_name}(A, R):\n    return bool({py_expr})\n"
        per_rule_src[rname] = src
        code_lines.append(src)

    module_src = "\n".join(code_lines)
    exec(module_src, env, env)

    funcs: Dict[str, Callable[[Dict[str, bool], Dict[str, bool]], bool]] = {}
    for rname in rules.keys():
        funcs[rname] = env[f"_rule_{rname}"]

    return funcs, per_rule_src, module_src
