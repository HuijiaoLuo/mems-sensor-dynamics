# Simplified MEMS Sensor Dynamics

**A cross-tool implementation and verification of a simplified MEMS-inspired dynamical sensor model using MATLAB/Simulink and Python/SciPy.**

This repository develops one normalized, lumped-parameter mass-spring-damper model across several representations. It combines state-space analysis, Simulink block diagrams, a license-free Python reference implementation, signal-chain modelling, physics-aware tests, and continuous integration.

The model is educational and intentionally simplified. It is not a calibrated multiphysics model of a commercial MEMS device.

## Model at a glance

The mechanical dynamics are

```math
\dot{x}=y,\qquad \dot{y}=u(t)-kx-ry.
```

The main demonstration uses a unit step input, zero initial conditions, $k=1.2$, and $r=0.2$. The detailed derivation, implementation mapping, and figure interpretation are in [METHODS.md](METHODS.md).

## What is included

- MATLAB reference dynamics and automatically generated Simulink models.
- Laplace-domain and frequency-response analysis of the normalized resonator.
- Six eigenvalue-based regimes: stable/unstable focus, center, stable/unstable node, and saddle.
- A transparent signal chain with transduction, bias, deterministic illustrative noise, low-pass filtering, and calibration.
- Python/SciPy equations and physics-aware `pytest` tests.
- Conda environment definition and GitHub Actions CI.
- Optional manual MATLAB/Simulink CI for licensed runners.

## Results

The figures in `results/` are generated locally by MATLAB:

- [Phase portraits](results/phase_portraits.png)
- [Eigenvalue and stability overview](results/damping_regimes.png)
- [Sensor step response](results/sensor_step_response.png)
- [Signal-chain stages](results/signal_chain.png)
- [Calibrated output](results/calibrated_output.png)
- [Frequency response](results/frequency_response.png)
- [MATLAB versus Simulink](results/matlab_vs_simulink.png)

## Quick start

From the repository root in MATLAB:

```matlab
run_demo
```

Or run the stages explicitly:

```matlab
addpath('matlab');
params = init_params();
build_models(params);
generate_results(params);
```

The license-free Python tests use the canonical Conda environment:

```bash
conda env create -f environment.yml
conda activate mems-sensor-dynamics
python -m pytest tests/python -q
```

## Validation and CI

`validate_model.m` compares the MATLAB `ode45` reference with the Simulink mechanical model and reports maximum absolute and RMS errors for $x(t)$ and $y(t)$. The comparison figure records those values after local execution.

The Python workflow runs on pushes and pull requests. The MATLAB/Simulink workflow is manually triggered because it requires MATLAB and Simulink availability or a suitable MathWorks license.

## Repository structure

```text
mems-sensor-dynamics/
├── README.md
├── METHODS.md
├── run_demo.m
├── models/                 # Simulink models and model notes
├── matlab/                 # MATLAB reference, generation, and validation code
├── python/                 # SciPy implementation
├── tests/                  # Python and MATLAB tests
├── results/                # Locally generated figures
├── legacy/                 # Original autonomous oscillator implementation
├── environment.yml
└── .github/workflows/      # Python CI and optional MATLAB CI
```

## Scope

The project does not model a particular device layout, electrostatic actuation, nonlinear stiffness, electrical readout physics, production calibration, packaging, temperature effects, or a qualified noise specification. OpenModelica remains future work under `open_source/`.
