"""Active learning process for CNN-surrogate-based binary optimization.

Pipeline
--------
1. Read ``dataset_<filename>.txt``.
2. Train the bit-size dependent CNN surrogate model.
3. Select the next binary candidate using BPSO or brute force.
4. Evaluate the selected candidate using a MATLAB FOM function.
5. Append the new result to ``dataset_<filename>.txt``.
6. Save progress logs such as FOM, RMS, and iteration time.

This script is designed to work with:
- ``CNN_class.py``: defines ``SimplifiedCNN(input_bit=...)``
- ``nn_fc.py`` or ``cnn_surrogate_utils.py``: defines ``nn_fc``, ``nn_fc_output``, and ``BPSO_Opt``
- ``matlab_file_import.py``: defines ``mfi`` and optionally ``save_batch_to_txt``

Example
-------
python active_learning_process.py --filename this_is_test_file --layer 25 --iterations 1000 --optimizer bpso
python active_learning_process.py --filename this_is_test_file --layer 25 --iterations 1000 --optimizer bf
"""

from __future__ import annotations

import argparse
import os
import random
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import List, Optional, Tuple

import numpy as np
import torch
from torch.utils.data import DataLoader, TensorDataset, random_split
from tqdm import tqdm

from matlab_file_import import mfi, save_batch_to_txt
try:
    from cnn_surrogate_utils import BPSO_Opt, get_device, load_simplified_cnn, nn_fc, nn_fc_output
except ImportError:
    from nn_fc import BPSO_Opt, get_device, load_simplified_cnn, nn_fc, nn_fc_output


SUPPORTED_BITS = (17, 19, 21, 23, 25, 30, 35, 40, 45, 50)


@dataclass
class ActiveLearningConfig:
    """Configuration for the active learning loop."""

    filename: str = "this_is_test_file"
    layer: int = 25
    iterations: int = 1000
    optimizer: str = "bpso"  # "bpso", "bf", or "brute_force"

    # Dataset / dataloader
    validation_ratio: float = 0.2
    train_batch_size: int = 1024
    validation_batch_size: int = 256
    drop_last_large_train: bool = True
    drop_last_large_validation: bool = True

    # Reproducibility
    seed: int = 101

    # MATLAB FOM evaluation
    matlab_function_name: str = "IRAR_TRC_test_script"
    start_matlab: bool = True

    # File outputs
    work_dir: Path = Path(".")
    model_dir: Path = Path(".")
    log_dir: Path = Path(".")
    save_split_files: bool = True
    remove_model_after_iteration: bool = True
    save_final_plots: bool = True

    # Brute-force search
    # junk_width=15 means each junk file contains 2**15 binary candidates.
    brute_force_junk_width: int = 15
    brute_force_junk_dir: Path = Path(".")
    brute_force_batch_size: int = 2**15
    reuse_junk_files: bool = True
    skip_existing_candidates: bool = True


# -----------------------------------------------------------------------------
# Basic utilities
# -----------------------------------------------------------------------------


def seed_everything(seed: int = 101) -> None:
    """Set random seeds for reproducible data splitting and model training."""
    random.seed(seed)
    os.environ["PYTHONHASHSEED"] = str(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed(seed)
        torch.cuda.manual_seed_all(seed)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False



def _as_2d_array(data: np.ndarray) -> np.ndarray:
    """Ensure that loaded text data is treated as a 2D array."""
    data = np.asarray(data)
    if data.ndim == 1:
        data = data.reshape(1, -1)
    return data



def _write_row(path: Path, row: np.ndarray, mode: str = "a") -> None:
    """Write one numeric row to a text file."""
    row = np.asarray(row).reshape(-1)
    with open(path, mode, encoding="utf-8") as f:
        f.write(" ".join(map(str, row)))
        f.write("\n")



def _checkpoint_path(filename: str, model_dir: Path, k: int = 0) -> Path:
    return model_dir / f"{filename}_k{k}_model.pt"



def _validate_layer(layer: int) -> None:
    if layer not in SUPPORTED_BITS:
        supported = ", ".join(map(str, SUPPORTED_BITS))
        raise ValueError(f"Unsupported layer={layer}. Supported bits: {supported}.")



def normalize_optimizer_name(optimizer: str) -> str:
    """Normalize optimizer option string."""
    optimizer = optimizer.lower().strip().replace("-", "_")
    if optimizer == "bruteforce":
        optimizer = "brute_force"
    if optimizer == "bf":
        optimizer = "brute_force"
    if optimizer not in {"bpso", "brute_force"}:
        raise ValueError("optimizer must be one of: 'bpso', 'bf', 'brute_force'.")
    return optimizer



def _junk_info(layer: int, junk_width: int) -> Tuple[int, int, int]:
    """Return total candidates, candidates per junk file, and number of junk files."""
    if junk_width < 1:
        raise ValueError("brute_force_junk_width must be greater than or equal to 1.")
    if junk_width > layer:
        raise ValueError("brute_force_junk_width cannot be larger than layer.")

    total_candidates = 2**layer
    candidates_per_junk = 2**junk_width
    total_junks = 2 ** (layer - junk_width)
    return total_candidates, candidates_per_junk, total_junks



def _junk_file_path(
    layer: int,
    chunk_idx: int,
    total_junks: int,
    junk_dir: Path,
    state_number: int = 2,
) -> Path:
    """Return the junk file path following the original naming convention."""
    return junk_dir / f"Lv{state_number}_W{layer}_cJ{chunk_idx + 1}_tJ{total_junks}.npy"



def _generate_binary_chunk(start: int, stop: int, layer: int) -> np.ndarray:
    """Generate binary vectors for integers in [start, stop).

    This keeps the same ordering as the original junk_num.ipynb approach:
    000...0, 000...1, ..., 111...1.
    """
    numbers = np.arange(start, stop, dtype=np.uint64)
    bit_positions = np.arange(layer - 1, -1, -1, dtype=np.uint64)
    return ((numbers[:, None] >> bit_positions) & 1).astype(np.float32)



def ensure_bruteforce_junk_files(config: ActiveLearningConfig) -> None:
    """Create brute-force junk files before the active-learning loop if needed."""
    config.brute_force_junk_dir.mkdir(parents=True, exist_ok=True)

    total_candidates, candidates_per_junk, total_junks = _junk_info(
        config.layer,
        config.brute_force_junk_width,
    )

    print(
        f"Brute-force mode: checking junk files "
        f"(layer={config.layer}, total={total_candidates}, "
        f"chunk_size={candidates_per_junk}, chunks={total_junks})"
    )

    for chunk_idx in tqdm(range(total_junks), desc="Preparing BF junk"):
        path = _junk_file_path(
            config.layer,
            chunk_idx,
            total_junks,
            config.brute_force_junk_dir,
        )

        if config.reuse_junk_files and path.exists():
            continue

        start = chunk_idx * candidates_per_junk
        stop = min(start + candidates_per_junk, total_candidates)
        chunk = _generate_binary_chunk(start, stop, config.layer)

        with open(path, "wb") as f:
            np.save(f, chunk)



def _binary_vectors_to_uint64(vectors: np.ndarray, layer: int) -> np.ndarray:
    """Convert binary vectors to their integer representation."""
    vectors = np.asarray(vectors, dtype=np.uint64)
    powers = np.left_shift(
        np.uint64(1),
        np.arange(layer - 1, -1, -1, dtype=np.uint64),
    )
    return vectors @ powers


# -----------------------------------------------------------------------------
# Dataset and training / candidate selection
# -----------------------------------------------------------------------------


def load_dataset(filename: str, work_dir: Path = Path(".")) -> Tuple[np.ndarray, np.ndarray]:
    """Load ``dataset_<filename>.txt`` and return binary vectors and FOM values."""
    dataset_path = work_dir / f"dataset_{filename}.txt"
    data = _as_2d_array(mfi(str(dataset_path)))

    if data.shape[1] < 2:
        raise ValueError(
            f"{dataset_path} must contain at least 2 columns: FOM and binary vector."
        )

    sample_binary = data[:, 1:].astype(np.float32)
    sample_fom = data[:, 0].reshape(-1, 1).astype(np.float32)
    return sample_binary, sample_fom



def make_dataloaders(
    sample_binary: np.ndarray,
    sample_fom: np.ndarray,
    config: ActiveLearningConfig,
) -> Tuple[DataLoader, DataLoader, TensorDataset, TensorDataset]:
    """Split the dataset into training/validation sets and create dataloaders."""
    if sample_binary.shape[1] != config.layer:
        raise ValueError(
            f"Dataset bit size is {sample_binary.shape[1]}, but config.layer={config.layer}."
        )

    if len(sample_binary) < 2:
        raise ValueError("At least 2 samples are required for train/validation split.")

    x_tensor = torch.from_numpy(sample_binary).float()
    y_tensor = torch.from_numpy(sample_fom).float()
    full_dataset = TensorDataset(x_tensor, y_tensor)

    val_size = int(config.validation_ratio * len(full_dataset))
    val_size = max(1, min(val_size, len(full_dataset) - 1))
    train_size = len(full_dataset) - val_size

    generator = torch.Generator().manual_seed(config.seed)
    train_dataset, val_dataset = random_split(
        full_dataset,
        [train_size, val_size],
        generator=generator,
    )

    train_drop_last = (
        config.drop_last_large_train and len(train_dataset) > config.train_batch_size
    )
    val_drop_last = (
        config.drop_last_large_validation
        and len(val_dataset) > config.validation_batch_size
    )

    train_loader = DataLoader(
        train_dataset,
        batch_size=config.train_batch_size,
        shuffle=False,
        drop_last=train_drop_last,
    )
    val_loader = DataLoader(
        val_dataset,
        batch_size=config.validation_batch_size,
        shuffle=False,
        drop_last=val_drop_last,
    )

    return train_loader, val_loader, train_dataset, val_dataset



def subset_to_numpy(dataset: TensorDataset) -> Tuple[np.ndarray, np.ndarray]:
    """Convert a TensorDataset or torch Subset into numpy arrays."""
    x_list: List[np.ndarray] = []
    y_list: List[np.ndarray] = []

    for x, y in dataset:
        x_list.append(x.numpy())
        y_list.append(y.numpy().reshape(1))

    x_array = np.asarray(x_list, dtype=np.float32)
    y_array = np.asarray(y_list, dtype=np.float32).reshape(-1)
    return x_array, y_array



def save_train_validation_batches(
    train_loader: DataLoader,
    val_loader: DataLoader,
    config: ActiveLearningConfig,
) -> None:
    """Save split batch files using the original helper convention."""
    if not config.save_split_files:
        return

    save_batch_to_txt(train_loader, config.layer, f"train_{config.filename}")
    save_batch_to_txt(val_loader, config.layer, f"cv_{config.filename}")



def brute_force_opt(
    config: ActiveLearningConfig,
    existing_vectors: Optional[np.ndarray] = None,
) -> Tuple[float, np.ndarray]:
    """Select the best candidate by exhaustive surrogate evaluation over junk files.

    The junk files are generated by ``ensure_bruteforce_junk_files`` and follow the
    original naming convention from ``junk_num.ipynb``:
    ``Lv2_W<layer>_cJ<current_junk>_tJ<total_junk>.npy``.
    """
    total_candidates, candidates_per_junk, total_junks = _junk_info(
        config.layer,
        config.brute_force_junk_width,
    )

    device = get_device()
    model = load_simplified_cnn(
        filename=config.filename,
        input_bit=config.layer,
        model_dir=config.model_dir,
        device=device,
    )
    model.eval()

    existing_ids: Optional[np.ndarray] = None
    if config.skip_existing_candidates and existing_vectors is not None:
        existing_ids = np.unique(_binary_vectors_to_uint64(existing_vectors, config.layer))

    best_cost = float("inf")
    best_position: Optional[np.ndarray] = None

    for chunk_idx in tqdm(range(total_junks), desc="BF surrogate search"):
        junk_path = _junk_file_path(
            config.layer,
            chunk_idx,
            total_junks,
            config.brute_force_junk_dir,
        )

        if not junk_path.exists():
            raise FileNotFoundError(
                f"Missing brute-force junk file: {junk_path}. "
                "Run ensure_bruteforce_junk_files first."
            )

        chunk = np.load(junk_path, mmap_mode="r")
        if chunk.ndim != 2 or chunk.shape[1] != config.layer:
            raise ValueError(
                f"Invalid junk file shape {chunk.shape} in {junk_path}. "
                f"Expected (?, {config.layer})."
            )

        global_chunk_start = chunk_idx * candidates_per_junk

        for batch_start in range(0, len(chunk), config.brute_force_batch_size):
            batch_end = min(batch_start + config.brute_force_batch_size, len(chunk))
            batch = np.asarray(chunk[batch_start:batch_end], dtype=np.float32)

            with torch.no_grad():
                batch_tensor = torch.as_tensor(batch, dtype=torch.float32, device=device)
                predictions = model(batch_tensor).view(-1).detach().cpu().numpy()

            if existing_ids is not None and existing_ids.size > 0:
                ids = np.arange(
                    global_chunk_start + batch_start,
                    global_chunk_start + batch_end,
                    dtype=np.uint64,
                )
                duplicate_mask = np.isin(ids, existing_ids)
                if np.all(duplicate_mask):
                    continue
                predictions[duplicate_mask] = np.inf

            local_idx = int(np.argmin(predictions))
            local_cost = float(predictions[local_idx])

            if local_cost < best_cost:
                best_cost = local_cost
                best_position = batch[local_idx].astype(np.int32)

    if best_position is None or not np.isfinite(best_cost):
        raise RuntimeError(
            "Brute-force search failed to find a valid non-duplicate candidate. "
            "Try setting skip_existing_candidates=False."
        )

    print(f"BF_output_values : {best_cost}")
    return best_cost, best_position



def select_candidate_with_surrogate(config: ActiveLearningConfig) -> Tuple[float, np.ndarray]:
    """Train CNN surrogate and select the next candidate using BPSO or brute force."""
    sample_binary, sample_fom = load_dataset(config.filename, config.work_dir)
    train_loader, val_loader, train_dataset, val_dataset = make_dataloaders(
        sample_binary,
        sample_fom,
        config,
    )
    save_train_validation_batches(train_loader, val_loader, config)

    # Train bit-specific CNN surrogate model.
    nn_fc(
        config.layer,
        train_loader,
        val_loader,
        config.filename,
        model_dir=config.model_dir,
        log_dir=config.log_dir,
    )

    # Select next binary vector using the selected optimizer.
    optimizer_name = normalize_optimizer_name(config.optimizer)
    start_time = time.time()

    if optimizer_name == "bpso":
        predicted_fom, candidate = BPSO_Opt(
            config.layer,
            filename=config.filename,
            model_dir=config.model_dir,
        )
        search_log_name = f"_BPSO_Search_time_{config.filename}.txt"

    elif optimizer_name == "brute_force":
        predicted_fom, candidate = brute_force_opt(
            config,
            existing_vectors=sample_binary,
        )
        search_log_name = f"_BF_Search_time_{config.filename}.txt"

    else:
        raise RuntimeError(f"Unexpected optimizer: {optimizer_name}")

    elapsed_time = time.time() - start_time
    _write_row(config.log_dir / search_log_name, [elapsed_time])

    candidate = np.asarray(candidate, dtype=np.int32).reshape(-1)
    if candidate.size != config.layer:
        raise ValueError(
            f"{optimizer_name} returned candidate length {candidate.size}, "
            f"expected {config.layer}."
        )

    # Save predicted candidate as opt_<filename>.txt.
    # First value: predicted FOM, remaining values: selected binary vector.
    opt_row = np.concatenate(([float(predicted_fom)], candidate.astype(float)))
    _write_row(config.work_dir / f"opt_{config.filename}.txt", opt_row, mode="w")

    # Save RMS logs for checking surrogate quality.
    train_x, train_y = subset_to_numpy(train_dataset)
    val_x, val_y = subset_to_numpy(val_dataset)
    save_surrogate_diagnostics(train_x, train_y, val_x, val_y, config)

    if config.remove_model_after_iteration:
        model_path = _checkpoint_path(config.filename, config.model_dir)
        if model_path.exists():
            model_path.unlink()

    return float(predicted_fom), candidate



def rms_loss(y_true: np.ndarray, y_pred: np.ndarray) -> float:
    """Calculate RMS error."""
    y_true = np.asarray(y_true).reshape(-1)
    y_pred = np.asarray(y_pred).reshape(-1)
    return float(np.sqrt(np.mean((y_true - y_pred) ** 2)))



def save_surrogate_diagnostics(
    train_x: np.ndarray,
    train_y: np.ndarray,
    val_x: np.ndarray,
    val_y: np.ndarray,
    config: ActiveLearningConfig,
) -> None:
    """Save train/validation prediction files and RMS values."""
    train_pred = nn_fc_output(
        train_x,
        config.filename,
        layer=config.layer,
        model_dir=config.model_dir,
    ).detach().cpu().numpy()
    val_pred = nn_fc_output(
        val_x,
        config.filename,
        layer=config.layer,
        model_dir=config.model_dir,
    ).detach().cpu().numpy()

    train_rms = rms_loss(train_y, train_pred)
    val_rms = rms_loss(val_y, val_pred)

    np.savetxt(
        config.log_dir / f"tr_{config.filename}.txt",
        np.concatenate(
            (train_pred.reshape(-1, 1), train_y.reshape(-1, 1), train_x), axis=1
        ),
    )
    np.savetxt(
        config.log_dir / f"cv_{config.filename}.txt",
        np.concatenate((val_pred.reshape(-1, 1), val_y.reshape(-1, 1), val_x), axis=1),
    )
    np.savetxt(config.log_dir / f"rms_{config.filename}.txt", np.array([train_rms, val_rms]))


# -----------------------------------------------------------------------------
# MATLAB FOM evaluation and dataset update
# -----------------------------------------------------------------------------


def start_matlab_engine_if_needed(config: ActiveLearningConfig):
    """Start MATLAB engine only when the active learning loop needs it."""
    if not config.start_matlab:
        return None

    try:
        import matlab.engine
    except ImportError as exc:
        raise ImportError(
            "MATLAB engine for Python is required. "
            "Install/configure matlab.engine or set start_matlab=False for testing."
        ) from exc

    return matlab.engine.start_matlab()



def read_opt_candidate(filename: str, work_dir: Path = Path(".")) -> Tuple[float, np.ndarray]:
    """Read ``opt_<filename>.txt`` and return predicted FOM and candidate vector."""
    opt_data = np.asarray(mfi(str(work_dir / f"opt_{filename}.txt"))).reshape(-1)
    if opt_data.size < 2:
        raise ValueError(f"opt_{filename}.txt must contain predicted FOM and vector.")

    predicted_fom = float(opt_data[0])
    candidate = opt_data[1:].astype(np.int32)
    return predicted_fom, candidate



def replace_if_duplicate(
    candidate: np.ndarray,
    existing_vectors: np.ndarray,
    max_trials: int = 10000,
) -> Tuple[np.ndarray, bool]:
    """Replace candidate by a random vector if it already exists in dataset."""
    candidate = np.asarray(candidate, dtype=np.int32).reshape(-1)
    existing_vectors = np.asarray(existing_vectors, dtype=np.int32)

    def is_duplicate(vec: np.ndarray) -> bool:
        return bool(np.any(np.all(existing_vectors == vec.reshape(1, -1), axis=1)))

    if not is_duplicate(candidate):
        return candidate, False

    for _ in range(max_trials):
        random_candidate = np.random.randint(0, 2, size=candidate.size, dtype=np.int32)
        if not is_duplicate(random_candidate):
            return random_candidate, True

    raise RuntimeError(
        "Failed to generate a non-duplicate candidate. "
        "The search space may be nearly exhausted."
    )



def evaluate_candidate_with_matlab(
    candidate: np.ndarray,
    engine,
    matlab_function_name: str,
) -> float:
    """Evaluate one binary candidate using the configured MATLAB FOM function."""
    if engine is None:
        raise RuntimeError("MATLAB engine is not running.")

    import matlab

    candidate_list = [int(v) for v in candidate.reshape(-1)]
    matlab_vector = matlab.int16(candidate_list)
    matlab_function = getattr(engine, matlab_function_name)
    fom = matlab_function(matlab_vector)

    # MATLAB engine may return scalar, list-like object, or matlab.double.
    fom_array = np.asarray(fom, dtype=float).reshape(-1)
    if fom_array.size == 0:
        raise ValueError(f"MATLAB function {matlab_function_name} returned no value.")
    return float(fom_array[0])



def calculate_fom_and_save(
    config: ActiveLearningConfig,
    engine,
) -> Tuple[float, np.ndarray, bool]:
    """Evaluate selected candidate and save ``MAT_<filename>.txt``."""
    _, candidate = read_opt_candidate(config.filename, config.work_dir)
    existing_vectors, _ = load_dataset(config.filename, config.work_dir)

    candidate, replaced_duplicate = replace_if_duplicate(candidate, existing_vectors)
    if replaced_duplicate:
        print("Duplicate candidate detected. Replaced with a random binary vector.")

    start_time = time.time()
    fom = evaluate_candidate_with_matlab(
        candidate,
        engine=engine,
        matlab_function_name=config.matlab_function_name,
    )
    elapsed_time = time.time() - start_time

    _write_row(config.log_dir / f"_TMM_time_{config.filename}.txt", [elapsed_time])

    actual_row = np.concatenate(([fom], candidate.astype(float)))
    _write_row(config.work_dir / f"MAT_{config.filename}.txt", actual_row, mode="w")
    _write_row(config.work_dir / f"FOM_PLOT_dat_{config.filename}.txt", actual_row, mode="w")

    return fom, candidate, replaced_duplicate



def append_dataset_and_logs(config: ActiveLearningConfig) -> None:
    """Append MATLAB-evaluated data to dataset and progress logs."""
    actual_data = np.asarray(mfi(str(config.work_dir / f"MAT_{config.filename}.txt"))).reshape(-1)
    predicted_data = np.asarray(mfi(str(config.work_dir / f"opt_{config.filename}.txt"))).reshape(-1)

    # Actual FOM + binary vector -> dataset and actual FOM plot file.
    _write_row(config.work_dir / f"dataset_{config.filename}.txt", actual_data)
    _write_row(config.log_dir / f"FOM_PLOT_{config.filename}.txt", actual_data)

    # Predicted FOM + binary vector -> surrogate-selected candidate log.
    optimizer_name = normalize_optimizer_name(config.optimizer)
    optimizer_tag = "BP" if optimizer_name == "bpso" else "BF"
    _write_row(config.log_dir / f"FOM_PLOT_{optimizer_tag}{config.filename}.txt", predicted_data)


# -----------------------------------------------------------------------------
# Monitoring and final reports
# -----------------------------------------------------------------------------


def get_current_best(filename: str, work_dir: Path = Path(".")) -> Tuple[float, np.ndarray]:
    """Return current minimum FOM and its binary vector from dataset."""
    data = _as_2d_array(mfi(str(work_dir / f"dataset_{filename}.txt")))
    best_idx = int(np.argmin(data[:, 0]))
    best_row = data[best_idx]
    return float(best_row[0]), best_row[1:].astype(np.int32)



def update_progress_logs(
    config: ActiveLearningConfig,
    iteration_idx: int,
    plot_of_fom: List[float],
    plot_of_rms: List[float],
    plot_of_rms_cv: List[float],
    best_update_times: List[object],
    best_update_iters: List[int],
    start_datetime: datetime,
) -> None:
    """Print and save current progress after each active learning iteration."""
    best_fom, best_vector = get_current_best(config.filename, config.work_dir)

    print("최소 FOM :", best_fom)
    print("해당 Binary vector :", best_vector)

    _write_row(config.log_dir / f"out_of_fom_{config.filename}.txt", [best_fom])

    rms_path = config.log_dir / f"rms_{config.filename}.txt"
    rms = np.asarray(mfi(str(rms_path))).reshape(-1)
    if rms.size >= 2:
        plot_of_rms.append(float(rms[0]))
        plot_of_rms_cv.append(float(rms[1]))
        _write_row(config.log_dir / f"Check_{config.filename}.txt", rms[:2])

    previous_best = plot_of_fom[-1] if plot_of_fom else None
    plot_of_fom.append(best_fom)

    if previous_best is None or best_fom != previous_best:
        elapsed = datetime.now() - start_datetime
        print("Code execution time :", elapsed)
        print("Number of iteration :", iteration_idx + 1)
        best_update_times.append(elapsed)
        best_update_iters.append(iteration_idx + 1)



def save_final_plots(
    config: ActiveLearningConfig,
    plot_of_fom: List[float],
    plot_of_rms: List[float],
    plot_of_rms_cv: List[float],
) -> None:
    """Save final FOM and RMS plots as PNG files."""
    if not config.save_final_plots:
        return

    try:
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib is not installed. Skipping final plot generation.")
        return

    if plot_of_fom:
        x_values = list(range(1, len(plot_of_fom) + 1))
        plt.figure()
        plt.plot(x_values, plot_of_fom, marker="o", alpha=0.5, linewidth=2)
        plt.title("Iteration-FOM")
        plt.xlabel("Iteration")
        plt.ylabel("Minimum FOM")
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(config.log_dir / f"Iteration_FOM_{config.filename}.png", dpi=300)
        plt.close()

    if plot_of_rms and plot_of_rms_cv:
        x_values = list(range(1, len(plot_of_rms) + 1))
        plt.figure()
        plt.plot(x_values, plot_of_rms, label="Training RMS")
        plt.plot(x_values, plot_of_rms_cv, label="Validation RMS")
        plt.legend()
        plt.xlabel("Iteration")
        plt.ylabel("RMS")
        plt.title("RMS vs Iteration")
        plt.grid(True)
        plt.tight_layout()
        plt.savefig(config.log_dir / f"RMS_{config.filename}.png", dpi=300)
        plt.close()


# -----------------------------------------------------------------------------
# Main active learning loop
# -----------------------------------------------------------------------------


def run_active_learning(config: ActiveLearningConfig) -> None:
    """Run the complete active learning process."""
    _validate_layer(config.layer)
    config.optimizer = normalize_optimizer_name(config.optimizer)

    config.work_dir.mkdir(parents=True, exist_ok=True)
    config.model_dir.mkdir(parents=True, exist_ok=True)
    config.log_dir.mkdir(parents=True, exist_ok=True)
    config.brute_force_junk_dir.mkdir(parents=True, exist_ok=True)

    seed_everything(config.seed)

    if config.optimizer == "brute_force":
        ensure_bruteforce_junk_files(config)

    init_time = time.time()
    start_datetime = datetime.now()
    print("start time :", datetime.fromtimestamp(int(init_time)))

    plot_of_fom: List[float] = []
    plot_of_rms: List[float] = []
    plot_of_rms_cv: List[float] = []
    best_update_times: List[object] = [0]
    best_update_iters: List[int] = [0]

    engine = start_matlab_engine_if_needed(config)

    try:
        for iteration_idx in tqdm(range(config.iterations)):
            iter_start_time = time.time()

            select_candidate_with_surrogate(config)
            calculate_fom_and_save(config, engine)
            append_dataset_and_logs(config)
            update_progress_logs(
                config=config,
                iteration_idx=iteration_idx,
                plot_of_fom=plot_of_fom,
                plot_of_rms=plot_of_rms,
                plot_of_rms_cv=plot_of_rms_cv,
                best_update_times=best_update_times,
                best_update_iters=best_update_iters,
                start_datetime=start_datetime,
            )

            iter_time = time.time() - iter_start_time
            _write_row(config.log_dir / f"iteration_time_{config.filename}.txt", [iter_time])

    finally:
        if engine is not None:
            try:
                engine.quit()
            except Exception:
                pass

    execution_time = time.time() - init_time
    print("Execution time:", execution_time)

    best_fom, best_vector = get_current_best(config.filename, config.work_dir)
    print("최소 FOM :", best_fom)
    print("해당 Binary vector :", best_vector)
    print("최소 FOM 발견 시간:", best_update_times[-1])
    print("최소 FOM 발견까지 반복 횟수:", best_update_iters[-1])

    save_final_plots(config, plot_of_fom, plot_of_rms, plot_of_rms_cv)


# -----------------------------------------------------------------------------
# CLI
# -----------------------------------------------------------------------------


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run CNN-surrogate active learning.")
    parser.add_argument("--filename", type=str, default="this_is_test_file")
    parser.add_argument("--layer", type=int, default=25, choices=SUPPORTED_BITS)
    parser.add_argument("--iterations", type=int, default=1000)
    parser.add_argument(
        "--optimizer",
        type=str,
        default="bpso",
        choices=("bpso", "bf", "brute_force"),
        help="Candidate search method: BPSO or brute-force surrogate search.",
    )
    parser.add_argument("--seed", type=int, default=101)
    parser.add_argument("--matlab-function", type=str, default="IRAR_TRC_test_script")
    parser.add_argument("--work-dir", type=Path, default=Path("."))
    parser.add_argument("--model-dir", type=Path, default=Path("."))
    parser.add_argument("--log-dir", type=Path, default=Path("."))
    parser.add_argument(
        "--brute-force-junk-dir",
        type=Path,
        default=Path("."),
        help="Directory where brute-force junk .npy files are stored.",
    )
    parser.add_argument(
        "--brute-force-junk-width",
        type=int,
        default=15,
        help="Number of variable bits per junk file. Each file has 2**junk_width rows.",
    )
    parser.add_argument(
        "--brute-force-batch-size",
        type=int,
        default=2**15,
        help="Prediction batch size used during brute-force surrogate search.",
    )
    parser.add_argument(
        "--regenerate-junk",
        action="store_true",
        help="Regenerate junk files even if matching files already exist.",
    )
    parser.add_argument(
        "--include-existing-candidates",
        action="store_true",
        help="Allow brute force to select candidates already present in the dataset.",
    )
    parser.add_argument("--no-save-split-files", action="store_true")
    parser.add_argument("--keep-model", action="store_true")
    parser.add_argument("--no-final-plots", action="store_true")
    return parser.parse_args()



def main() -> None:
    args = parse_args()
    config = ActiveLearningConfig(
        filename=args.filename,
        layer=args.layer,
        iterations=args.iterations,
        optimizer=args.optimizer,
        seed=args.seed,
        matlab_function_name=args.matlab_function,
        work_dir=args.work_dir,
        model_dir=args.model_dir,
        log_dir=args.log_dir,
        brute_force_junk_dir=args.brute_force_junk_dir,
        brute_force_junk_width=args.brute_force_junk_width,
        brute_force_batch_size=args.brute_force_batch_size,
        reuse_junk_files=not args.regenerate_junk,
        skip_existing_candidates=not args.include_existing_candidates,
        save_split_files=not args.no_save_split_files,
        remove_model_after_iteration=not args.keep_model,
        save_final_plots=not args.no_final_plots,
    )
    run_active_learning(config)


if __name__ == "__main__":
    main()
