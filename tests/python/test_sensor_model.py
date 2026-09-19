from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pytest

PYTHON_DIR = Path(__file__).parents[2] / "python"
sys.path.insert(0, str(PYTHON_DIR))

from sensor_model import (  # noqa: E402
    classify_dynamics,
    mechanical_energy,
    sensor_dynamics,
    simulate,
    step_input,
    system_matrix,
)


def test_input_driven_state_equation() -> None:
    derivative = sensor_dynamics(
        2.0,
        np.array([0.4, -0.2]),
        k=1.2,
        r=0.5,
        u_fun=lambda _time: 1.0,
    )

    np.testing.assert_allclose(derivative, [-0.2, 0.62], rtol=0, atol=1e-12)


def test_zero_input_reproduces_autonomous_oscillator() -> None:
    derivative = sensor_dynamics(
        2.0,
        np.array([0.4, -0.2]),
        k=1.2,
        r=0.5,
        u_fun=lambda _time: 0.0,
    )

    np.testing.assert_allclose(derivative, [-0.2, -0.38], rtol=0, atol=1e-12)


def test_step_input_reaches_expected_steady_state() -> None:
    k = 1.2
    t, state = simulate(
        k=k,
        r=0.2,
        u_fun=lambda time: step_input(time),
        t_span=(0.0, 100.0),
        sample_count=4001,
    )

    assert t[-1] == pytest.approx(100.0)
    assert state[0, -1] == pytest.approx(1.0 / k, abs=1e-4)
    assert state[1, -1] == pytest.approx(0.0, abs=1e-4)


def test_undamped_free_response_conserves_energy() -> None:
    t, state = simulate(
        k=1.2,
        r=0.0,
        u_fun=lambda _time: 0.0,
        t_span=(0.0, 40.0),
        x0=1.0,
        y0=0.0,
        sample_count=4001,
    )

    energy = mechanical_energy(state[0], state[1], k=1.2)
    relative_deviation = np.max(np.abs(energy - energy[0])) / energy[0]

    assert t[-1] == pytest.approx(40.0)
    assert relative_deviation < 1e-8


def test_positive_damping_reduces_mechanical_energy() -> None:
    _, state = simulate(
        k=1.2,
        r=0.2,
        u_fun=lambda _time: 0.0,
        t_span=(0.0, 30.0),
        x0=1.0,
        y0=0.0,
        sample_count=3001,
    )

    energy = mechanical_energy(state[0], state[1], k=1.2)
    assert energy[-1] < energy[0]
    assert np.max(np.diff(energy)) < 1e-8


@pytest.mark.parametrize(
    ("k", "r", "expected"),
    [
        (1.2, 0.2, "Stable focus"),
        (1.2, 0.0, "Center"),
        (1.2, -0.2, "Unstable focus"),
        (1.2, 2.5, "Stable node"),
        (1.2, -2.5, "Unstable node"),
        (-0.5, 0.2, "Saddle"),
    ],
)
def test_dynamic_regime_classification(
    k: float,
    r: float,
    expected: str,
) -> None:
    assert classify_dynamics(k, r) == expected


def test_system_matrix_matches_model_definition() -> None:
    np.testing.assert_allclose(
        system_matrix(k=1.2, r=0.2),
        np.array([[0.0, 1.0], [-1.2, -0.2]]),
    )
