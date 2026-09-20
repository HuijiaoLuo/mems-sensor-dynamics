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

function testDifferentialCapacitanceIsZeroAtEquilibrium(testCase)
params = init_params();
cap = capacitive_transduction(0, params.capacitance);

verifyEqual(testCase, cap.c1, cap.c2, 'AbsTol', 1e-24);
verifyEqual(testCase, cap.delta_c, 0, 'AbsTol', 1e-24);
end

function testDifferentialCapacitanceSymmetry(testCase)
params = init_params();
displacement = [-0.2e-6, 0, 0.2e-6];
cap = capacitive_transduction(displacement, params.capacitance);

verifyEqual(testCase, cap.delta_c(1), -cap.delta_c(3), ...
    'AbsTol', 1e-24);
verifyEqual(testCase, cap.c1(1), cap.c2(3), 'AbsTol', 1e-24);
verifyEqual(testCase, cap.c2(1), cap.c1(3), 'AbsTol', 1e-24);
end

function testSmallSignalCapacitanceLinearization(testCase)
params = init_params();
displacement = 1e-10;
cap = capacitive_transduction(displacement, params.capacitance);

expected_sensitivity = 2 * params.capacitance.epsilon * ...
    params.capacitance.electrode_area / params.capacitance.gap^2;
verifyEqual(testCase, cap.sensitivity, expected_sensitivity, ...
    'AbsTol', 1e-24);
verifyEqual(testCase, cap.delta_c, cap.delta_c_linear, ...
    'RelTol', 1e-8);
end

function testCapacitanceRejectsGapViolation(testCase)
params = init_params();
verifyError(testCase, @() capacitive_transduction( ...
    params.capacitance.gap, params.capacitance), ...
    'capacitive_transduction:GapViolation');
end

function testReadoutFrontendCalibratesSmallSignal(testCase)
params = init_params();
t = linspace(0, 1, 101).';
x_expected = 0.2 .* ones(size(t));
delta_c = params.capacitance.sensitivity .* ...
    params.capacitance.displacement_scale .* x_expected;

readout = params.readout;
readout.noise_amplitude = 0;
readout.bandwidth_tau = 1e-6;
readout.adc_bits = 20;
params.readout = readout;
frontend = readout_frontend_reference(params, t, delta_c);

verifyEqual(testCase, frontend.x_calibrated(end), 0.2, ...
    'AbsTol', 1e-4);
end

function testReadoutFrontendRespectsRailsAndAdcRange(testCase)
params = init_params();
t = linspace(0, 1, 11).';
readout = params.readout;
readout.noise_amplitude = 0;
readout.amplifier_max = 1.0;
readout.adc_max = 1.0;
params.readout = readout;
frontend = readout_frontend_reference(params, t, ...
    [-1e-10; 1e-10 .* ones(10, 1)]);

verifyGreaterThanOrEqual(testCase, min(frontend.v_amplifier), 0);
verifyLessThanOrEqual(testCase, max(frontend.v_amplifier), 1);
verifyGreaterThanOrEqual(testCase, min(frontend.adc_code), 0);
verifyLessThanOrEqual(testCase, max(frontend.adc_code), ...
    2^params.readout.adc_bits - 1);
end

function testDiscreteMatricesPreserveStaticGain(testCase)
matrices = discretize_sensor_model(1.2, 0.2, 0.005);
equilibrium = (eye(2) - matrices.Ad) \ matrices.Bd;

verifyEqual(testCase, equilibrium, [1 / 1.2; 0], 'AbsTol', 1e-12);
end

function testDiscreteResponseMatchesContinuousReference(testCase)
params = init_params();
[t_discrete, state_discrete] = simulate_discrete_model(params);
[t_reference, state_reference] = reference_model(params);

x_reference = interp1(t_reference, state_reference(:, 1), ...
    t_discrete, 'linear');
y_reference = interp1(t_reference, state_reference(:, 2), ...
    t_discrete, 'linear');

% reference_model returns ode45's adaptive output grid. The interpolation
% onto the fixed grid contributes a small comparison error, so this is a
% consistency check rather than a bit-for-bit solver comparison.
verifyLessThan(testCase, max(abs(x_reference - state_discrete(:, 1))), 1e-2);
verifyLessThan(testCase, max(abs(y_reference - state_discrete(:, 2))), 1e-2);
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
