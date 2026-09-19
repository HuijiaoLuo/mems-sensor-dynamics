function [t, chain] = signal_chain_reference(params, t)
%SIGNAL_CHAIN_REFERENCE Evaluate the educational signal chain in MATLAB.
%
%   v_abstract = G*x
%   v_cap     = G_C*DeltaC(xi)
%   v_raw     = v_cap + bias + noise
%   y_cal   = scale*(v_filtered - bias_est)
%
% The deterministic random seed makes the generated illustration
% reproducible. It is not a device noise characterization.

if nargin < 1
    params = init_params();
end
if nargin < 2
    t = linspace(params.t0, params.tfinal, 2001).';
else
    t = t(:);
end

[t_mechanical, state] = reference_model(params);
x = interp1(t_mechanical, state(:, 1), t, 'linear', 'extrap');

% Convert normalized displacement x into physical proof-mass displacement xi.
xi = params.capacitance.displacement_scale .* x;
cap = capacitive_transduction(xi, params.capacitance);

% Keep all three paths visible: the original abstract path, the linearized
% capacitive approximation, and the exact differential-capacitance path.
v_abstract = params.transduction_gain .* x;
v_capacitive_linear = params.capacitance.readout_gain .* ...
    cap.delta_c_linear;
v_capacitive = params.capacitance.readout_gain .* cap.delta_c;

previous_rng = rng;
cleanup_rng = onCleanup(@() rng(previous_rng)); %#ok<NASGU>
rng(params.noise_seed, 'twister');
noise = params.noise_amplitude .* randn(size(t));

v_ideal = v_capacitive;
v_raw = v_ideal + params.bias + noise;

% Separate mixed-signal front-end study: voltage readout, finite bandwidth,
% saturation, ADC quantization, and digital calibration.
frontend = readout_frontend_reference(params, t, cap.delta_c);

v_filtered = zeros(size(t));
v_filtered(1) = v_raw(1);
for index = 2:numel(t)
    dt = t(index) - t(index - 1);
    alpha = dt / (params.lowpass_tau + dt);
    v_filtered(index) = v_filtered(index - 1) + ...
        alpha .* (v_raw(index) - v_filtered(index - 1));
end

y_cal = params.calibration_scale .* ...
    (v_filtered - params.bias_estimate);

chain = struct('x', x, 'xi', xi, 'noise', noise, ...
    'c1', cap.c1, 'c2', cap.c2, 'delta_c', cap.delta_c, ...
    'delta_c_linear', cap.delta_c_linear, 'v_abstract', v_abstract, ...
    'v_capacitive', v_capacitive, ...
    'v_capacitive_linear', v_capacitive_linear, 'v_ideal', v_ideal, ...
    'v_raw', v_raw, 'v_filtered', v_filtered, 'y_cal', y_cal, ...
    'frontend', frontend);

end
