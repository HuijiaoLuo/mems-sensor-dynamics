function params = init_params()
%INIT_PARAMS Shared parameters for MATLAB and Simulink.
%
% The mechanical parameters are normalized educational values. Keep this
% function as the single source of truth for the main sensor demonstration.

this_file = mfilename('fullpath');
repo_root = fileparts(fileparts(this_file));

params.k = 1.2;
params.r = 0.2;
params.x0 = 0;
params.y0 = 0;
params.t0 = 0;
params.tfinal = 12;
params.tspan = [params.t0, params.tfinal];

params.input.step_time = 1;
params.input.before = 0;
params.input.after = 1;

% Educational signal-chain parameters.
params.transduction_gain = 1;
params.bias = 0.10;
params.bias_estimate = 0.10;
params.noise_amplitude = 0.01;
params.noise_seed = 7;
params.lowpass_tau = 0.15;
params.calibration_scale = 1;

% Frequency-response sweep settings in rad/s.
params.frequency.omega_min = 1e-2;
params.frequency.omega_max = 10^1.5;
params.frequency.sample_count = 1200;

params.model_files.sensor_dynamics = fullfile( ...
    repo_root, 'models', 'sensor_dynamics.slx');
params.model_files.signal_chain = fullfile( ...
    repo_root, 'models', 'sensor_signal_chain.slx');
params.results_dir = fullfile(repo_root, 'results');

end
