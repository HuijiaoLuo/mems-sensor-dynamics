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
phase_figure = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1100 720]);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
phase_tspan = [0, 6];
for index = 1:numel(cases)
    rhs = @(time, state) cases(index).A * state;
    [~, state] = ode45(rhs, phase_tspan, [1; 0]);
    ax = nexttile;
    plot(ax, state(:, 1), state(:, 2), 'LineWidth', 1.1);
    grid on;
    xlabel(ax, 'x');
    ylabel(ax, 'y');
    title(ax, cases(index).name);
    local_style_axes(ax);

    % The unstable-node trajectory grows rapidly, so MATLAB may place a
    % 10^n y-axis offset directly beside the subplot title. Use ordinary
    % integer tick labels so the scale is readable and self-contained.
    if strcmp(cases(index).name, 'Unstable node')
        ax.XAxis.Exponent = 0;
        ax.YAxis.Exponent = 0;
        xtickformat(ax, '%.0f');
        ytickformat(ax, '%.0f');
    end
end
sgtitle(phase_figure, 'Second-order dynamic regimes');
local_export(phase_figure, fullfile(params.results_dir, ...
    'phase_portraits.png'));

% Eigenvalue-based damping/stability overview.
damping_figure = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1150 800]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile;
hold on;
for index = 1:numel(cases)
    lambda = cases(index).eigenvalues;
    plot(ax, real(lambda), imag(lambda), 'o', 'MarkerSize', 7, ...
        'DisplayName', cases(index).name);
end
xline(ax, 0, 'k:', 'HandleVisibility', 'off');
yline(ax, 0, 'k:', 'HandleVisibility', 'off');
grid on;
xlabel(ax, '$\mathrm{Re}(\lambda)$', 'Interpreter', 'latex');
ylabel(ax, '$\mathrm{Im}(\lambda)$', 'Interpreter', 'latex');
title(ax, 'Eigenvalue locations');
legend(ax, 'Location', 'eastoutside');
local_style_axes(ax);

ax = nexttile;
max_real_parts = zeros(1, numel(cases));
for index = 1:numel(cases)
    max_real_parts(index) = max(real(cases(index).eigenvalues));
end
bar(ax, max_real_parts);
hold on;
yline(ax, 0, 'k:', 'HandleVisibility', 'off');
grid on;
xticks(ax, 1:numel(cases));
xticklabels(ax, {cases.name});
xtickangle(ax, 25);
xlabel(ax, 'Regime');
ylabel(ax, '$\mathrm{max}\,\mathrm{Re}(\lambda)$', 'Interpreter', 'latex');
title(ax, 'Stability indicator from eigenvalues');
local_style_axes(ax);
local_export(damping_figure, fullfile(params.results_dir, ...
    'damping_regimes.png'));

% Main sensor step response.
[t_sensor, state_sensor, u_sensor] = reference_model(params);
step_figure = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1100 760]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile;
plot(ax, t_sensor, state_sensor(:, 1), 'LineWidth', 1.3);
hold on;
steady_state = params.input.after / params.k;
yline(ax, steady_state, 'k--', 'HandleVisibility', 'off');
label_index = max(1, round(0.62 * numel(t_sensor)));
text(ax, t_sensor(label_index), steady_state + 0.06, ...
    '$x_{\mathrm{ss}}=\frac{u}{k}$', ...
    'Interpreter', 'latex', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom');
xline(ax, params.input.step_time, 'k:', 'HandleVisibility', 'off');
grid on;
xlabel(ax, 'Time (s)');
ylabel(ax, 'Displacement $x$', 'Interpreter', 'latex');
title(ax, 'Normalized sensor step response');
legend(ax, '$x(t)$', 'Interpreter', 'latex', 'Location', 'best');
local_style_axes(ax);

ax = nexttile;
plot(ax, t_sensor, u_sensor, 'LineWidth', 1.2);
hold on;
plot(ax, t_sensor, state_sensor(:, 2), 'LineWidth', 1.2);
grid on;
xlabel(ax, 'Time (s)');
ylabel(ax, 'Amplitude');
title(ax, 'Excitation and velocity');
legend(ax, '$u(t)$', '$y(t)$', 'Interpreter', 'latex', ...
    'Location', 'best');
local_style_axes(ax);
local_export(step_figure, fullfile(params.results_dir, ...
    'sensor_step_response.png'));

% Signal-chain plots use a deterministic noise seed for illustration only.
t_chain = linspace(params.t0, params.tfinal, 2001).';
[t_chain, chain] = signal_chain_reference(params, t_chain);

chain_figure = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1100 900]);
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
ax = nexttile;
plot(ax, t_chain, chain.x, 'LineWidth', 1.2);
grid on;
xlabel(ax, 'Time (s)');
ylabel(ax, '$x$', 'Interpreter', 'latex');
title(ax, 'Mechanical displacement');
local_style_axes(ax);

ax = nexttile;
plot(ax, t_chain, chain.v_abstract, '--', 'LineWidth', 1.0);
hold on;
plot(ax, t_chain, chain.v_capacitive_linear, 'LineWidth', 1.0);
plot(ax, t_chain, chain.v_capacitive, 'LineWidth', 1.2);
plot(ax, t_chain, chain.v_raw, 'LineWidth', 0.8);
grid on;
xlabel(ax, 'Time (s)');
ylabel(ax, 'Signal');
title(ax, 'Abstract and capacitive transduction with measurement noise');
legend(ax, '$v_{\mathrm{abstract}}=Gx$', ...
    '$v_{\mathrm{cap,linear}}$', '$v_{\mathrm{cap,exact}}$', ...
    '$v_{\mathrm{raw}}$', ...
    'Interpreter', 'latex', 'Location', 'best');
local_style_axes(ax);

ax = nexttile;
plot(ax, t_chain, chain.v_filtered, 'LineWidth', 1.2);
grid on;
xlabel(ax, 'Time (s)');
ylabel(ax, 'Filtered signal');
title(ax, 'First-order low-pass filter output');
local_style_axes(ax);
local_export(chain_figure, fullfile(params.results_dir, ...
    'signal_chain.png'));

calibrated_figure = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1100 500]);
ax = axes(calibrated_figure);
plot(ax, t_chain, chain.y_cal, 'LineWidth', 1.3);
hold on;
plot(ax, t_chain, chain.x, '--', 'LineWidth', 1.0);
grid on;
xlabel(ax, 'Time (s)');
ylabel(ax, 'Normalized output');
title(ax, 'Calibrated output and displacement reference');
legend(ax, '$y_{\mathrm{cal}}$', '$x(t)$', 'Interpreter', 'latex', ...
    'Location', 'best');
local_style_axes(ax);
local_export(calibrated_figure, fullfile(params.results_dir, ...
    'calibrated_output.png'));

% Analytical frequency response of the normalized mechanical dynamics.
generate_capacitive_transduction(params);
generate_readout_frontend(params);
generate_frequency_response(params);

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

function local_style_axes(ax)
ax.FontName = 'Arial';
ax.FontSize = 10;
ax.LineWidth = 0.75;
ax.Box = 'on';
end
