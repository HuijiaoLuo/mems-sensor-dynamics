function generate_readout_frontend(params)
%GENERATE_READOUT_FRONTEND Plot the ideal mixed-signal readout chain.

if nargin < 1
    params = init_params();
end
if exist(params.results_dir, 'dir') ~= 7
    mkdir(params.results_dir);
end

t = linspace(params.t0, params.tfinal, 2001).';
[~, chain] = signal_chain_reference(params, t);
frontend = chain.frontend;

figure_handle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1120 900]);
tiledlayout(3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile;
plot(ax, t, frontend.v_sensor, 'LineWidth', 1.2, ...
    'DisplayName', '$G_C\Delta C$');
hold on;
plot(ax, t, frontend.v_input, 'LineWidth', 0.8, ...
    'DisplayName', '$G_C\Delta C+V_{\mathrm{offset}}+n$');
grid on;
xlabel(ax, 'Time (s)');
ylabel(ax, 'Voltage (V)');
title(ax, 'Capacitive readout voltage and analogue nonidealities');
legend(ax, 'Interpreter', 'latex', 'Location', 'best');
local_style_axes(ax);

ax = nexttile;
plot(ax, t, frontend.v_bandlimited, 'LineWidth', 1.2, ...
    'DisplayName', 'Finite-bandwidth output');
hold on;
plot(ax, t, frontend.v_amplifier, 'LineWidth', 1.1, ...
    'DisplayName', 'Saturated amplifier output');
yline(ax, params.readout.amplifier_min, 'k:', ...
    'HandleVisibility', 'off');
yline(ax, params.readout.amplifier_max, 'k:', ...
    'HandleVisibility', 'off');
grid on;
xlabel(ax, 'Time (s)');
ylabel(ax, 'Voltage (V)');
title(ax, 'Finite bandwidth and amplifier rails');
legend(ax, 'Location', 'best');
local_style_axes(ax);

ax = nexttile;
yyaxis(ax, 'left');
plot(ax, t, frontend.adc_code, 'LineWidth', 1.0, ...
    'DisplayName', 'ADC code');
ylabel(ax, sprintf('ADC code (%d-bit)', params.readout.adc_bits));
ylim(ax, [0, 2^params.readout.adc_bits - 1]);
yyaxis(ax, 'right');
plot(ax, t, frontend.x_calibrated, 'LineWidth', 1.2, ...
    'DisplayName', 'Calibrated displacement');
hold on;
plot(ax, t, chain.x, '--', 'LineWidth', 1.0, ...
    'DisplayName', 'Mechanical displacement reference');
ylabel(ax, 'Normalized displacement');
grid on;
xlabel(ax, 'Time (s)');
title(ax, 'ADC quantization and digital calibration');
legend(ax, 'Location', 'best');
local_style_axes(ax);

local_export(figure_handle, fullfile(params.results_dir, ...
    'readout_frontend.png'));

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
