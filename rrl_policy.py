# Policy: transforms raw state -> atoms via adapter, calls SymbolicModel.
from __future__ import annotations

from pathlib import Path as _Path
from typing import Any, Dict, List, Union

from symbolic_model import SymbolicModel
from model_adapter import ModelAdapter


class RRLPolicy:
    def __init__(
        self,
        model_path: Union[str, _Path],
        adapter: ModelAdapter,
        eval_mode: str = "compiled",  # "lazy" or "compiled"
    ) -> None:
        self.model = SymbolicModel.load(model_path)
        self.adapter = adapter
        self.eval_mode = eval_mode

    def _forward(self, atoms: Dict[str, bool]):
        if self.eval_mode == "lazy":
            return self.model.lazy_forward(atoms)
        if self.eval_mode == "compiled":
            return self.model.compiled_forward(atoms)
        raise ValueError(f"Unsupported eval_mode: {self.eval_mode}")

    def act(self, state: Dict[str, Any], applicable: List[str]) -> str:
        atoms = self.adapter.encode(state)
        _, _, scores = self._forward(atoms)

        for lbl in sorted(scores, key=scores.get, reverse=True):
            act = self.adapter.decode(lbl)
            if act in applicable:
                return act

        if not applicable:
            raise RuntimeError("No applicable actions to choose from.")
        return applicable[0]
