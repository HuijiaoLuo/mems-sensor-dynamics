"""Portable numerical reference for the normalized sensor dynamics.

The model matches the MATLAB and Simulink mechanical equations:

    x_dot = y
    y_dot = u(t) - k*x - r*y

This module is deliberately independent of MATLAB and Simulink so it can run
in GitHub Actions and act as an open reference implementation.
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

import numpy as np
from numpy.typing import NDArray
from scipy.integrate import solve_ivp


FloatArray = NDArray[np.float64]
InputFunction = Callable[[float], float]


@dataclass(frozen=True)
class FrequencyResponseMetrics:
    """Characteristic frequencies and gains of the normalized resonator."""

    natural_frequency: float
    damping_ratio: float
    quality_factor: float
    resonance_frequency: float
    resonance_magnitude: float
    static_gain: float
    bandwidth_approx: float


def system_matrix(k: float, r: float) -> FloatArray:
    """Return A for the unforced state-space system."""

    return np.array([[0.0, 1.0], [-k, -r]], dtype=float)


def frequency_response(
    omega: FloatArray,
    *,
    k: float,
    r: float,
) -> NDArray[np.complex128]:
    """Return H(j*omega) = X/U for the normalized mechanical model.

    The transfer function follows from zero-initial-condition Laplace
    analysis:

        H(s) = 1 / (s**2 + r*s + k)

    and s = j*omega for sinusoidal steady-state response.
    """

    omega_array = np.asarray(omega, dtype=float)
    if np.any(omega_array < 0.0):
        raise ValueError("Angular frequency must be non-negative.")

    denominator = k - omega_array**2 + 1j * r * omega_array
    return 1.0 / denominator


def frequency_response_metrics(
    *,
    k: float,
    r: float,
) -> FrequencyResponseMetrics:
    """Return natural-frequency, damping, resonance, and Q-factor metrics."""

    if k <= 0.0:
        raise ValueError("Frequency-response metrics require k > 0.")

    natural_frequency = float(np.sqrt(k))
    damping_ratio = float(r / (2.0 * natural_frequency))
    quality_factor = float(natural_frequency / r) if r > 0.0 else float("inf")
    static_gain = float(1.0 / k)
    bandwidth_approx = float(r) if r > 0.0 else 0.0

    if r > 0.0 and r**2 < 2.0 * k:
        resonance_frequency = float(np.sqrt(k - 0.5 * r**2))
        resonance_magnitude = float(
            1.0 / (r * np.sqrt(k - 0.25 * r**2))
        )
    else:
        resonance_frequency = float("nan")
        resonance_magnitude = float("nan")

    return FrequencyResponseMetrics(
        natural_frequency=natural_frequency,
        damping_ratio=damping_ratio,
        quality_factor=quality_factor,
        resonance_frequency=resonance_frequency,
        resonance_magnitude=resonance_magnitude,
        static_gain=static_gain,
        bandwidth_approx=bandwidth_approx,
    )


def step_input(
    time: float,
    *,
    step_time: float = 1.0,
    before: float = 0.0,
    after: float = 1.0,
) -> float:
    """Return a piecewise-constant step input."""

    return after if time >= step_time else before


def sensor_dynamics(
    time: float,
    state: FloatArray,
    k: float,
    r: float,
    u_fun: InputFunction,
) -> FloatArray:
    """Evaluate the input-driven first-order state equations."""

    x, y = state
    u = float(u_fun(float(time)))
    return np.array([y, u - k * x - r * y], dtype=float)


def simulate(
    *,
    k: float,
    r: float,
    u_fun: InputFunction,
    t_span: tuple[float, float] = (0.0, 12.0),
    x0: float = 0.0,
    y0: float = 0.0,
    sample_count: int = 2001,
    rtol: float = 1e-10,
    atol: float = 1e-12,
) -> tuple[FloatArray, FloatArray]:
    """Integrate the sensor dynamics and return time and state arrays."""

    t_eval = np.linspace(t_span[0], t_span[1], sample_count)
    solution = solve_ivp(
        lambda time, state: sensor_dynamics(time, state, k, r, u_fun),
        t_span,
        np.array([x0, y0], dtype=float),
        method="DOP853",
        t_eval=t_eval,
        rtol=rtol,
        atol=atol,
    )
    if not solution.success:
        raise RuntimeError(solution.message)
    return solution.t, solution.y


def classify_dynamics(k: float, r: float, tolerance: float = 1e-10) -> str:
    """Classify the second-order dynamics from its eigenvalues."""

    eigenvalues = np.linalg.eigvals(system_matrix(k, r))
    if np.linalg.det(system_matrix(k, r)) < -tolerance:
        return "Saddle"

    if np.any(np.abs(np.imag(eigenvalues)) > tolerance):
        real_part = float(np.real(eigenvalues[0]))
        if abs(real_part) <= tolerance:
            return "Center"
        return "Stable focus" if real_part < 0.0 else "Unstable focus"

    real_parts = np.real(eigenvalues)
    if np.max(real_parts) < -tolerance:
        return "Stable node"
    if np.min(real_parts) > tolerance:
        return "Unstable node"
    return "Degenerate / marginal"


def mechanical_energy(
    displacement: FloatArray,
    velocity: FloatArray,
    k: float,
) -> FloatArray:
    """Return normalized mechanical energy for k > 0."""

    return 0.5 * velocity**2 + 0.5 * k * displacement**2
