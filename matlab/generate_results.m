function generate_results(params)
%GENERATE_RESULTS Generate the portfolio figures in results/.
%
% This function creates figures only when run locally in MATLAB. It does not
% fabricate image files during repository preparation.

if nargin < 1
    params = init_params();
end
if exist(params.results_dir, 'dir') ~= 7
    mkdir(params.results_dir);
end

cases = get_test_cases();

% Phase portraits for the six requested dynamic regimes.
phase_figure = figure('Visible', 'off', 'Color', 'w');
tiledlayout(2, 3);
for index = 1:numel(cases)
    rhs = @(time, state) cases(index).A * state;
    [~, state] = ode45(rhs, [0, 12], [1; 0]);
    nexttile;
    plot(state(:, 1), state(:, 2), 'LineWidth', 1.1);
    grid on;
    xlabel('x');
    ylabel('y');
    title(cases(index).name);
end
sgtitle('Second-order dynamic regimes');
local_export(phase_figure, fullfile(params.results_dir, ...
    'phase_portraits.png'));

% Eigenvalue-based damping/stability overview.
damping_figure = figure('Visible', 'off', 'Color', 'w');
tiledlayout(2, 1);
nexttile;
hold on;
for index = 1:numel(cases)
    lambda = cases(index).eigenvalues;
    plot(real(lambda), imag(lambda), 'o', 'MarkerSize', 7, ...
        'DisplayName', cases(index).name);
end
xline(0, 'k:');
yline(0, 'k:');
grid on;
xlabel('Real(lambda)');
ylabel('Imag(lambda)');
title('Eigenvalue locations');
legend('Location', 'eastoutside');

nexttile;
max_real_parts = zeros(1, numel(cases));
for index = 1:numel(cases)
    max_real_parts(index) = max(real(cases(index).eigenvalues));
end
bar(max_real_parts);
hold on;
yline(0, 'k:');
grid on;
xticks(1:numel(cases));
xticklabels({cases.name});
xtickangle(25);
xlabel('Regime');
ylabel('max Real(lambda)');
title('Stability indicator from eigenvalues');
local_export(damping_figure, fullfile(params.results_dir, ...
    'damping_regimes.png'));

% Main sensor step response.
[t_sensor, state_sensor, u_sensor] = reference_model(params);
step_figure = figure('Visible', 'off', 'Color', 'w');
tiledlayout(2, 1);
nexttile;
plot(t_sensor, state_sensor(:, 1), 'LineWidth', 1.3);
hold on;
yline(params.input.after / params.k, 'k--', 'x_ss = u/k');
xline(params.input.step_time, 'k:');
grid on;
xlabel('Time (s)');
ylabel('Displacement x');
title('Normalized MEMS-inspired sensor step response');
legend('x(t)', 'steady-state reference', 'Location', 'best');

nexttile;
plot(t_sensor, u_sensor, 'LineWidth', 1.2);
hold on;
plot(t_sensor, state_sensor(:, 2), 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Input / velocity');
title('Excitation and velocity');
legend('u(t)', 'y(t)', 'Location', 'best');
local_export(step_figure, fullfile(params.results_dir, ...
    'sensor_step_response.png'));

% Signal-chain plots use a deterministic noise seed for illustration only.
t_chain = linspace(params.t0, params.tfinal, 2001).';
[t_chain, chain] = signal_chain_reference(params, t_chain);

chain_figure = figure('Visible', 'off', 'Color', 'w');
tiledlayout(3, 1);
nexttile;
plot(t_chain, chain.x, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('x');
title('Mechanical displacement');

nexttile;
plot(t_chain, chain.v_ideal, 'LineWidth', 1.1);
hold on;
plot(t_chain, chain.v_raw, 'LineWidth', 0.8);
grid on;
xlabel('Time (s)');
ylabel('Signal');
title('Transduction, bias, and additive measurement noise');
legend('v_ideal', 'v_raw', 'Location', 'best');

nexttile;
plot(t_chain, chain.v_filtered, 'LineWidth', 1.2);
grid on;
xlabel('Time (s)');
ylabel('Filtered signal');
title('First-order low-pass filter output');
local_export(chain_figure, fullfile(params.results_dir, ...
    'signal_chain.png'));

calibrated_figure = figure('Visible', 'off', 'Color', 'w');
plot(t_chain, chain.y_cal, 'LineWidth', 1.3);
hold on;
plot(t_chain, chain.x, '--', 'LineWidth', 1.0);
grid on;
xlabel('Time (s)');
ylabel('Output');
title('Calibrated output versus normalized displacement');
legend('y_cal', 'x reference', 'Location', 'best');
local_export(calibrated_figure, fullfile(params.results_dir, ...
    'calibrated_output.png'));

if exist(params.model_files.sensor_dynamics, 'file') == 2
    % validate_model creates matlab_vs_simulink.png and reports local
    % numerical errors. Expected: curves should nearly overlap.
    validate_model(params);
else
    warning('generate_results:ValidationSkipped', ...
        ['Skipping matlab_vs_simulink.png because %s does not exist. ' ...
        'Run build_models(params) first.'], params.model_files.sensor_dynamics);
end

end

function local_export(figure_handle, output_file)
exportgraphics(figure_handle, output_file, 'Resolution', 150);
close(figure_handle);
end

