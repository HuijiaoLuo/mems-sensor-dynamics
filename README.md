# Simplified MEMS Sensor Dynamics

**A cross-tool implementation and verification of a simplified MEMS sensor dynamical model using MATLAB/Simulink and Python/SciPy.**

This repository treats one normalized, lumped-parameter mass-spring-damper model as a small scientific-software system. It combines dynamic-system analysis, sensor signal-chain modelling, MATLAB/Simulink cross-validation, physics-aware automated tests, a reproducible Conda environment, and GitHub Actions CI.

This is a simplified educational model. It is not intended to reproduce the architecture, multiphysics, noise behavior, or calibrated parameters of a commercial MEMS device.

## Project Highlights

- Implemented one externally driven sensor model in MATLAB/Simulink and Python/SciPy.
- Added state-space stability analysis for focus, node, center, and saddle regimes.
- Built an end-to-end signal chain with transduction, bias, noise, filtering, and calibration.
- Cross-validated MATLAB and Simulink mechanical responses with maximum-error and RMS metrics.
- Added physics-aware pytest checks, a reproducible Conda environment, and GitHub Actions CI.

## Overview

The mechanical model is

~~~text
x_dot = y
y_dot = u - k*x - r*y
~~~

or, equivalently,

~~~text
x'' + r*x' + k*x = u(t)
~~~

The normalized parameters can be related to a mass-spring-damper analogy:

~~~text
m*x'' + c*x' + k_s*x = F_ext
r = c/m,  k = k_s/m,  u = F_ext/m
~~~

The main sensor demonstration uses k = 1.2, r = 0.2, zero initial conditions, and a unit step input at t = 1 s. Its expected static displacement is x_ss = 1/k = 0.8333 in normalized units.

The original autonomous oscillator implementation is retained under legacy/ to document the evolution from an unforced dynamical system to the externally driven sensor model.

## Simulation Setup and Initial Conditions

The main sensor step-response and signal-chain demonstrations use:

~~~text
k = 1.2
r = 0.2
x0 = 0
y0 = 0
t0 = 0 s
tfinal = 12 s
u(t) = 0 before t = 1 s
u(t) = 1 after t = 1 s
~~~

The dynamic-regime phase portraits use a separate diagnostic setup:

~~~text
u(t) = 0
x0 = 1
y0 = 0
phase-portrait interval = 0 to 6 s
~~~

Using a nonzero initial displacement makes the stable, unstable, focus, node, and saddle geometries visible. This diagnostic setup is intentionally separate from the physically motivated sensor demonstration, which starts from rest at x0 = 0 and y0 = 0.

## Simulink Architecture

matlab/build_models.m creates two models:

- models/sensor_dynamics.slx — step excitation and two-state mechanical dynamics.
- models/sensor_signal_chain.slx — mechanical displacement, transduction, bias, additive noise, first-order low-pass filtering, and scale/bias compensation.

The generated models use the same parameter values and initial conditions as the MATLAB reference model.

## Dynamic Regimes

The project preserves six second-order regimes and classifies them programmatically with

~~~matlab
A = [0 1; -k -r];
lambda = eig(A);
~~~

| Regime | k | r |
|---|---:|---:|
| Stable focus | 1.2 | 0.2 |
| Center | 1.2 | 0 |
| Unstable focus | 1.2 | -0.2 |
| Stable node | 1.2 | 2.5 |
| Unstable node | 1.2 | -2.5 |
| Saddle | -0.5 | 0.2 |

These experiments are intentionally separate from the physically sensible operating regime of the sensor demonstration, where k > 0 and r > 0.

## Sensor Signal Chain

The signal-chain model follows transparent equations:

~~~text
v_ideal = G*x
v_raw   = v_ideal + bias + noise
y_cal   = scale*(v_filtered - bias_est)
~~~

The model is intentionally small enough to inspect and modify in Simulink.

## MATLAB ↔ Simulink Validation

matlab/reference_model.m solves the mechanical system with ode45. matlab/validate_model.m runs the Simulink model, retrieves the logged x(t) and y(t) signals, interpolates both implementations to a common time vector, reports maximum absolute and RMS errors, and exports a comparison figure.

Expected behavior: the MATLAB and Simulink curves should nearly overlap. Check the reported numerical errors after local execution rather than assuming values in advance.

## Open-Source Reference and CI

The repository also contains a license-free Python/SciPy implementation of the same mechanical equations under python/. Its physics-aware pytest suite verifies equilibrium behavior, conservation in the undamped regime, dissipative decay under positive damping, and eigenvalue-based stability classification.

GitHub Actions creates the Conda environment defined in environment.yml and runs these physics and numerical tests on every push and pull request through .github/workflows/python-ci.yml. This gives the repository a continuous-integration backbone without requiring a MATLAB license. MATLAB/Simulink remains the model-based implementation and cross-validation reference.

An additional MATLAB/Simulink workflow is available at .github/workflows/matlab-ci.yml. It is manually triggered because it requires MATLAB and Simulink availability or an appropriate MathWorks license. The MATLAB test suite covers the state equations, steady-state behavior, dynamic-regime labels, and MATLAB/Simulink response agreement.

The open_source/ folder records OpenModelica as future work. It is not part of the current implementation or CI pipeline.

## Results

Run the local workflow to generate the following GitHub-ready figures:

- ![Phase portraits](results/phase_portraits.png)
- ![Damping regimes](results/damping_regimes.png)
- ![MATLAB versus Simulink](results/matlab_vs_simulink.png)
- ![Sensor step response](results/sensor_step_response.png)
- ![Signal chain](results/signal_chain.png)
- ![Calibrated output](results/calibrated_output.png)

The image files are not fabricated in this repository; they appear after the MATLAB scripts are run locally.

### How to Read the Figures

- phase_portraits.png shows x-y trajectories for the six unforced dynamic regimes. Stable focus spirals toward the origin, the center forms a closed orbit, unstable focus spirals outward, stable node approaches without sustained oscillation, unstable node diverges, and the saddle has both stable and unstable directions.
- damping_regimes.png shows the eigenvalue locations and max Re(lambda). Negative real parts indicate decay, zero real parts indicate marginal behavior, and positive real parts indicate instability.
- matlab_vs_simulink.png compares the MATLAB ode45 reference with the Simulink mechanical model using the same zero initial conditions and step input. The curves should nearly overlap.
- sensor_step_response.png shows the main sensor displacement, the expected x_ss = u/k reference, the step excitation, and velocity. Because r = 0.2 is lightly damped, the 12-second window can still contain visible transient oscillation.
- signal_chain.png shows displacement, ideal and raw transduced signals, and the smoothed low-pass output. The raw signal includes the configured bias and measurement noise.
- calibrated_output.png compares the compensated output with normalized displacement. The low-pass filter creates transient lag, while the bias compensation removes the configured static bias estimate.

## How to Run

From the repository root in MATLAB:

~~~matlab
run_demo
~~~

Or run the stages explicitly:

~~~matlab
addpath('matlab');
params = init_params();
build_models(params);
generate_results(params);
report = validate_model(params);
~~~

Create the Conda environment and run the license-free numerical tests locally with:

~~~bash
conda env create -f environment.yml
conda activate mems-sensor-dynamics
python -m pytest tests/python -q
~~~

If the environment already exists, update it with:

~~~bash
conda env update -f environment.yml --prune
~~~

python/requirements.txt is retained as an optional pip-only fallback; Conda is the canonical development and CI environment.

Run the MATLAB tests locally with:

~~~matlab
results = runtests('tests/matlab', 'IncludeSubfolders', true);
table(results)
~~~

Open the generated models with:

~~~matlab
open_system('models/sensor_dynamics.slx');
open_system('models/sensor_signal_chain.slx');
~~~

Inspect the step response, x and y outputs, the signal-chain intermediate signals, and the validation error printed by validate_model.

Qualitatively, the sensor displacement should remain bounded and settle toward 0.8333; velocity should return toward zero; the low-pass filter should smooth the raw signal; and the calibration stage should remove the configured bias estimate. The six regime plots should reflect stable, marginal, unstable, and saddle behavior according to their eigenvalues.

Expected generated files are the two .slx models under models/ and the six .png figures under results/. Simulink may also create slprj/ and *.slxc files; these are ignored by Git.

If something fails, send back the complete MATLAB/Simulink error text, MATLAB release, the command that was run, and the model name or script line shown in the error.

## Repository Structure

~~~text
mems-sensor-dynamics/
├── README.md
├── .gitignore
├── run_demo.m
├── models/
│   ├── README.md
│   ├── sensor_dynamics.slx          # generated locally
│   └── sensor_signal_chain.slx      # generated locally
├── matlab/
│   ├── init_params.m
│   ├── reference_model.m
│   ├── sensor_dynamics_model.m
│   ├── get_test_cases.m
│   ├── build_models.m
│   ├── signal_chain_reference.m
│   ├── validate_model.m
│   └── generate_results.m
├── python/
│   ├── sensor_model.py
│   └── requirements.txt
├── environment.yml
├── tests/
│   ├── python/
│   │   └── test_sensor_model.py
│   └── matlab/
│       └── test_sensor_model.m
├── .github/
│   └── workflows/
│       ├── python-ci.yml
│       └── matlab-ci.yml
├── open_source/
│   └── README.md
├── results/                         # generated PNG files
└── legacy/
    ├── harmonic_oscillator_model.m
    ├── generic_second_order_model.m
    ├── harmonic_oscillator_dynamics.mlx
    └── harmonic_oscillator_demo.slx
~~~

## Scope and Limitations

The equations are normalized and intended for learning and portfolio demonstration. The project does not model a particular device layout, electrostatic actuation, nonlinear stiffness, electrical readout physics, production calibration, packaging, temperature effects, or a qualified noise specification.
