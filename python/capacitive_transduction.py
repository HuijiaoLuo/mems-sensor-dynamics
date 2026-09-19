"""Simplified differential capacitive transduction reference model."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from numpy.typing import NDArray


FloatArray = NDArray[np.float64]


@dataclass(frozen=True)
class CapacitiveTransduction:
    """Exact and small-signal differential-capacitance quantities."""

    c1: FloatArray
    c2: FloatArray
    delta_c: FloatArray
    delta_c_linear: FloatArray
    common_mode: FloatArray
    sensitivity: float


def capacitive_transduction(
    displacement: FloatArray,
    *,
    epsilon: float,
    electrode_area: float,
    gap: float,
) -> CapacitiveTransduction:
    """Evaluate a symmetric differential parallel-plate sensor.

    Parameters
    ----------
    displacement:
        Physical proof-mass displacement in metres.
    epsilon, electrode_area, gap:
        Permittivity, electrode area, and nominal electrode gap.

    The exact model requires ``abs(displacement) < gap``.  The linearized
    differential capacitance is the first-order approximation around zero.
    """

    if epsilon <= 0.0 or electrode_area <= 0.0 or gap <= 0.0:
        raise ValueError("epsilon, electrode_area, and gap must be positive.")

    displacement_array = np.asarray(displacement, dtype=float)
    if np.any(np.abs(displacement_array) >= gap):
        raise ValueError("The model requires abs(displacement) < gap.")

    scale = epsilon * electrode_area
    c1 = scale / (gap - displacement_array)
    c2 = scale / (gap + displacement_array)
    sensitivity = 2.0 * scale / gap**2

    return CapacitiveTransduction(
        c1=c1,
        c2=c2,
        delta_c=c1 - c2,
        delta_c_linear=sensitivity * displacement_array,
        common_mode=c1 + c2,
        sensitivity=sensitivity,
    )
