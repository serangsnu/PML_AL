"""Training, inference, and BPSO utilities for bit-size dependent CNN models.

This module is intended to be used together with ``CNN_class.py``.
The CNN architecture itself is defined in ``CNN_class.SimplifiedCNN``;
this file only contains helper functions for training, prediction, and
Binary Particle Swarm Optimization (BPSO).

Supported input bit sizes are 17, 19, 21, 23, 25, 30, 35, 40, 45, and 50.
"""

from __future__ import annotations

import time
from pathlib import Path
from typing import Dict, Mapping, Optional, Tuple, Union

import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim

from CNN_class import SimplifiedCNN


ArrayLike = Union[np.ndarray, torch.Tensor]
PathLike = Union[str, Path]


# -----------------------------------------------------------------------------
# BPSO hyperparameters by input bit size
# -----------------------------------------------------------------------------

BPSO_CONFIGS: Dict[int, Dict[str, object]] = {
    17: {
        "iters": 2**7,
        "n_particles": 2**5,
        "options": {"c1": 0.5, "c2": 0.3, "w": 0.9, "k": 9, "p": 1},
    },
    19: {
        "iters": 2**8,
        "n_particles": 2**5,
        "options": {"c1": 0.5, "c2": 0.3, "w": 0.9, "k": 9, "p": 1},
    },
    21: {
        "iters": 2**9,
        "n_particles": 2**6,
        "options": {"c1": 0.5, "c2": 0.3, "w": 0.9, "k": 9, "p": 1},
    },
    23: {
        "iters": 2**10,
        "n_particles": 2**6,
        "options": {"c1": 0.5, "c2": 0.3, "w": 0.9, "k": 9, "p": 1},
    },
    25: {
        "iters": 2**13,
        "n_particles": 2**6,
        "options": {"c1": 0.5, "c2": 0.3, "w": 0.9, "k": 9, "p": 1},
    },
    30: {
        "iters": 2**13,
        "n_particles": 2**6,
        "options": {"c1": 0.5, "c2": 0.3, "w": 0.9, "k": 9, "p": 1},
    },
    35: {
        "iters": 2**13,
        "n_particles": 2**6,
        "options": {"c1": 0.5, "c2": 0.3, "w": 0.9, "k": 9, "p": 1},
    },
    40: {
        "iters": 2**13,
        "n_particles": 2**6,
        "options": {"c1": 0.5, "c2": 0.3, "w": 0.9, "k": 9, "p": 1},
    },
    45: {
        "iters": 2**13,
        "n_particles": 2**6,
        "options": {"c1": 0.5, "c2": 0.3, "w": 0.9, "k": 9, "p": 1},
    },
    50: {
        "iters": 2**13,
        "n_particles": 2**6,
        "options": {"c1": 0.5, "c2": 0.3, "w": 0.9, "k": 9, "p": 1},
    },
}


# -----------------------------------------------------------------------------
# Basic helpers
# -----------------------------------------------------------------------------


def get_device(device: Optional[Union[str, torch.device]] = None) -> torch.device:
    """Return a torch device.

    If ``device`` is not given, CUDA is used when available; otherwise CPU is used.
    """
    if device is not None:
        return torch.device(device)
    return torch.device("cuda" if torch.cuda.is_available() else "cpu")



def get_model_path(filename: str, model_dir: PathLike = ".", k: int = 0) -> Path:
    """Return the checkpoint path used by the original code convention."""
    return Path(model_dir) / f"{filename}_k{k}_model.pt"



def _check_supported_bit(input_bit: int) -> None:
    if input_bit not in SimplifiedCNN.supported_bits():
        supported = ", ".join(map(str, SimplifiedCNN.supported_bits()))
        raise ValueError(
            f"Unsupported input bit size: {input_bit}. "
            f"Supported values are: {supported}."
        )



def _infer_input_bit(sample_x: ArrayLike, input_bit: Optional[int] = None) -> int:
    """Infer input bit size from sample data unless it is explicitly provided."""
    if input_bit is not None:
        input_bit = int(input_bit)
        _check_supported_bit(input_bit)
        return input_bit

    shape = tuple(sample_x.shape)
    if len(shape) == 2:
        inferred_bit = shape[1]
    elif len(shape) == 3:
        inferred_bit = shape[-1]
    else:
        raise ValueError(
            "Cannot infer input bit size. Expected sample_x shape "
            "(n_samples, input_bit) or (n_samples, 1, input_bit)."
        )

    _check_supported_bit(inferred_bit)
    return int(inferred_bit)



def _to_float_tensor(data: ArrayLike, device: torch.device) -> torch.Tensor:
    """Convert numpy array or tensor to float32 tensor on the selected device."""
    if isinstance(data, torch.Tensor):
        return data.detach().clone().float().to(device)
    return torch.as_tensor(data, dtype=torch.float32, device=device)



def load_simplified_cnn(
    filename: str,
    input_bit: int,
    model_dir: PathLike = ".",
    k: int = 0,
    device: Optional[Union[str, torch.device]] = None,
) -> SimplifiedCNN:
    """Load a trained ``SimplifiedCNN`` checkpoint."""
    device = get_device(device)
    _check_supported_bit(input_bit)

    model = SimplifiedCNN(input_bit=input_bit).to(device)
    model_path = get_model_path(filename, model_dir=model_dir, k=k)
    state_dict = torch.load(model_path, map_location=device)
    model.load_state_dict(state_dict)
    model.eval()
    return model


# -----------------------------------------------------------------------------
# Training and inference functions
# -----------------------------------------------------------------------------


def nn_fc(
    layer: int,
    sample_x,
    sample_y,
    filename: str,
    *,
    lr: float = 1e-5,
    num_epochs: int = 7000,
    early_stop_patience: int = 500,
    validation_interval: int = 1,
    model_dir: PathLike = ".",
    log_dir: PathLike = ".",
    k: int = 0,
    device: Optional[Union[str, torch.device]] = None,
    verbose: bool = True,
) -> Tuple[float, int]:
    """Train a ``SimplifiedCNN`` model and save the best checkpoint.

    Parameters
    ----------
    layer : int
        Input data size in bits. This value selects the CNN architecture.
    sample_x : iterable
        Training DataLoader or any iterable returning ``(batch_x, batch_y)``.
    sample_y : iterable
        Validation DataLoader or any iterable returning ``(valid_x, valid_y)``.
    filename : str
        Prefix of the saved model file. The checkpoint is saved as
        ``{filename}_k{k}_model.pt``.

    Returns
    -------
    tuple[float, int]
        Best validation loss and the epoch at which it was achieved.
    """
    input_bit = int(layer)
    _check_supported_bit(input_bit)

    if validation_interval < 1:
        raise ValueError("validation_interval must be greater than or equal to 1.")

    device = get_device(device)
    model_dir = Path(model_dir)
    log_dir = Path(log_dir)
    model_dir.mkdir(parents=True, exist_ok=True)
    log_dir.mkdir(parents=True, exist_ok=True)

    model = SimplifiedCNN(input_bit=input_bit).to(device)
    optimizer = optim.Adam(model.parameters(), lr=lr)
    criterion = nn.MSELoss()

    best_val_loss = float("inf")
    best_epoch = 0
    early_stop_count = 0
    model_path = get_model_path(filename, model_dir=model_dir, k=k)

    start_time = time.time()

    for epoch in range(1, num_epochs + 1):
        model.train()
        for batch_x, batch_y in sample_x:
            batch_x = batch_x.float().to(device)
            batch_y = batch_y.float().to(device).view(-1, 1)

            optimizer.zero_grad()
            prediction = model(batch_x)
            loss = criterion(prediction, batch_y)
            loss.backward()
            optimizer.step()

        if epoch % validation_interval != 0 and epoch != num_epochs:
            continue

        model.eval()
        total_val_loss = 0.0
        total_val_samples = 0

        with torch.no_grad():
            for valid_x, valid_y in sample_y:
                valid_x = valid_x.float().to(device)
                valid_y = valid_y.float().to(device).view(-1, 1)

                valid_prediction = model(valid_x)
                valid_loss = criterion(valid_prediction, valid_y)

                batch_size = valid_x.size(0)
                total_val_loss += valid_loss.item() * batch_size
                total_val_samples += batch_size

        if total_val_samples == 0:
            raise ValueError("Validation loader contains no samples.")

        val_loss = total_val_loss / total_val_samples

        if val_loss < best_val_loss:
            best_val_loss = val_loss
            best_epoch = epoch
            early_stop_count = 0
            torch.save(model.state_dict(), model_path)
        else:
            early_stop_count += 1

        if early_stop_count >= early_stop_patience:
            break

    elapsed_time = time.time() - start_time

    with open(log_dir / f"_train_time_{filename}.txt", "a", encoding="utf-8") as f:
        f.write(f"{elapsed_time}\n")

    with open(log_dir / f"_out_of_validation_loss_{filename}.txt", "a", encoding="utf-8") as f:
        f.write(f"{best_val_loss}\n")

    if verbose:
        print(f"epoch : {best_epoch}")
        print(f"validation_loss : {best_val_loss}")

    return best_val_loss, best_epoch



def nn_fc_output(
    sample_x: ArrayLike,
    filename: str,
    *,
    layer: Optional[int] = None,
    model_dir: PathLike = ".",
    k: int = 0,
    device: Optional[Union[str, torch.device]] = None,
) -> torch.Tensor:
    """Predict FOM values using a trained ``SimplifiedCNN`` model.

    ``sample_x`` may have shape ``(n_samples, input_bit)`` or
    ``(n_samples, 1, input_bit)``.
    """
    input_bit = _infer_input_bit(sample_x, input_bit=layer)
    device = get_device(device)

    sample_x_tensor = _to_float_tensor(sample_x, device=device)
    model = load_simplified_cnn(
        filename=filename,
        input_bit=input_bit,
        model_dir=model_dir,
        k=k,
        device=device,
    )

    with torch.no_grad():
        predictions = model(sample_x_tensor).view(-1)

    return predictions



def nn_fc_output_bpso(
    sample_x: ArrayLike,
    *,
    filename: str = "this_is_test_file",
    layer: Optional[int] = None,
    model_dir: PathLike = ".",
    k: int = 0,
    device: Optional[Union[str, torch.device]] = None,
) -> np.ndarray:
    """Objective function for BPSO.

    PySwarms passes a binary matrix with shape ``(n_particles, dimensions)``.
    This function returns predicted FOM values as a NumPy array.
    """
    predictions = nn_fc_output(
        sample_x=sample_x,
        filename=filename,
        layer=layer,
        model_dir=model_dir,
        k=k,
        device=device,
    )
    return predictions.detach().cpu().numpy()


# -----------------------------------------------------------------------------
# BPSO optimization
# -----------------------------------------------------------------------------


def get_bpso_config(layer: int) -> Dict[str, object]:
    """Return BPSO hyperparameters for the given input bit size."""
    input_bit = int(layer)
    if input_bit not in BPSO_CONFIGS:
        supported = ", ".join(map(str, sorted(BPSO_CONFIGS)))
        raise ValueError(
            f"Unsupported BPSO bit size: {input_bit}. "
            f"Supported values are: {supported}."
        )

    config = BPSO_CONFIGS[input_bit]
    return {
        "iters": int(config["iters"]),
        "n_particles": int(config["n_particles"]),
        "options": dict(config["options"]),
    }



def BPSO_Opt(
    layer: int,
    *,
    filename: str = "this_is_test_file",
    model_dir: PathLike = ".",
    k: int = 0,
    device: Optional[Union[str, torch.device]] = None,
    verbose: bool = False,
) -> Tuple[float, np.ndarray]:
    """Run Binary Particle Swarm Optimization for the selected bit size.

    The number of iterations and particles are selected automatically from
    ``BPSO_CONFIGS`` according to ``layer``.
    """
    input_bit = int(layer)
    config = get_bpso_config(input_bit)

    try:
        from pyswarms.discrete import binary as bi
    except ImportError as exc:
        raise ImportError(
            "BPSO_Opt requires pyswarms. Install it with: pip install pyswarms"
        ) from exc

    optimizer = bi.BinaryPSO(
        n_particles=config["n_particles"],
        dimensions=input_bit,
        options=config["options"],
    )

    objective_function = lambda x: nn_fc_output_bpso(
        x,
        filename=filename,
        layer=input_bit,
        model_dir=model_dir,
        k=k,
        device=device,
    )

    cost, pos = optimizer.optimize(
        objective_function,
        iters=config["iters"],
        verbose=verbose,
    )

    early_stop_iter = len(optimizer.cost_history)

    print(f"BPSO_epoch : {early_stop_iter}")
    print(f"BPSO_output_values : {cost}")

    return cost, pos


__all__ = [
    "BPSO_CONFIGS",
    "BPSO_Opt",
    "get_bpso_config",
    "get_device",
    "get_model_path",
    "load_simplified_cnn",
    "nn_fc",
    "nn_fc_output",
    "nn_fc_output_bpso",
]
