%% Analyze one frequency-response point

% Current model parameters
% Expected to exist in workspace:
% k, r, omega, Tsim, u_log, x_log

% Excitation period
T = 2*pi/omega;

% Use the final two periods as approximate steady state
n_periods = 2;
t_start = Tsim - n_periods*T;

% Extract steady-state samples
idx_u = u_log.Time >= t_start;
idx_x = x_log.Time >= t_start;

u_ss = u_log.Data(idx_u);
x_ss = x_log.Data(idx_x);

% Estimate amplitudes from peak-to-peak values
A_u = (max(u_ss) - min(u_ss))/2;
A_x = (max(x_ss) - min(x_ss))/2;

% Measured frequency-response magnitude
H_measured = A_x / A_u;

% Analytical magnitude
H_theory = 1 / sqrt((k - omega^2)^2 + (r*omega)^2);

% Error
relative_error_percent = ...
    100 * abs(H_measured - H_theory) / H_theory;

% Print result
fprintf('\nFrequency-response analysis\n');
fprintf('---------------------------\n');
fprintf('omega               = %.4f rad/s\n', omega);
fprintf('period              = %.4f s\n', T);
fprintf('input amplitude     = %.6f\n', A_u);
fprintf('output amplitude    = %.6f\n', A_x);
fprintf('measured |H|        = %.6f\n', H_measured);
fprintf('theoretical |H|     = %.6f\n', H_theory);
fprintf('relative error      = %.3f %%\n', relative_error_percent);