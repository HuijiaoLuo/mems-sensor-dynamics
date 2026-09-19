function frontend = readout_frontend_reference(params, t, delta_c)
%READOUT_FRONTEND_REFERENCE Ideal capacitive readout front-end model.
%
% The signal path is
%   DeltaC -> voltage gain -> offset/noise -> finite bandwidth -> saturation
%   -> ADC quantization -> digital offset calibration.

if nargin < 1
    params = init_params();
end
if nargin < 2 || nargin < 3
    error('readout_frontend_reference:MissingInput', ...
        'Provide params, time, and differential capacitance.');
end

t = t(:);
delta_c = delta_c(:);
if numel(t) ~= numel(delta_c) || numel(t) < 1
    error('readout_frontend_reference:SizeMismatch', ...
        'Time and differential-capacitance arrays must have equal nonzero length.');
end
if any(diff(t) < 0)
    error('readout_frontend_reference:NonMonotonicTime', ...
        'Time must be non-decreasing.');
end

readout = params.readout;
levels = 2^readout.adc_bits;

previous_rng = rng;
cleanup_rng = onCleanup(@() rng(previous_rng)); %#ok<NASGU>
rng(readout.noise_seed, 'twister');
noise = readout.noise_amplitude .* randn(size(t));

v_sensor = readout.gain_v_per_f .* delta_c;
v_input = v_sensor + readout.offset_voltage + noise;
v_bandlimited = local_lowpass(t, v_input, readout.bandwidth_tau);
v_amplifier = min(max(v_bandlimited, readout.amplifier_min), ...
    readout.amplifier_max);

v_adc_input = min(max(v_amplifier, readout.adc_min), readout.adc_max);
adc_lsb = (readout.adc_max - readout.adc_min) ./ (levels - 1);
adc_code = round((v_adc_input - readout.adc_min) ./ adc_lsb);
adc_code = min(max(adc_code, 0), levels - 1);
v_adc = readout.adc_min + adc_code .* adc_lsb;

% Invert the ideal readout gain and the small-signal capacitance sensitivity
% to express the calibrated ADC result in normalized displacement units.
delta_c_calibrated = (v_adc - readout.offset_estimate) ./ ...
    readout.gain_v_per_f;
x_calibrated = delta_c_calibrated ./ ...
    (params.capacitance.sensitivity .* ...
    params.capacitance.displacement_scale);

frontend = struct( ...
    'delta_c', delta_c, ...
    'noise', noise, ...
    'v_sensor', v_sensor, ...
    'v_input', v_input, ...
    'v_bandlimited', v_bandlimited, ...
    'v_amplifier', v_amplifier, ...
    'adc_code', adc_code, ...
    'adc_lsb', adc_lsb, ...
    'v_adc', v_adc, ...
    'delta_c_calibrated', delta_c_calibrated, ...
    'x_calibrated', x_calibrated);

end

function filtered = local_lowpass(t, signal, tau)
if tau <= 0
    error('readout_frontend_reference:InvalidBandwidth', ...
        'bandwidth_tau must be positive.');
end

filtered = zeros(size(signal));
filtered(1) = signal(1);
for index = 2:numel(signal)
    dt = t(index) - t(index - 1);
    alpha = dt ./ (tau + dt);
    filtered(index) = filtered(index - 1) + ...
        alpha .* (signal(index) - filtered(index - 1));
end
end
