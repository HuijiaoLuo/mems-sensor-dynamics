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
│   ├── get_test_cases.m
│   ├── build_models.m
│   ├── signal_chain_reference.m
│   ├── validate_model.m
│   └── generate_results.m
├── results/                         # generated PNG files
└── legacy/
    ├── harmonic_oscillator_model.m
    ├── generic_second_order_model.m
    ├── harmonic_oscillator_dynamics.mlx
    └── harmonic_oscillator_demo.slx
~~~

## Scope and Limitations

The equations are normalized and intended for learning and portfolio demonstration. The project does not model a particular device layout, electrostatic actuation, nonlinear stiffness, electrical readout physics, production calibration, packaging, temperature effects, or a qualified noise specification.

