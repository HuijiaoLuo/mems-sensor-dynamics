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

The signal-chain study now includes a symmetric differential-capacitive transducer. It compares the exact geometry-dependent capacitance with the small-signal approximation that reduces to the original $v=Gx$ model near the centred position.

The next readout layer models an ideal C--V/charge-amplifier interface with offset, noise, finite bandwidth, saturation, ADC quantization, and digital calibration.

## What is included

- MATLAB reference dynamics and automatically generated Simulink models.
- Laplace-domain and frequency-response analysis of the normalized resonator.
- Six eigenvalue-based regimes: stable/unstable focus, center, stable/unstable node, and saddle.
- A transparent signal chain with transduction, bias, deterministic illustrative noise, low-pass filtering, and calibration.
- A simplified differential-capacitive transducer with exact and linearized readout paths.
- An ideal capacitive readout front-end with ADC and digital calibration.
- Python/SciPy equations and physics-aware `pytest` tests; see the detailed
  [Python component guide](python/README.md).
- A separate fixed-step discrete model for code-generation experiments and
  continuous-versus-discrete validation.
- A local generated-C++ runtime harness cross-validated against MATLAB,
  Simulink, and SciPy at the fixed-step sample grid.
- A portable C++ fixed-step runtime compiled and checked by GitHub Actions
  against the Python/SciPy reference.
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
- [Exact versus linearized capacitive transduction](results/capacitive_transduction.png)
- [Capacitive readout front-end](results/readout_frontend.png)
- [MATLAB versus Simulink](results/matlab_vs_simulink.png)
- [Continuous versus discrete model](results/discrete_vs_continuous.png)

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
generate_discrete_results(params);
```

This creates the additional capacitive, readout, and fixed-step code-generation
models when they are not already present. Existing Simulink files are kept
unchanged. The fixed-step comparison is written to
`results/discrete_vs_continuous.png`.

The optional C++ source generation requires the **Simulink Coder app/product**
to be installed and licensed; Simulink alone is not sufficient. In MATLAB,
open the **Apps** tab and launch **Simulink Coder**, or run the reproducible
script below:

```matlab
addpath('matlab');
params = init_params();
generate_cpp_code(params);
```

Generated source and build folders are local artifacts and are not uploaded by
the repository workflow. Compiling the generated source into a host executable
is a separate compiler/toolchain step.

After compiling the generated model and placing the local executable at
`cpp/sensor_codegen_test.exe`, the runtime can be compared with all three
reference implementations:

```matlab
addpath('matlab');
params = init_params();
report = validate_codegen_pipeline('conda', 'mems-sensor-dynamics', params);
```

The command runs the C++ executable, compares its CSV trajectory with the
fixed-step Simulink model and MATLAB reference, and invokes
`python/compare_cpp_runtime.py` through the named Conda environment. The local
validation completed with maximum state errors of approximately $10^{-15}$ for
$x$ and $y$ across 2401 samples. The same fixed-step algorithm is also
compiled as a portable C++ runtime in GitHub Actions and checked against the
Python/SciPy reference with a $10^{-12}$ tolerance. GitHub Actions does not
build the MATLAB-generated C++ artifacts because those require the local
Simulink Coder toolchain.

The license-free Python tests use the canonical Conda environment:

```bash
conda env create -f environment.yml
conda activate mems-sensor-dynamics
python -m pytest tests/python -q
```

To reproduce the portable C++ CI job locally on a machine with `g++`:

```bash
g++ -std=c++17 -O2 -Wall -Wextra -pedantic \
  cpp/ci_runtime.cpp -o cpp/.ci_runtime
./cpp/.ci_runtime
python python/compare_cpp_runtime.py
```

This compiles the standalone exact-ZOH runtime used by CI. It is deliberately
separate from the Simulink-generated source, so this check does not require a
MATLAB license or Simulink Coder.

## Validation and CI

`validate_model.m` compares the MATLAB `ode45` reference with the Simulink mechanical model and reports maximum absolute and RMS errors for $x(t)$ and $y(t)$. The comparison figure records those values after local execution. The generated-C++ runtime is additionally compared with MATLAB, Simulink, and SciPy by the local `validate_codegen_pipeline` workflow described above.

The Python and portable C++ jobs run on pushes and pull requests. The
MATLAB/Simulink workflow is manually triggered because it requires MATLAB and
Simulink availability or a suitable MathWorks license.

## Repository structure

```text
mems-sensor-dynamics/
├── README.md
├── METHODS.md
├── run_demo.m
├── models/                 # Simulink models and model notes
├── matlab/                 # MATLAB reference, discrete model, and validation
├── cpp/                    # portable C++ runtime and local codegen harness
├── python/                 # SciPy dynamics, capacitance, and readout models
├── tests/                  # Python and MATLAB tests
├── results/                # Locally generated figures
├── legacy/                 # Original autonomous oscillator implementation
├── environment.yml
└── .github/workflows/      # Python CI and optional MATLAB CI
```

The continuous `sensor_dynamics.slx` model remains the high-accuracy
variable-step reference. `sensor_codegen_discrete.slx` is a separate
fixed-step model whose discrete state update is suitable for Simulink Coder.

## Scope

The project does not model a particular device layout, fringing fields, electrostatic actuation, nonlinear stiffness, transistor-level circuits, charge-pump implementation, production calibration, packaging, temperature effects, or a qualified noise specification. OpenModelica remains future work under `open_source/`.
