function generate_capacitive_transduction(params)
%GENERATE_CAPACITIVE_TRANSDUCTION Compare exact and linearized Delta C.

if nargin < 1
    params = init_params();
end
if exist(params.results_dir, 'dir') ~= 7
    mkdir(params.results_dir);
end

% Sweep almost to the pull-in/contact boundary to make the nonlinear
% correction visible. The main experiment occupies only a small central
% portion of this range.
displacement_ratio = linspace(-0.9, 0.9, 1201).';
xi = displacement_ratio .* params.capacitance.gap;
cap = capacitive_transduction(xi, params.capacitance);

[~, state] = reference_model(params);
main_ratio = params.capacitance.displacement_scale .* ...
    max(abs(state(:, 1))) ./ params.capacitance.gap;

relative_error = zeros(size(displacement_ratio));
nonzero = abs(cap.delta_c) > 0;
relative_error(nonzero) = 100 .* ...
    abs(cap.delta_c(nonzero) - cap.delta_c_linear(nonzero)) ./ ...
    abs(cap.delta_c(nonzero));

figure_handle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1120 760]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile;
plot(ax, displacement_ratio, cap.delta_c .* 1e15, ...
    'LineWidth', 1.4, 'DisplayName', 'Exact $\Delta C$');
hold on;
plot(ax, displacement_ratio, cap.delta_c_linear .* 1e15, '--', ...
    'LineWidth', 1.2, 'DisplayName', 'Linearized $\Delta C$');
xline(ax, -main_ratio, 'k:', 'HandleVisibility', 'off');
xline(ax, main_ratio, 'k:', 'HandleVisibility', 'off');
grid on;
xlabel(ax, '$\xi/d$', 'Interpreter', 'latex');
ylabel(ax, '$\Delta C$ (fF)', 'Interpreter', 'latex');
title(ax, 'Differential capacitance: exact model versus small-signal model');
legend(ax, 'Interpreter', 'latex', 'Location', 'northwest');
local_style_axes(ax);

ax = nexttile;
plot(ax, abs(displacement_ratio), relative_error, ...
    'LineWidth', 1.4, 'DisplayName', 'Relative error');
hold on;
xline(ax, main_ratio, 'k:', 'HandleVisibility', 'off');
grid on;
xlabel(ax, '$|\xi|/d$', 'Interpreter', 'latex');
ylabel(ax, 'Linearization error (%)');
title(ax, 'Small-signal validity improves as $|\xi|/d$ decreases', ...
    'Interpreter', 'latex');
legend(ax, 'Location', 'northwest');
xlim(ax, [0, 0.9]);
local_style_axes(ax);

annotation(figure_handle, 'textbox', [0.68 0.01 0.28 0.04], ...
    'String', sprintf('Main response: max |\\xi|/d = %.3g', main_ratio), ...
    'EdgeColor', 'none', 'HorizontalAlignment', 'right', ...
    'FontSize', 9);

local_export(figure_handle, fullfile(params.results_dir, ...
    'capacitive_transduction.png'));

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
