function report = generate_discrete_results(params)
%GENERATE_DISCRETE_RESULTS Compare fixed-step and continuous trajectories.

if nargin < 1
    params = init_params();
end

[t_discrete, state_discrete] = simulate_discrete_model(params);
[t_reference, state_reference] = reference_model(params);

x_reference = interp1(t_reference, state_reference(:, 1), ...
    t_discrete, 'linear');
y_reference = interp1(t_reference, state_reference(:, 2), ...
    t_discrete, 'linear');

report = struct();
report.max_abs_error_x = max(abs(x_reference - state_discrete(:, 1)));
report.rms_error_x = sqrt(mean((x_reference - state_discrete(:, 1)).^2));
report.max_abs_error_y = max(abs(y_reference - state_discrete(:, 2)));
report.rms_error_y = sqrt(mean((y_reference - state_discrete(:, 2)).^2));
report.sample_time = params.codegen.sample_time;

fprintf(['Discrete model Ts = %.6g s: x max abs = %.6g, x RMS = %.6g\n'], ...
    report.sample_time, report.max_abs_error_x, report.rms_error_x);
fprintf(['Discrete model Ts = %.6g s: y max abs = %.6g, y RMS = %.6g\n'], ...
    report.sample_time, report.max_abs_error_y, report.rms_error_y);

if exist(params.results_dir, 'dir') ~= 7
    mkdir(params.results_dir);
end

figure_handle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1100 760]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile;
plot(ax, t_reference, state_reference(:, 1), 'LineWidth', 1.3);
hold(ax, 'on');
plot(ax, t_discrete, state_discrete(:, 1), '.', 'MarkerSize', 4);
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, '$x$', 'Interpreter', 'latex');
title(ax, 'Continuous reference versus fixed-step model: displacement');
legend(ax, 'Continuous / ode45', 'Discrete / zero-order hold', ...
    'Location', 'best');
local_style_axes(ax);

ax = nexttile;
plot(ax, t_reference, state_reference(:, 2), 'LineWidth', 1.3);
hold(ax, 'on');
plot(ax, t_discrete, state_discrete(:, 2), '.', 'MarkerSize', 4);
grid(ax, 'on');
xlabel(ax, 'Time (s)');
ylabel(ax, '$y$', 'Interpreter', 'latex');
title(ax, 'Continuous reference versus fixed-step model: velocity');
legend(ax, 'Continuous / ode45', 'Discrete / zero-order hold', ...
    'Location', 'best');
local_style_axes(ax);

exportgraphics(figure_handle, ...
    fullfile(params.results_dir, 'discrete_vs_continuous.png'), ...
    'Resolution', 150);
close(figure_handle);

end

function local_style_axes(ax)
ax.FontName = 'Arial';
ax.FontSize = 10;
ax.LineWidth = 0.75;
ax.Box = 'on';
end
