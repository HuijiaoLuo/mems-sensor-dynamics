function response = generate_frequency_response(params)
%GENERATE_FREQUENCY_RESPONSE Generate the frequency-response figure.

if nargin < 1
    params = init_params();
end

if ~isfield(params, 'frequency')
    params.frequency.omega_min = 1e-2;
    params.frequency.omega_max = 10^1.5;
    params.frequency.sample_count = 1200;
end

omega = logspace( ...
    log10(params.frequency.omega_min), ...
    log10(params.frequency.omega_max), ...
    params.frequency.sample_count).';
response = frequency_response(params.k, params.r, omega);

figure_handle = figure('Visible', 'off', 'Color', 'w', ...
    'Position', [100 100 1100 760]);
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax = nexttile;
response_line = semilogx(ax, response.omega, response.magnitude_db, ...
    'LineWidth', 1.4, 'DisplayName', '$|X/U|$');
hold(ax, 'on');
static_line = yline(ax, 20 * log10(response.static_gain), 'k--', ...
    'DisplayName', '$|H(0)|=1/k$');
natural_line = xline(ax, response.natural_frequency, 'k:', ...
    'DisplayName', '$\omega_n$');

if isfinite(response.resonance_frequency)
    resonance_line = xline(ax, response.resonance_frequency, 'r:', ...
        'DisplayName', '$\omega_r$');
    peak_marker = plot(ax, response.resonance_frequency, ...
        20 * log10(response.resonance_magnitude), 'ko', ...
        'MarkerFaceColor', 'k', 'DisplayName', 'resonance peak');
    legend(ax, [response_line, static_line, natural_line, resonance_line, ...
        peak_marker], ...
        'Interpreter', 'latex', 'Location', 'best');
else
    legend(ax, [response_line, static_line, natural_line], ...
        'Interpreter', 'latex', 'Location', 'best');
end
grid(ax, 'on');
xlabel(ax, '$\omega$ (rad/s)', 'Interpreter', 'latex');
ylabel(ax, '$20\log_{10}|X/U|$ (dB)', 'Interpreter', 'latex');
title(ax, sprintf('Displacement frequency response (Q = %.2f)', ...
    response.quality_factor));
local_style_axes(ax);

ax = nexttile;
semilogx(ax, response.omega, response.phase_deg, 'LineWidth', 1.4);
grid(ax, 'on');
xlabel(ax, '$\omega$ (rad/s)', 'Interpreter', 'latex');
ylabel(ax, '$\angle H(j\omega)$ (degrees)', 'Interpreter', 'latex');
title(ax, 'Phase response');
local_style_axes(ax);

results_dir = params.results_dir;
if exist(results_dir, 'dir') ~= 7
    mkdir(results_dir);
end
exportgraphics(figure_handle, ...
    fullfile(results_dir, 'frequency_response.png'), ...
    'Resolution', 150);
close(figure_handle);

fprintf(['Frequency response: wn = %.6g rad/s, zeta = %.6g, ' ...
    'Q = %.6g\n'], ...
    response.natural_frequency, response.damping_ratio, ...
    response.quality_factor);
if isfinite(response.resonance_frequency)
    fprintf('Resonance: wr = %.6g rad/s, |H(wr)| = %.6g\n', ...
        response.resonance_frequency, response.resonance_magnitude);
end

end

function local_style_axes(ax)
ax.FontName = 'Arial';
ax.FontSize = 10;
ax.LineWidth = 0.75;
ax.Box = 'on';
end
