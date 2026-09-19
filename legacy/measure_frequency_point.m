function result = measure_frequency_point(model_name, omega, k, r, Ain)
%MEASURE_FREQUENCY_POINT Measure one Simulink frequency-response point.
%
% The mechanical system is
%
%       x'' + r*x' + k*x = u(t)
%
% with sinusoidal excitation
%
%       u(t) = Ain*sin(omega*t).
%
% The function:
%   1. determines a suitable simulation time,
%   2. runs the Simulink model,
%   3. extracts the steady-state part,
%   4. fits sinusoids to u(t) and x(t),
%   5. calculates measured magnitude and phase,
%   6. compares them with the analytical transfer function.


%% Initial conditions

x0 = 0;
y0 = 0;


%% 1. System poles and transient decay time

A = [0 1;
    -k -r];

poles = eig(A);

if max(real(poles)) >= 0
    error(['Frequency-response measurement requires a stable system. ' ...
           'Current poles are not strictly stable.']);
end

% Slowest exponential decay rate
decay_rate = -max(real(poles));

% Wait approximately five time constants for transients to decay
t_settle = 5 / decay_rate;


%% 2. Excitation period and simulation time

T = 2*pi / omega;

% Measure the last five complete periods
n_measure_periods = 5;

measurement_time = n_measure_periods * T;

Tsim = t_settle + measurement_time;


%% 3. Configure and run Simulink

simIn = Simulink.SimulationInput(model_name);

simIn = simIn.setVariable('omega', omega);
simIn = simIn.setVariable('Ain', Ain);

simIn = simIn.setVariable('k', k);
simIn = simIn.setVariable('r', r);

simIn = simIn.setVariable('x0', x0);
simIn = simIn.setVariable('y0', y0);

simIn = simIn.setModelParameter( ...
    'StopTime', num2str(Tsim));

simOut = sim(simIn);


%% 4. Retrieve logged signals

u_log = simOut.get('u_log');
x_log = simOut.get('x_log');

t_u = u_log.Time(:);
u = u_log.Data(:);

t_x = x_log.Time(:);
x = x_log.Data(:);


%% 5. Keep only the final steady-state periods

t_measure_start = Tsim - measurement_time;

mask_u = t_u >= t_measure_start;
mask_x = t_x >= t_measure_start;

t_u_ss = t_u(mask_u);
u_ss = u(mask_u);

t_x_ss = t_x(mask_x);
x_ss = x(mask_x);


%% 6. Fit steady-state sinusoids

[A_u, phi_u] = local_fit_sine(t_u_ss, u_ss, omega);
[A_x, phi_x] = local_fit_sine(t_x_ss, x_ss, omega);


%% 7. Measured frequency response

H_measured = A_x / A_u;

phase_measured = phi_x - phi_u;

% Wrap phase to [-pi, pi]
phase_measured = atan2( ...
    sin(phase_measured), ...
    cos(phase_measured));


%% 8. Analytical frequency response

s = 1i * omega;

H_theory_complex = 1 / (s^2 + r*s + k);

H_theory = abs(H_theory_complex);
phase_theory = angle(H_theory_complex);


%% 9. Errors

magnitude_error_percent = ...
    100 * abs(H_measured - H_theory) / H_theory;

phase_error = phase_measured - phase_theory;

phase_error = atan2( ...
    sin(phase_error), ...
    cos(phase_error));


%% 10. Return results

result.omega = omega;
result.period = T;
result.simulation_time = Tsim;

result.poles = poles;

result.input_amplitude = A_u;
result.output_amplitude = A_x;

result.measured_magnitude = H_measured;
result.theoretical_magnitude = H_theory;

result.measured_phase_deg = rad2deg(phase_measured);
result.theoretical_phase_deg = rad2deg(phase_theory);

result.magnitude_error_percent = magnitude_error_percent;
result.phase_error_deg = rad2deg(phase_error);


%% 11. Print summary

fprintf('\nFrequency response at omega = %.4f rad/s\n', omega);
fprintf('------------------------------------------------\n');
fprintf('Simulation time       : %.3f s\n', Tsim);
fprintf('Input amplitude       : %.6f\n', A_u);
fprintf('Output amplitude      : %.6f\n', A_x);
fprintf('\n');
fprintf('Measured |H|          : %.6f\n', H_measured);
fprintf('Theoretical |H|       : %.6f\n', H_theory);
fprintf('Magnitude error       : %.4f %%\n', magnitude_error_percent);
fprintf('\n');
fprintf('Measured phase        : %.3f deg\n', ...
    result.measured_phase_deg);
fprintf('Theoretical phase     : %.3f deg\n', ...
    result.theoretical_phase_deg);
fprintf('Phase error           : %.3f deg\n', ...
    result.phase_error_deg);

end


function [amplitude, phase] = local_fit_sine(t, signal, omega)
%LOCAL_FIT_SINE Fit
%
%   signal(t) = a*sin(omega*t) + b*cos(omega*t) + c
%
% by least squares.

M = [ ...
    sin(omega*t), ...
    cos(omega*t), ...
    ones(size(t))];

coefficients = M \ signal;

a = coefficients(1);
b = coefficients(2);

amplitude = hypot(a, b);

phase = atan2(b, a);

end