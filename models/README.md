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

After inspection, commit the .slx files if you want the generated model binaries included in the GitHub repository. Generated slprj/ and *.slxc files should remain ignored.
