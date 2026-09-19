function [t, chain] = signal_chain_reference(params, t)
%SIGNAL_CHAIN_REFERENCE Evaluate the educational signal chain in MATLAB.
%
%   v_ideal = G*x
%   v_raw   = v_ideal + bias + noise
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

previous_rng = rng;
cleanup_rng = onCleanup(@() rng(previous_rng)); %#ok<NASGU>
rng(params.noise_seed, 'twister');
noise = params.noise_amplitude .* randn(size(t));

v_ideal = params.transduction_gain .* x;
v_raw = v_ideal + params.bias + noise;

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

chain = struct('x', x, 'noise', noise, 'v_ideal', v_ideal, ...
    'v_raw', v_raw, 'v_filtered', v_filtered, 'y_cal', y_cal);

end

