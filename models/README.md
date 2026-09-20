# Simulink models

The .slx files are generated locally by matlab/build_models.m so that no unverified binary model or runtime result is committed by the preparation step.

From the repository root in MATLAB, run:

~~~matlab
addpath('matlab');
params = init_params();
build_models(params);
~~~

Then open:

~~~matlab
open_system('models/sensor_dynamics.slx');
open_system('models/sensor_signal_chain.slx');
open_system('models/sensor_capacitive_chain.slx');
open_system('models/sensor_readout_frontend.slx');
open_system('models/sensor_codegen_discrete.slx');
~~~

The capacitive-chain model contains the explicit path

```text
x -> xi -> {d-xi, d+xi} -> {1/(d-xi), 1/(d+xi)}
  -> {C1, C2} -> Delta C -> readout gain -> bias/noise/filter/calibration
```

It is the block-diagram counterpart of the equations documented in
`METHODS.md`. The original `sensor_signal_chain.slx` is retained as the
abstract `v = G*x` baseline.

The readout-front-end model continues from `Delta C` through an ideal C--V
gain, offset and noise, a first-order bandwidth limit, amplifier saturation,
ADC quantization, and digital displacement calibration.

## Fixed-step code-generation model

`sensor_codegen_discrete.slx` is intentionally separate from the continuous
`sensor_dynamics.slx` reference. It uses a `FixedStepDiscrete` solver and a
`Discrete State-Space` block with

```math
\mathbf{z}[n+1]=A_d\mathbf{z}[n]+B_d u[n].
```

The matrices are computed offline by
`matlab/discretize_sensor_model.m` using an exact zero-order-hold
discretisation. The input is held constant for one sample interval, with the
default sample time set in `matlab/init_params.m` as
`params.codegen.sample_time = 0.005` s.

The model has ordinary Outport blocks rather than `To Workspace` logging
blocks, so it can be used as the algorithm model for Simulink Coder. Generate
C++ source locally with:

```matlab
addpath('matlab');
params = init_params();
generate_cpp_code(params);
```

This requires Simulink Coder. The generated `*_grt_rtw/` directory and other
build artifacts are ignored by Git. The function generates source only; a
host executable can be compiled later with an available C++ toolchain. The
repository keeps the MATLAB and Python reference implementations rather than
generated source files.

After inspection, commit the .slx files if you want the generated model binaries included in the GitHub repository. Generated slprj/ and *.slxc files should remain ignored.
