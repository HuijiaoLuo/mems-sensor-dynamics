"""Ideal mixed-signal capacitive readout front-end reference model."""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np
from numpy.typing import NDArray


FloatArray = NDArray[np.float64]


@dataclass(frozen=True)
class ReadoutFrontendResult:
    """Signals exposed by the ideal analogue front-end and ADC."""

    sensor_voltage: FloatArray
    noise: FloatArray
    input_voltage: FloatArray
    bandlimited_voltage: FloatArray
    amplifier_voltage: FloatArray
    adc_code: FloatArray
    adc_lsb: float
    adc_voltage: FloatArray
    calibrated_displacement: FloatArray


def readout_frontend(
    time: FloatArray,
    delta_c: FloatArray,
    *,
    gain_v_per_f: float,
    offset_voltage: float,
    offset_estimate: float,
    noise_amplitude: float,
    noise_seed: int,
    bandwidth_tau: float,
    amplifier_min: float,
    amplifier_max: float,
    adc_bits: int,
    adc_min: float,
    adc_max: float,
    capacitive_sensitivity: float,
    displacement_scale: float,
) -> ReadoutFrontendResult:
    """Simulate voltage readout, finite bandwidth, saturation, and ADC.

    The analogue chain is intentionally idealized. Saturation is applied
    after the first-order finite-bandwidth stage, and the digital output is
    calibrated back to normalized displacement using the small-signal gain.
    """

    time_array = np.asarray(time, dtype=float)
    delta_c_array = np.asarray(delta_c, dtype=float)
    if time_array.shape != delta_c_array.shape or time_array.size == 0:
        raise ValueError("time and delta_c must have the same nonzero shape.")
    if np.any(np.diff(time_array) < 0.0):
        raise ValueError("time must be non-decreasing.")
    if gain_v_per_f <= 0.0 or bandwidth_tau <= 0.0:
        raise ValueError("gain_v_per_f and bandwidth_tau must be positive.")
    if amplifier_min >= amplifier_max or adc_min >= adc_max:
        raise ValueError("Voltage limits must be strictly increasing.")
    if adc_bits < 1 or int(adc_bits) != adc_bits:
        raise ValueError("adc_bits must be a positive integer.")
    if capacitive_sensitivity <= 0.0 or displacement_scale <= 0.0:
        raise ValueError("Sensitivity and displacement_scale must be positive.")

    rng = np.random.default_rng(noise_seed)
    noise = noise_amplitude * rng.standard_normal(time_array.shape)
    sensor_voltage = gain_v_per_f * delta_c_array
    input_voltage = sensor_voltage + offset_voltage + noise

    bandlimited_voltage = np.zeros_like(input_voltage)
    bandlimited_voltage[0] = input_voltage[0]
    for index in range(1, input_voltage.size):
        dt = time_array[index] - time_array[index - 1]
        alpha = dt / (bandwidth_tau + dt)
        bandlimited_voltage[index] = (
            bandlimited_voltage[index - 1]
            + alpha * (input_voltage[index] - bandlimited_voltage[index - 1])
        )

    amplifier_voltage = np.clip(
        bandlimited_voltage,
        amplifier_min,
        amplifier_max,
    )
    levels = 2**int(adc_bits)
    adc_lsb = (adc_max - adc_min) / (levels - 1)
    adc_input = np.clip(amplifier_voltage, adc_min, adc_max)
    adc_code = np.clip(
        np.rint((adc_input - adc_min) / adc_lsb),
        0,
        levels - 1,
    )
    adc_voltage = adc_min + adc_code * adc_lsb
    calibrated_displacement = (
        (adc_voltage - offset_estimate)
        / gain_v_per_f
        / (capacitive_sensitivity * displacement_scale)
    )

    return ReadoutFrontendResult(
        sensor_voltage=sensor_voltage,
        noise=noise,
        input_voltage=input_voltage,
        bandlimited_voltage=bandlimited_voltage,
        amplifier_voltage=amplifier_voltage,
        adc_code=adc_code,
        adc_lsb=float(adc_lsb),
        adc_voltage=adc_voltage,
        calibrated_displacement=calibrated_displacement,
    )
