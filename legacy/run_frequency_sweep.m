%% Frequency sweep using Simulink

clear;
clc;

model_name = 'sensor_frequency_sweep';

% Mechanical parameters
k = 1.2;
r = 0.2;
Ain = 1;

% Logarithmically spaced frequencies
omega_values = logspace(-1, 1, 20);

n_points = numel(omega_values);

measured_mag = zeros(n_points, 1);
theory_mag   = zeros(n_points, 1);

measured_phase = zeros(n_points, 1);
theory_phase   = zeros(n_points, 1);

mag_error = zeros(n_points, 1);
phase_error = zeros(n_points, 1);


%% Run all frequency points

for i = 1:n_points

    omega = omega_values(i);

    fprintf('\n====================================\n');
    fprintf('Point %d / %d\n', i, n_points);
    fprintf('====================================\n');

    result = measure_frequency_point( ...
        model_name, ...
        omega, ...
        k, ...
        r, ...
        Ain);

    measured_mag(i) = result.measured_magnitude;
    theory_mag(i) = result.theoretical_magnitude;

    measured_phase(i) = result.measured_phase_deg;
    theory_phase(i) = result.theoretical_phase_deg;

    mag_error(i) = result.magnitude_error_percent;
    phase_error(i) = result.phase_error_deg;

end


%% Convert magnitude to dB

measured_mag_db = 20*log10(measured_mag);
theory_mag_db   = 20*log10(theory_mag);


%% Plot magnitude response

figure;

semilogx(omega_values, theory_mag_db, ...
    'LineWidth', 1.5);

hold on;

semilogx(omega_values, measured_mag_db, ...
    'o', ...
    'LineWidth', 1.0);

grid on;

xlabel('\omega [rad/s]');
ylabel('|X/U| [dB]');

title('Mechanical frequency response');

legend( ...
    'Analytical', ...
    'Simulink measurement', ...
    'Location', 'best');


%% Plot phase response

figure;

semilogx(omega_values, theory_phase, ...
    'LineWidth', 1.5);

hold on;

semilogx(omega_values, measured_phase, ...
    'o', ...
    'LineWidth', 1.0);

grid on;

xlabel('\omega [rad/s]');
ylabel('Phase [deg]');

title('Mechanical phase response');

legend( ...
    'Analytical', ...
    'Simulink measurement', ...
    'Location', 'best');


%% Error summary

fprintf('\n\nSweep complete\n');
fprintf('====================================\n');

fprintf('Maximum magnitude error = %.5f %%\n', ...
    max(mag_error));

fprintf('Maximum phase error = %.5f deg\n', ...
    max(abs(phase_error)));