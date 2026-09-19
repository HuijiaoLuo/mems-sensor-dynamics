function report = validate_model(params)
%VALIDATE_MODEL Compare the MATLAB reference model with Simulink.
%
% The exact numerical values are intentionally produced only when this
% function is run locally in MATLAB/Simulink.

if nargin < 1
    params = init_params();
end

model_file = params.model_files.sensor_dynamics;
if exist(model_file, 'file') ~= 2
    error('validate_model:MissingModel', ...
        ['Missing %s. Run build_models(params) locally in MATLAB first.'], ...
        model_file);
end

[t_reference, state_reference] = reference_model(params);
sim_output = sim(model_file, ...
    'ReturnWorkspaceOutputs', 'on', ...
    'StopTime', num2str(params.tfinal));

x_signal = sim_output.get('x_sim');
y_signal = sim_output.get('y_sim');
[t_simulation, x_simulation] = local_extract_timeseries(x_signal);
[t_simulation_y, y_simulation] = local_extract_timeseries(y_signal);

% Use one common vector so the comparison does not depend on solver output
% time steps. Expected: MATLAB and Simulink curves should nearly overlap.
t_start = max([t_reference(1), t_simulation(1), t_simulation_y(1)]);
t_end = min([t_reference(end), t_simulation(end), t_simulation_y(end)]);
t_common = linspace(t_start, t_end, 1001).';

x_reference_common = interp1(t_reference, state_reference(:, 1), ...
    t_common, 'linear');
y_reference_common = interp1(t_reference, state_reference(:, 2), ...
    t_common, 'linear');
x_simulation_common = interp1(t_simulation, x_simulation, ...
    t_common, 'linear');
y_simulation_common = interp1(t_simulation_y, y_simulation, ...
    t_common, 'linear');

x_error = x_reference_common - x_simulation_common;
y_error = y_reference_common - y_simulation_common;

report = struct();
report.max_abs_error_x = max(abs(x_error));
report.rms_error_x = sqrt(mean(x_error.^2));
report.max_abs_error_y = max(abs(y_error));
report.rms_error_y = sqrt(mean(y_error.^2));
report.t = t_common;
report.reference = [x_reference_common, y_reference_common];
report.simulink = [x_simulation_common, y_simulation_common];

fprintf('x(t): max absolute error = %.6g, RMS error = %.6g\n', ...
    report.max_abs_error_x, report.rms_error_x);
fprintf('y(t): max absolute error = %.6g, RMS error = %.6g\n', ...
    report.max_abs_error_y, report.rms_error_y);
fprintf('Check the reported numerical error after local execution.\n');

if exist(params.results_dir, 'dir') ~= 7
    mkdir(params.results_dir);
end

figure_handle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1100 760]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile;
plot(ax, t_common, x_reference_common, 'LineWidth', 1.4);
hold on;
plot(ax, t_common, x_simulation_common, '--', 'LineWidth', 1.2);
grid on;
xlabel(ax, 'Time (s)');
ylabel(ax, 'Displacement $x$', 'Interpreter', 'latex');
title(ax, {'MATLAB reference versus Simulink: $x(t)$', ...
    sprintf('max abs = %.2e, RMS = %.2e', ...
    report.max_abs_error_x, report.rms_error_x)}, ...
    'Interpreter', 'latex');
legend(ax, 'MATLAB / ode45', 'Simulink', 'Location', 'best');
local_style_axes(ax);

ax = nexttile;
plot(ax, t_common, y_reference_common, 'LineWidth', 1.4);
hold on;
plot(ax, t_common, y_simulation_common, '--', 'LineWidth', 1.2);
grid on;
xlabel(ax, 'Time (s)');
ylabel(ax, 'Velocity $y$', 'Interpreter', 'latex');
title(ax, {'MATLAB reference versus Simulink: $y(t)$', ...
    sprintf('max abs = %.2e, RMS = %.2e', ...
    report.max_abs_error_y, report.rms_error_y)}, ...
    'Interpreter', 'latex');
legend(ax, 'MATLAB / ode45', 'Simulink', 'Location', 'best');
local_style_axes(ax);

exportgraphics(figure_handle, ...
    fullfile(params.results_dir, 'matlab_vs_simulink.png'), ...
    'Resolution', 150);
close(figure_handle);

end

function local_style_axes(ax)
ax.FontName = 'Arial';
ax.FontSize = 10;
ax.LineWidth = 0.75;
ax.Box = 'on';
end

function [t, data] = local_extract_timeseries(signal)
if isa(signal, 'timeseries')
    t = signal.Time(:);
    data = signal.Data(:);
elseif isstruct(signal) && isfield(signal, 'time')
    t = signal.time(:);
    data = signal.signals.values(:);
else
    error('validate_model:UnsupportedLogFormat', ...
        'Expected a Timeseries or Structure With Time log.');
end
end
