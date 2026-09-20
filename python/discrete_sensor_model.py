"""Fixed-step reference for the code-generation version of the sensor model.

The continuous model is

    x_dot = y
    y_dot = u - k*x - r*y.

This module uses an exact zero-order-hold discretisation of that model.  The
discrete matrices are computed once, before a real-time loop starts, and the
sample-by-sample update only contains matrix-vector operations:

    z[k+1] = A_d z[k] + B_d u[k].

That structure mirrors the Discrete State-Space block used by the optional
Simulink code-generation model.  It is intentionally separate from
``sensor_model.py``, whose ``solve_ivp`` implementation remains the
high-accuracy continuous reference.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from numpy.typing import NDArray
from scipy.linalg import expm


FloatArray = NDArray[np.float64]


@dataclass(frozen=True)
class DiscreteMatrices:
    """Zero-order-hold matrices for one fixed sample time."""

    state: FloatArray
    input: FloatArray


def discrete_matrices(*, k: float, r: float, sample_time: float) -> DiscreteMatrices:
    """Return exact zero-order-hold matrices for the normalized dynamics.

    The matrix exponential is an offline operation.  It is not part of the
    per-sample update and therefore does not need to be generated for a
    target MCU or host executable.
    """

    if sample_time <= 0.0:
        raise ValueError("sample_time must be positive.")

    continuous_state = np.array([[0.0, 1.0], [-k, -r]], dtype=float)
    continuous_input = np.array([[0.0], [1.0]], dtype=float)
    augmented = np.block(
        [
            [continuous_state, continuous_input],
            [np.zeros((1, 3), dtype=float)],
        ]
    )
    discrete_augmented = expm(augmented * sample_time)

    return DiscreteMatrices(
        state=np.asarray(discrete_augmented[:2, :2], dtype=float),
        input=np.asarray(discrete_augmented[:2, 2:3], dtype=float),
    )


def discrete_state_update(
    state: FloatArray,
    input_value: float,
    matrices: DiscreteMatrices,
) -> FloatArray:
    """Advance one sample using precomputed discrete matrices."""

    state_array = np.asarray(state, dtype=float).reshape(2)
    return matrices.state @ state_array + matrices.input[:, 0] * float(input_value)


def simulate_discrete(
    *,
    k: float,
    r: float,
    u_fun,
    sample_time: float = 0.005,
    t_span: tuple[float, float] = (0.0, 12.0),
    x0: float = 0.0,
    y0: float = 0.0,
) -> tuple[FloatArray, FloatArray, FloatArray, DiscreteMatrices]:
    """Simulate the fixed-step model and return ``time, state, input, matrices``.

    ``u_fun(t[n])`` is held constant over the interval from ``t[n]`` to
    ``t[n+1]``.  The time span must contain an integer number of samples so
    that the output grid is deterministic.
    """

    if t_span[1] <= t_span[0]:
        raise ValueError("t_span must be increasing.")

    interval = float(t_span[1] - t_span[0])
    sample_count = int(round(interval / sample_time))
    if not np.isclose(sample_count * sample_time, interval, rtol=0.0, atol=1e-12):
        raise ValueError("t_span length must be an integer multiple of sample_time.")

    matrices = discrete_matrices(k=k, r=r, sample_time=sample_time)
    time = t_span[0] + sample_time * np.arange(sample_count + 1, dtype=float)
    input_values = np.asarray([u_fun(float(value)) for value in time[:-1]], dtype=float)
    state = np.zeros((2, sample_count + 1), dtype=float)
    state[:, 0] = [x0, y0]

    for index in range(sample_count):
        state[:, index + 1] = discrete_state_update(
            state[:, index], input_values[index], matrices
        )

    # Return one input value per state sample for convenient plotting.  The
    # last value is the input that would be applied at the final sample.
    input_trace = np.asarray([u_fun(float(value)) for value in time], dtype=float)
    return time, state, input_trace, matrices

