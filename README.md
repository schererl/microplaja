# microPlaJa

microPlaJa is a small Python environment built on top of PlaJa for testing policies on planning problems described in **JANI**.

At the moment, it focuses on **rule-based policies** exported from an interpretable model (RRL-style). The model is represented in three layers:

- **Binarization layer**
- **Logical layer** (rules)
- **Linear layer** (class scores)

The logical + linear part is exported as a JSON **symbolic model**, which microPlaJa executes symbolically.

Our goal is to use these policies in the **Policy Debugging loop** developed in the FAI group.

> The model we use comes from  
> *“Learning Interpretable Rules for Scalable Data Representation and Classification”* (Wang, 2014).  
> We do **not** use the original code directly: it was modified to export the model as JSON.

Future work: add **neural network policies** (e.g. `.pth`) using the same interface mechanism.

---

## Architecture (short)

- `symbolic_model.py`  
  Loads a symbolic model from JSON and compiles each rule to Python code.  
  Main API:  
  ```python
  sm = SymbolicModel.load("sym_model.json")
  rule_vals, last_vals, class_scores = sm.forward(atom_assignment)
  ```

- `model_adapter.py`  
  Adapters that map **JANI states ↔ model input / output**.
  - `RRLAdapter`: encodes JANI state into atoms for the symbolic rule model and decodes `class_k` → action name.
  - `NNAdapter`: same idea, but produces a bit-vector suitable for NNs (planned).

- `runner.py`  
  Wraps a JANI environment + a policy (`RandomPolicy` or `RRLPolicy`) into episodes.

---

## Installation

Create and use a project-local virtual environment:

```bash
chmod +x setup_env.sh
./setup_env.sh

# then
source .venv/bin/activate
python runner.py --help
```

### Requirements (main)

```text
numpy>=1.26
torch>=2.2
z3-solver>=4.12
pandas>=2.0
```

PyTorch is installed in **CPU** mode by default.

For CUDA (example: CUDA 12.1) inside the venv:

```bash
pip uninstall -y torch
pip install --index-url https://download.pytorch.org/whl/cu121 torch
```

---

## Running the environment (runner)

Entry point: `runner.py`

```bash
python3 runner.py --jani PATH/your_env.jani --property PATH/your_prop.jani --interface PATH/your_interface.jani2nnet --policy rrl --sym_model PATH/sym_model.json
```

### CLI arguments

- `--jani` (required): JANI model of the environment.
- `--property` (required): JANI property file (start / goal / unsafe).
- `--interface` (required for `rrl`): `jani2nnet` JSON mapping JANI vars to model input/output.
- `--policy`:
  - `random` (default): random applicable action.
  - `rrl` / `rule-based`: symbolic rule model.
- `--sym_model`: path to symbolic model JSON (required if `--policy rrl`).
- `--episodes`: number of episodes (default: 10).
- `--max_steps`: max steps per episode (default: 100).
- `--trace`: print step-by-step trace.
- `--trace-file`: write a JSONL trace.

Internals:

- `runner.py` builds a `JaniEnvironment` via `load_env(...)`.
- For `rrl`, it builds:
  - `RRLAdapter(var_bounds=M.variables, interface_path=interface_file)`
  - `RRLPolicy(model_path=sym_model, adapter=adapter)`

---

## Testing the symbolic model

Debug scripts live in `debug_scripts/`.

### 1) Compare with original RRL logits (`.npz`)

```bash
python3 -m debug_scripts.test_sym_model --model example/sym_model.json --npz example/pred_dump.npz
```

This:

- Evaluates the symbolic model on the same atom matrix used in RRL.
- Compares logits and predictions with the original RRL model:
  - `repo_acc`: accuracy of original RRL.
  - `sym_acc`: accuracy of symbolic model.
  - `pred_agreement`: fraction of samples where argmax matches.

The accuracy is ~97% and agreement ~100%; if is not ~100% something is wrong with the export or microPlaJa.


### 2) Evaluate from `.data` + JANI + interface

```bash
python3 -m debug_scripts.test_sym_model --model example/sym_model.json --df example/one_way_line_15_10_det.data  --interface example/one_way_line_15_10_128_128.jani2nnet --jani example/one_way_line_15_10.jani --prop example/pa_one_way_line_15_10_random_starts_1000.jani
```
This:

- Parses the `.data` file.
- Uses `RRLAdapter` to encode rows into atoms.
- Runs `SymbolicModel.forward` and computes accuracy.

### 3) Inspect compiled rules

```bash
python3 -m debug_scripts.test_sym_model --model example/sym_model.json --print-rules
```

Prints the compiled Python functions for all rules (for debugging / inspection).

---

## File overview

- `jani_parser.py` – Z3-based JANI semantics + property handling.
- `jani_environment.py` – Environment wrapper, exposes `load_env(...)`.
- `symbolic_model.py` – Symbolic rule model loading + compiled evaluation.
- `model_adapter.py` – Encoders/decoders between JANI states and model input/output.
- `rrl_policy.py` – Policy that uses `SymbolicModel` + `RRLAdapter`.
- `runner.py` – Main CLI to run policies on JANI environments.
- `debug_scripts/test_sym_model.py` – Utilities to test and debug symbolic models.
- `setup_env.sh` – Helper script to create `.venv` and install dependencies.

---

## Troubleshooting (short)

- **Imports fail**  
  Make sure the venv is active: `source .venv/bin/activate`.

- **Atom / dimension mismatch**  
  Check that:
  - `atoms` in `sym_model.json`,
  - the `jani2nnet` interface, and
  - any `.npz` or `.data` files  
  all match the same encoding.

- **Actions not found**  
  Action names produced by the model must match the JANI labels (`applicable_actions` in `JaniEnvironment`).
