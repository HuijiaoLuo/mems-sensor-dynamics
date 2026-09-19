# MEMS Sensor Modelling with MATLAB and Simulink

This portfolio project presents a simplified MEMS-inspired sensor model using MATLAB and Simulink. It combines normalized mass-spring-damper dynamics, an educational sensor signal chain, stability analysis, and MATLAB/Simulink cross-validation.

This is a simplified educational and portfolio model. It is not intended to reproduce the architecture, noise behavior, or calibrated parameters of a commercial MEMS sensor.

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

## From Harmonic Oscillator to Driven Sensor

The original model is preserved in legacy/harmonic_oscillator_model.m. It represents the autonomous case with no external excitation:

~~~text
x_dot = y
y_dot = -k*x - r*y
~~~

The new matlab/sensor_dynamics_model.m extends the same state equations with a time-dependent input function u_fun(t):

~~~matlab
u = u_fun(t);
dydt = u - k*x - r*y;
~~~

matlab/reference_model.m calls this function directly, so the MATLAB reference implementation and the Simulink step-input model now share the same explicit input-driven dynamics. Setting u_fun = @(t) 0 reproduces the original autonomous oscillator.

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

The repository also contains a license-free Python/SciPy implementation of the same mechanical equations under python/. Its pytest suite checks the input-driven state equation, the original u = 0 case, step-response steady state, energy conservation for the undamped oscillator, energy reduction with positive damping, and eigenvalue-based regime classification.

GitHub Actions creates the Conda environment defined in environment.yml and runs these physics and numerical tests on every push and pull request through .github/workflows/python-ci.yml. This gives the repository a continuous-integration backbone without requiring a MATLAB license. MATLAB/Simulink remains the model-based implementation and cross-validation reference.

The open_source/ folder records a future OpenModelica extension. The intended long-term goal is to implement the same sensor model in MATLAB/Simulink, Python/SciPy, and OpenModelica, then compare their displacement and velocity signals using common parameters and automated error metrics.

## Results

Run the local workflow to generate the following GitHub-ready figures:

- ![Phase portraits](results/phase_portraits.png)
- ![Damping regimes](results/damping_regimes.png)
- ![MATLAB versus Simulink](results/matlab_vs_simulink.png)
- ![Sensor step response](results/sensor_step_response.png)
- ![Signal chain](results/signal_chain.png)
- ![Calibrated output](results/calibrated_output.png)

The image files are not fabricated in this repository; they appear after the MATLAB scripts are run locally.

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
conda activate mems-sensor-simulink
python -m pytest tests/python -q
~~~

If the environment already exists, update it with:

~~~bash
conda env update -f environment.yml --prune
~~~

python/requirements.txt is retained as an optional pip-only fallback; Conda is the canonical development and CI environment.

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
mems-sensor-simulink/
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
│   └── python/
│       └── test_sensor_model.py
├── .github/
│   └── workflows/
│       └── python-ci.yml
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
