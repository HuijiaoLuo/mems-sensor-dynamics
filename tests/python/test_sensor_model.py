from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
import pytest

PYTHON_DIR = Path(__file__).parents[2] / "python"
sys.path.insert(0, str(PYTHON_DIR))

from sensor_model import (  # noqa: E402
    classify_dynamics,
    frequency_response,
    frequency_response_metrics,
    mechanical_energy,
    sensor_dynamics,
    simulate,
    step_input,
    system_matrix,
)
from capacitive_transduction import (  # noqa: E402
    capacitive_transduction,
)
from readout_frontend import readout_frontend  # noqa: E402


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


def test_frequency_response_matches_static_gain_at_zero_frequency() -> None:
    response = frequency_response(np.array([0.0]), k=1.2, r=0.2)

    np.testing.assert_allclose(response[0], 1.0 / 1.2, atol=1e-12)


def test_frequency_response_has_a_resonance_peak() -> None:
    metrics = frequency_response_metrics(k=1.2, r=0.2)
    response_at_resonance = frequency_response(
        np.array([metrics.resonance_frequency]),
        k=1.2,
        r=0.2,
    )

    assert 0.0 < metrics.resonance_frequency < metrics.natural_frequency
    assert metrics.resonance_magnitude > metrics.static_gain
    np.testing.assert_allclose(
        abs(response_at_resonance[0]),
        metrics.resonance_magnitude,
        rtol=1e-12,
    )


def test_frequency_response_metrics_match_damping_parameters() -> None:
    metrics = frequency_response_metrics(k=1.2, r=0.2)

    np.testing.assert_allclose(metrics.natural_frequency, np.sqrt(1.2))
    np.testing.assert_allclose(
        metrics.damping_ratio,
        0.2 / (2.0 * np.sqrt(1.2)),
    )
    np.testing.assert_allclose(metrics.quality_factor, np.sqrt(1.2) / 0.2)
    np.testing.assert_allclose(metrics.bandwidth_approx, 0.2)


def test_frequency_response_has_second_order_high_frequency_rolloff() -> None:
    response = frequency_response(np.array([10.0, 100.0]), k=1.2, r=0.2)

    ratio = abs(response[1]) / abs(response[0])
    assert ratio == pytest.approx(1e-2, rel=2e-2)


def test_differential_capacitance_is_zero_at_equilibrium() -> None:
    result = capacitive_transduction(
        np.array([0.0]),
        epsilon=8.8541878128e-12,
        electrode_area=1e-8,
        gap=2e-6,
    )

    np.testing.assert_allclose(result.c1, result.c2, rtol=0, atol=1e-24)
    np.testing.assert_allclose(result.delta_c, 0.0, rtol=0, atol=1e-24)


def test_differential_capacitance_has_odd_symmetry() -> None:
    displacement = np.array([-0.2e-6, 0.0, 0.2e-6])
    result = capacitive_transduction(
        displacement,
        epsilon=8.8541878128e-12,
        electrode_area=1e-8,
        gap=2e-6,
    )

    np.testing.assert_allclose(result.delta_c[0], -result.delta_c[2])
    np.testing.assert_allclose(result.c1[0], result.c2[2])
    np.testing.assert_allclose(result.c2[0], result.c1[2])


def test_small_signal_sensitivity_matches_linearization() -> None:
    epsilon = 8.8541878128e-12
    area = 1e-8
    gap = 2e-6
    displacement = np.array([1e-10])
    result = capacitive_transduction(
        displacement,
        epsilon=epsilon,
        electrode_area=area,
        gap=gap,
    )

    expected_sensitivity = 2.0 * epsilon * area / gap**2
    np.testing.assert_allclose(result.sensitivity, expected_sensitivity)
    np.testing.assert_allclose(
        result.delta_c,
        result.delta_c_linear,
        rtol=1e-8,
    )


def test_capacitive_model_rejects_gap_violation() -> None:
    with pytest.raises(ValueError, match=r"abs\(displacement\) < gap"):
        capacitive_transduction(
            np.array([2e-6]),
            epsilon=8.8541878128e-12,
            electrode_area=1e-8,
            gap=2e-6,
        )


def test_readout_frontend_calibrates_a_small_signal() -> None:
    time = np.linspace(0.0, 1.0, 101)
    sensitivity = 2.0 * 8.8541878128e-12 * 1e-8 / (2e-6) ** 2
    displacement_scale = 1e-7
    displacement = np.full(time.shape, 0.2)
    delta_c = sensitivity * displacement_scale * displacement

    result = readout_frontend(
        time,
        delta_c,
        gain_v_per_f=1e13,
        offset_voltage=0.05,
        offset_estimate=0.05,
        noise_amplitude=0.0,
        noise_seed=23,
        bandwidth_tau=1e-6,
        amplifier_min=0.0,
        amplifier_max=1.8,
        adc_bits=20,
        adc_min=0.0,
        adc_max=1.8,
        capacitive_sensitivity=sensitivity,
        displacement_scale=displacement_scale,
    )

    np.testing.assert_allclose(
        result.calibrated_displacement[-1],
        displacement[-1],
        atol=1e-4,
    )


def test_readout_frontend_respects_rails_and_adc_range() -> None:
    time = np.linspace(0.0, 1.0, 11)
    delta_c = np.array([-1e-10] + [1e-10] * 10)
    result = readout_frontend(
        time,
        delta_c,
        gain_v_per_f=1e13,
        offset_voltage=0.0,
        offset_estimate=0.0,
        noise_amplitude=0.0,
        noise_seed=23,
        bandwidth_tau=0.1,
        amplifier_min=0.0,
        amplifier_max=1.0,
        adc_bits=8,
        adc_min=0.0,
        adc_max=1.0,
        capacitive_sensitivity=1.0,
        displacement_scale=1.0,
    )

    assert np.all(result.amplifier_voltage >= 0.0)
    assert np.all(result.amplifier_voltage <= 1.0)
    assert np.all(result.adc_code >= 0.0)
    assert np.all(result.adc_code <= 255.0)


def test_readout_frontend_rejects_invalid_adc_configuration() -> None:
    with pytest.raises(ValueError, match="adc_bits"):
        readout_frontend(
            np.array([0.0, 1.0]),
            np.array([0.0, 0.0]),
            gain_v_per_f=1.0,
            offset_voltage=0.0,
            offset_estimate=0.0,
            noise_amplitude=0.0,
            noise_seed=1,
            bandwidth_tau=1.0,
            amplifier_min=0.0,
            amplifier_max=1.0,
            adc_bits=0,
            adc_min=0.0,
            adc_max=1.0,
            capacitive_sensitivity=1.0,
            displacement_scale=1.0,
        )
