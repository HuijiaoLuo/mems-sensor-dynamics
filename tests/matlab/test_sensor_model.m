function tests = test_sensor_model
%TEST_SENSOR_MODEL MATLAB and optional Simulink verification tests.

tests = functiontests(localfunctions);

end

function testInputDrivenEquation(testCase)
actual = sensor_dynamics_model(2.0, [0.4; -0.2], 1.2, 0.5, ...
    @(~) 1.0);

verifyEqual(testCase, actual, [-0.2; 0.62], 'AbsTol', 1e-12);
end

function testZeroInputReproducesAutonomousOscillator(testCase)
actual = sensor_dynamics_model(2.0, [0.4; -0.2], 1.2, 0.5, ...
    @(~) 0.0);

verifyEqual(testCase, actual, [-0.2; -0.38], 'AbsTol', 1e-12);
end

function testStepResponseReachesExpectedSteadyState(testCase)
params = init_params();
params.tspan = [0, 100];

[t, state] = reference_model(params);
x_ss = params.input.after / params.k;

verifyEqual(testCase, t(end), 100, 'AbsTol', 1e-12);
verifyLessThan(testCase, abs(state(end, 1) - x_ss), 1e-4);
verifyLessThan(testCase, abs(state(end, 2)), 1e-4);
end

function testDynamicRegimeClassification(testCase)
cases = get_test_cases();
actual = {cases.classification};
expected = {'Stable focus', 'Center', 'Unstable focus', ...
    'Stable node', 'Unstable node', 'Saddle'};

verifyEqual(testCase, actual, expected);
end

function testFrequencyResponseMatchesStaticGain(testCase)
response = frequency_response(1.2, 0.2, 0);

verifyEqual(testCase, response.H, 1 / 1.2, 'AbsTol', 1e-12);
end

function testFrequencyResponseMetrics(testCase)
response = frequency_response(1.2, 0.2, [0; sqrt(1.2)]);

verifyEqual(testCase, response.natural_frequency, sqrt(1.2), ...
    'AbsTol', 1e-12);
verifyEqual(testCase, response.damping_ratio, ...
    0.2 / (2 * sqrt(1.2)), 'AbsTol', 1e-12);
verifyEqual(testCase, response.quality_factor, sqrt(1.2) / 0.2, ...
    'AbsTol', 1e-12);
verifyGreaterThan(testCase, response.resonance_magnitude, ...
    response.static_gain);
verifyGreaterThan(testCase, response.resonance_frequency, 0);
verifyLessThan(testCase, response.resonance_frequency, ...
    response.natural_frequency);
end

function testSimulinkMatchesReferenceWhenAvailable(testCase)
% This test is skipped on MATLAB installations without Simulink.
assumeTrue(testCase, license('test', 'Simulink'));

params = init_params();
verifyTrue(testCase, isfile(params.model_files.sensor_dynamics));

[t_reference, state_reference] = reference_model(params);
sim_output = sim(params.model_files.sensor_dynamics, ...
    'ReturnWorkspaceOutputs', 'on', ...
    'StopTime', num2str(params.tfinal));

[t_x, x_simulation] = local_extract_timeseries(sim_output.get('x_sim'));
[t_y, y_simulation] = local_extract_timeseries(sim_output.get('y_sim'));
t_common = linspace(params.t0, params.tfinal, 1001).';

x_reference = interp1(t_reference, state_reference(:, 1), ...
    t_common, 'linear');
y_reference = interp1(t_reference, state_reference(:, 2), ...
    t_common, 'linear');
x_simulation = interp1(t_x, x_simulation, t_common, 'linear');
y_simulation = interp1(t_y, y_simulation, t_common, 'linear');

% The comparison uses two adaptive solver grids and linear interpolation.
% The local run typically gives errors of a few 1e-3, so keep this as a
% cross-implementation consistency check rather than a solver identity test.
verifyLessThan(testCase, max(abs(x_reference - x_simulation)), 1e-2);
verifyLessThan(testCase, max(abs(y_reference - y_simulation)), 1e-2);
end

function [time, data] = local_extract_timeseries(signal)
if isa(signal, 'timeseries')
    time = signal.Time(:);
    data = signal.Data(:);
elseif isstruct(signal) && isfield(signal, 'time')
    time = signal.time(:);
    data = signal.signals.values(:);
else
    error('test_sensor_model:UnsupportedLogFormat', ...
        'Expected a Timeseries or Structure With Time log.');
end
end
