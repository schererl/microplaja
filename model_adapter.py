from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Tuple, Union, Sequence
import json


class ModelAdapter:
    def encode(self, state: Dict[str, Any]) -> Any:
        raise NotImplementedError

    def decode(self, pred: Any) -> str:
        raise NotImplementedError

@dataclass
class RRLAdapter(ModelAdapter):
    var_bounds: Union[Dict[str, Tuple[int, int]], List[Tuple[str, int, int]]]
    interface_path: Union[str, Path]

    def __post_init__(self) -> None:
        if isinstance(self.var_bounds, dict):
            self.bounds: Dict[str, Tuple[int, int]] = self.var_bounds
        else:
            self.bounds = {name: (lo, hi) for name, lo, hi in self.var_bounds}

        p = Path(self.interface_path)
        obj = json.loads(p.read_text(encoding="utf-8"))
        if "input" not in obj or "output" not in obj:
            raise ValueError(f"{p} must contain 'input' and 'output' fields")

        self.input_names: List[str] = [x["name"] for x in obj["input"]]
        self.outputs: List[str] = list(obj["output"])

        self.bstate_map: Dict[Tuple[str, int], str] = {}
        self.bstate_size = 0
        for i, nm in enumerate(self.input_names):
            lo, hi = self.bounds[nm]
            for val in range(int(lo) + 1, int(hi) + 1):
                self.bstate_map[(nm, int(val))] = f"{i}_{val}"
                self.bstate_size += 1

        self._class_to_action: Dict[str, str] = {
            f"class_{k}": act for k, act in enumerate(self.outputs)
        }

    def encode(self, state: Dict[str, Any]) -> Dict[str, bool]:
        A = {bs: False for bs in self.bstate_map.values()}
        for i, nm in enumerate(self.input_names):
            val = int(state[nm])
            if self.bounds[nm][0] != val:
                bstate_key = self.bstate_map[(nm, val)]
                A[bstate_key] = True
        return A

    def decode(self, pred: Any) -> str:
        class_label = str(pred)
        if class_label not in self._class_to_action:
            raise KeyError(f"Unknown class label '{class_label}'.")
        return self._class_to_action[class_label]


@dataclass
class NNAdapter(ModelAdapter):
    var_bounds: Union[Dict[str, Tuple[int, int]], List[Tuple[str, int, int]]]
    interface_path: Union[str, Path]

    def __post_init__(self) -> None:
        pass

    def encode(self, state: Dict[str, Any]) -> List[float]:
        pass

    def decode(self, pred: Any) -> str:
        pass
