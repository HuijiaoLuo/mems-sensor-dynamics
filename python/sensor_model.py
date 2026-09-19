"""Portable numerical reference for the normalized sensor dynamics.

The model matches the MATLAB and Simulink mechanical equations:

    x_dot = y
    y_dot = u(t) - k*x - r*y

This module is deliberately independent of MATLAB and Simulink so it can run
in GitHub Actions and act as an open reference implementation.
"""

from __future__ import annotations

from collections.abc import Callable

import numpy as np
from numpy.typing import NDArray
from scipy.integrate import solve_ivp


FloatArray = NDArray[np.float64]
InputFunction = Callable[[float], float]


def system_matrix(k: float, r: float) -> FloatArray:
    """Return A for the unforced state-space system."""

    return np.array([[0.0, 1.0], [-k, -r]], dtype=float)


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

