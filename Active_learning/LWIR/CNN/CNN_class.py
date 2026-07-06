"""CNN architectures selected by input bit size.

This module defines a single `SimplifiedCNN` class that reproduces the
bit-specific 1D CNN architectures used for input sizes 17, 19, 21, 23, 25,
30, 35, 40, 45, and 50.

Example
-------
>>> model = SimplifiedCNN(input_bit=25)
>>> x = torch.randn(32, 25)      # or torch.randn(32, 1, 25)
>>> y = model(x)
"""

from __future__ import annotations

from collections import OrderedDict
from typing import Dict, List, Tuple

import torch
import torch.nn as nn


LayerSpec = Tuple[int, int, int]  # (in_channels, out_channels, kernel_size)


class SimplifiedCNN(nn.Module):
    """Bit-size dependent 1D CNN regression model.

    Parameters
    ----------
    input_bit : int
        Input data size in bits. Supported values are
        17, 19, 21, 23, 25, 30, 35, 40, 45, and 50.

    Notes
    -----
    The convolution layers are registered as ``conv1``, ``conv2``, ... to keep
    the same layer names as the original bit-specific CNN files. This makes the
    model easier to compare with the previous implementation and helps preserve
    checkpoint compatibility when layer shapes are identical.
    """

    ARCHITECTURES: Dict[int, List[LayerSpec]] = {
        17: [
            (1, 64, 5),
            (64, 128, 5),
            (128, 256, 4),
            (256, 128, 3),
        ],
        19: [
            (1, 64, 5),
            (64, 128, 5),
            (128, 256, 4),
            (256, 128, 3),
            (128, 128, 3),
        ],
        21: [
            (1, 64, 5),
            (64, 128, 5),
            (128, 256, 5),
            (256, 128, 4),
            (128, 128, 3),
        ],
        23: [
            (1, 64, 5),
            (64, 128, 5),
            (128, 256, 5),
            (256, 128, 5),
            (128, 128, 4),
        ],
        25: [
            (1, 64, 5),
            (64, 128, 5),
            (128, 256, 5),
            (256, 128, 5),
            (128, 128, 4),
            (128, 128, 3),
        ],
        30: [
            (1, 64, 5),
            (64, 128, 5),
            (128, 256, 5),
            (256, 256, 5),
            (256, 256, 5),
            (256, 128, 5),
            (128, 128, 3),
        ],
        35: [
            (1, 64, 5),
            (64, 128, 5),
            (128, 256, 5),
            (256, 256, 5),
            (256, 256, 5),
            (256, 128, 5),
            (128, 64, 4),
        ],
        40: [
            (1, 64, 5),
            (64, 128, 5),
            (128, 256, 5),
            (256, 256, 5),
            (256, 256, 5),
            (256, 128, 5),
            (128, 64, 5),
            (64, 64, 5),
        ],
        45: [
            (1, 64, 5),
            (64, 128, 5),
            (128, 256, 5),
            (256, 256, 5),
            (256, 256, 5),
            (256, 128, 5),
            (128, 128, 5),
            (128, 64, 5),
            (64, 64, 5),
        ],
        50: [
            (1, 64, 5),
            (64, 128, 5),
            (128, 256, 5),
            (256, 256, 5),
            (256, 256, 5),
            (256, 128, 5),
            (128, 128, 5),
            (128, 64, 5),
            (64, 32, 5),
        ],
    }

    def __init__(self, input_bit: int) -> None:
        super().__init__()

        if input_bit not in self.ARCHITECTURES:
            supported_bits = ", ".join(map(str, self.supported_bits()))
            raise ValueError(
                f"Unsupported input_bit={input_bit}. "
                f"Supported input_bit values are: {supported_bits}."
            )

        self.input_bit = input_bit
        self.conv_names: List[str] = []

        current_length = input_bit
        for layer_idx, (in_channels, out_channels, kernel_size) in enumerate(
            self.ARCHITECTURES[input_bit], start=1
        ):
            layer_name = f"conv{layer_idx}"
            conv_layer = nn.Conv1d(
                in_channels=in_channels,
                out_channels=out_channels,
                kernel_size=kernel_size,
            )
            setattr(self, layer_name, conv_layer)
            self.conv_names.append(layer_name)

            current_length = current_length - kernel_size + 1
            if current_length <= 0:
                raise ValueError(
                    f"Invalid architecture for input_bit={input_bit}: "
                    f"sequence length became {current_length} after {layer_name}."
                )

        final_out_channels = self.ARCHITECTURES[input_bit][-1][1]
        fc_input_features = final_out_channels * current_length

        self.fc1 = nn.Linear(fc_input_features, 64)
        self.fc2 = nn.Linear(64, 1)

    @classmethod
    def supported_bits(cls) -> List[int]:
        """Return supported input bit sizes in ascending order."""
        return sorted(cls.ARCHITECTURES.keys())

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """Run the forward pass.

        Parameters
        ----------
        x : torch.Tensor
            Input tensor with shape ``(batch, input_bit)`` or
            ``(batch, 1, input_bit)``.

        Returns
        -------
        torch.Tensor
            Regression output with shape ``(batch, 1)``.
        """
        if x.dim() == 2:
            x = x.unsqueeze(1)
        elif x.dim() != 3:
            raise ValueError(
                "Input tensor must have shape (batch, input_bit) "
                "or (batch, 1, input_bit)."
            )

        if x.size(1) != 1:
            raise ValueError(f"Expected 1 input channel, but got {x.size(1)}.")

        if x.size(-1) != self.input_bit:
            raise ValueError(
                f"Expected input length {self.input_bit}, but got {x.size(-1)}."
            )

        for conv_name in self.conv_names:
            conv_layer = getattr(self, conv_name)
            x = torch.relu(conv_layer(x))

        x = x.view(x.size(0), -1)
        x = torch.relu(self.fc1(x))
        return self.fc2(x)

    def extra_repr(self) -> str:
        return f"input_bit={self.input_bit}"


__all__ = ["SimplifiedCNN"]
