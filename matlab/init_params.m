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

% Simplified differential capacitive transduction parameters.
% x is normalized, so displacement_scale maps it to physical metres.
params.capacitance.epsilon = 8.8541878128e-12;  % F/m
params.capacitance.electrode_area = 1e-8;        % m^2
params.capacitance.gap = 2e-6;                   % m
params.capacitance.displacement_scale = 1e-7;    % m per normalized x
params.capacitance.sensitivity = 2 .* ...
    params.capacitance.epsilon .* params.capacitance.electrode_area ./ ...
    params.capacitance.gap.^2;
% Choose the readout gain so that the linearized capacitive path has the
% same small-signal gain as the existing abstract v = G*x path.
params.capacitance.readout_gain = params.transduction_gain ./ ...
    (params.capacitance.sensitivity .* ...
    params.capacitance.displacement_scale);

% Ideal mixed-signal capacitive readout front-end.
params.readout.gain_v_per_f = 1e13;       % voltage gain [V/F]
params.readout.offset_voltage = 0.05;     % amplifier input offset [V]
params.readout.offset_estimate = 0.05;    % digital calibration estimate [V]
params.readout.noise_amplitude = 5e-4;    % illustrative voltage noise [V]
params.readout.noise_seed = 23;
params.readout.bandwidth_tau = 0.25;      % first-order time constant [s]
params.readout.amplifier_min = 0.0;       % amplifier output rail [V]
params.readout.amplifier_max = 1.8;       % amplifier output rail [V]
params.readout.adc_bits = 12;
params.readout.adc_min = 0.0;
params.readout.adc_max = 1.8;

% Frequency-response sweep settings in rad/s.
params.frequency.omega_min = 1e-2;
params.frequency.omega_max = 10^1.5;
params.frequency.sample_count = 1200;

params.model_files.sensor_dynamics = fullfile( ...
    repo_root, 'models', 'sensor_dynamics.slx');
params.model_files.signal_chain = fullfile( ...
    repo_root, 'models', 'sensor_signal_chain.slx');
params.model_files.capacitive_chain = fullfile( ...
    repo_root, 'models', 'sensor_capacitive_chain.slx');
params.model_files.readout_frontend = fullfile( ...
    repo_root, 'models', 'sensor_readout_frontend.slx');
% Fixed-step model used for discrete-time validation and optional C/C++ code
% generation. The sample time is deliberately explicit and deterministic.
params.codegen.sample_time = 0.005;
params.model_files.codegen = fullfile( ...
    repo_root, 'models', 'sensor_codegen_discrete.slx');
params.results_dir = fullfile(repo_root, 'results');

end
