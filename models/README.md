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
~~~

After inspection, commit the .slx files if you want the generated model binaries included in the GitHub repository. Generated slprj/ and *.slxc files should remain ignored.

