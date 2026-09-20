# Python reference implementation

This directory contains the license-free Python/SciPy reference for the
simplified MEMS sensor model. It is deliberately independent of MATLAB and
Simulink so that the equations can be tested in a reproducible Conda
environment and executed by GitHub Actions.

The Python implementation follows the same system-level progression as the
main repository:

```text
normalized mechanics
    -> frequency response and stability analysis
    -> physical differential capacitance
    -> ideal C-to-V readout
    -> bandwidth, noise, saturation, ADC, and digital calibration
```

The mechanical state variables are normalized:

```math
\dot{x}=y,
\qquad
\dot{y}=u(t)-kx-ry.
```

The capacitive and readout modules then use physical units such as metres,
farads, volts, and ADC codes.

The separate `discrete_sensor_model.py` module provides the fixed-step
reference used by the code-generation stage. It computes exact
zero-order-hold matrices once and applies the sample-by-sample update

```math
\mathbf{z}[n+1]=A_d\mathbf{z}[n]+B_d u[n].
```

This mirrors `models/sensor_codegen_discrete.slx`; it does not replace the
high-accuracy continuous `solve_ivp` reference in `sensor_model.py`.

## Module overview

### `sensor_model.py`

This is the numerical reference for the normalized mechanical system. It
provides:

- `system_matrix(k, r)`: state matrix

  ```math
  A=\begin{bmatrix}0&1\\-k&-r\end{bmatrix};
  ```

- `sensor_dynamics(...)`: evaluates the first-order state equations for an
  arbitrary input function `u_fun(t)`;
- `step_input(...)`: creates a piecewise-constant input;
- `simulate(...)`: integrates the model with SciPy `solve_ivp` using the
  high-order `DOP853` method;
- `classify_dynamics(...)`: classifies stable/unstable focus, center,
  stable/unstable node, or saddle from the eigenvalues;
- `mechanical_energy(...)`: evaluates normalized kinetic plus potential energy;
- `frequency_response(...)`: evaluates

  ```math
  H(j\omega)=\frac{1}{k-\omega^2+jr\omega};
  ```

- `frequency_response_metrics(...)`: returns natural frequency, damping ratio,
  resonance frequency, resonance magnitude, static gain, approximate
  bandwidth, and quality factor.

Example:

```python
import numpy as np

from sensor_model import simulate, step_input

t, state = simulate(
    k=1.2,
    r=0.2,
    u_fun=lambda time: step_input(time),
)
x = state[0]
y = state[1]
```

Here `x` is displacement and `y` is velocity. The arrays returned by
`simulate` have shape `(2, number_of_time_samples)`.

### `capacitive_transduction.py`

This module maps physical proof-mass displacement to a symmetric differential
capacitive signal. The input `displacement` is $\xi$ in metres; `epsilon` is
permittivity in F/m, `electrode_area` is in m², and `gap` is in metres.

The exact model is

```math
C_1=\frac{\varepsilon A}{d-\xi},
\qquad
C_2=\frac{\varepsilon A}{d+\xi},
\qquad
\Delta C=C_1-C_2.
```

The returned `CapacitiveTransduction` object contains:

- `c1`, `c2`: individual electrode capacitances in farads;
- `delta_c`: exact differential capacitance in farads;
- `delta_c_linear`: small-signal approximation;
- `common_mode`: $C_1+C_2$;
- `sensitivity`: $S_C=2\varepsilon A/d^2$ in F/m.

The function rejects non-positive geometry parameters and displacements that
violate $|\xi|\lt d$.

```python
from capacitive_transduction import capacitive_transduction

cap = capacitive_transduction(
    displacement=1e-7,
    epsilon=8.8541878128e-12,
    electrode_area=1e-8,
    gap=2e-6,
)
```

### `readout_frontend.py`

This module implements the ideal system-level mixed-signal readout. It does
not model transistor-level circuits. The input is a time array and
differential capacitance array; the output is a `ReadoutFrontendResult` with
the intermediate electrical signals:

1. `sensor_voltage = gain_v_per_f * delta_c`;
2. offset and deterministic illustrative noise;
3. first-order finite-bandwidth filtering;
4. amplifier rail saturation;
5. ADC clipping and round-to-nearest quantization;
6. reconstructed ADC voltage;
7. digital offset compensation and conversion back to normalized displacement.

Important parameters are:

| Parameter | Meaning |
|---|---|
| `gain_v_per_f` | C-to-V gain in V/F |
| `offset_voltage` | analogue offset in V |
| `noise_amplitude` | illustrative voltage-noise amplitude in V |
| `bandwidth_tau` | first-order time constant in seconds |
| `amplifier_min`, `amplifier_max` | amplifier output rails in V |
| `adc_bits` | ADC resolution |
| `adc_min`, `adc_max` | ADC input range in V |
| `offset_estimate` | digital offset estimate in V |
| `capacitive_sensitivity` | $S_C$ in F/m |
| `displacement_scale` | metres per normalized displacement unit |

The calibrated displacement uses the small-signal inverse model:

```math
\widehat{x}
=\frac{v_{\mathrm{ADC}}-\widehat{V}_{\mathrm{offset}}}
{G_C S_C\alpha_x}.
```

This makes analogue clipping and finite bandwidth visible before the digital
calibration stage. The calibration cannot recover information lost by rail
saturation.

### `discrete_sensor_model.py`

This module supports the fixed-step/code-generation comparison:

- `discrete_matrices(...)` computes the zero-order-hold matrices $A_d$ and
  $B_d$ offline;
- `discrete_state_update(...)` applies one deterministic sample update;
- `simulate_discrete(...)` runs the fixed-step model on an input held over
  each sample interval.

The default sample time used by the repository is $T_s=0.005$ s. The module
is useful for checking the algorithm before compiling generated C++.

### `__init__.py` and `requirements.txt`

`__init__.py` marks `python/` as the lightweight Python reference package; it
does not create a separate runtime or command-line application.
`requirements.txt` lists the pip-installable dependencies for the same code
that is specified by the repository-level `environment.yml`.

## Testing

All Python tests are in
[`tests/python/test_sensor_model.py`](../tests/python/test_sensor_model.py).
The single test module covers all four implementation modules.

The tests verify physical and numerical properties rather than only one
reference output:

| Area | Checks |
|---|---|
| Mechanical equations | input-driven and autonomous $u=0$ state equations |
| Step response | expected equilibrium $x_{\mathrm{ss}}=u/k$ |
| Energy | conservation for $r=0$ and decay for positive damping |
| Stability | six eigenvalue-based dynamic regimes |
| Frequency response | static gain, resonance, damping metrics, high-frequency roll-off |
| Capacitance | zero differential output, odd symmetry, sensitivity, gap validity |
| Readout front-end | calibration, amplifier rails, ADC code limits, invalid configuration handling |
| Discrete code-generation reference | zero-order-hold matrices, matrix update, continuous/discrete agreement, sample-grid validation |

## Create the environment and run tests

From the repository root, create the canonical Conda environment:

```bash
conda env create -f environment.yml
conda activate mems-sensor-dynamics
```

Run the complete Python test suite:

```bash
python -m pytest tests/python -q
```

To generate a JUnit report locally, use the same command as CI:

```bash
python -m pytest tests/python -q --junitxml=test-results.xml
```

The dependencies are declared in `environment.yml`. The lighter
`python/requirements.txt` file contains the same NumPy, SciPy, and pytest
requirements for users who prefer a virtual environment or pip installation.

Before installing dependencies, a syntax-only check can be run with:

```bash
python -m py_compile \
    python/sensor_model.py \
    python/capacitive_transduction.py \
    python/readout_frontend.py \
    tests/python/test_sensor_model.py
```

## Continuous integration

`.github/workflows/python-ci.yml` creates the Conda environment on every push
and pull request, runs the full pytest suite, and uploads the JUnit report as
an artifact. This workflow does not require a MATLAB or Simulink license.

The Python implementation is therefore both an open reference model and the
license-free automated test layer for the broader MATLAB/Simulink project.

## Scope

These modules are educational system-level models. They do not represent
fringing fields, electrostatic feedback, parasitic capacitance, a transistor-
level charge amplifier, ADC circuit nonidealities, device calibration data, or
production noise specifications.
