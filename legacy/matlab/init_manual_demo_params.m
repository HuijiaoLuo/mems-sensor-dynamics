%% Manual MEMS / Simulink demo parameters
%
% Shared Base Workspace parameters for the hand-built legacy models.
% These are illustrative educational values, not parameters of a
% commercial MEMS device.
%
% Run this script before opening/running the manual Simulink models:
%
%   run('legacy/matlab/init_manual_demo_params.m')


%% ============================================================
%  1. Mechanical second-order system
%     x_dot = y
%     y_dot = u - k*x - r*y
% =============================================================

k = 1.2;              % normalized stiffness
r = 0.2;              % normalized damping

x0 = 0;               % initial normalized displacement
y0 = 0;               % initial normalized velocity


%% ============================================================
%  2. Step excitation
% =============================================================

step_time = 1;        % s
u_before = 0;
u_after  = 1;


%% ============================================================
%  3. Sinusoidal excitation / frequency-response experiments
% =============================================================

Ain = 1;              % sinusoidal input amplitude
omega = 0.3;          % rad/s; manually change for sine experiments

% Useful manual test values:
% omega = 0.3;        % below resonance
% omega = 1.1;        % near resonance
% omega = 3.0;        % above resonance


%% ============================================================
%  4. Normalized -> physical displacement
% =============================================================

alpha_x_small_signal = 0.2e-6;   % m / normalized displacement unit
alpha_x_nonlinear    = 0.6e-6;   % used to demonstrate nonlinearity

alpha_x = alpha_x_small_signal;


%% ============================================================
%  5. Differential capacitive MEMS geometry
% =============================================================

d = 2e-6;                         % nominal gap [m]

A_electrode = (100e-6)^2;        % electrode area [m^2]

epsilon0 = 8.8541878128e-12;     % vacuum permittivity [F/m]
epsilon_r = 1;                    % simplified air/vacuum dielectric
epsilon = epsilon0 * epsilon_r;

epsA = epsilon * A_electrode;     % epsilon*A [F*m]

C0 = epsA / d;                    % nominal single-sided capacitance [F]

S_C = 2 * epsilon * A_electrode / d^2;
% Small-signal differential capacitive sensitivity [F/m]
%
% DeltaC_linear = S_C * xi


%% ============================================================
%  6. Ideal capacitance-to-voltage readout
% =============================================================

G_C = 1e12;                       % C-to-V gain [V/F]


%% ============================================================
%  7. Front-end DC offset
% =============================================================

V_offset = 0.02;                  % illustrative front-end offset [V]


%% ============================================================
%  8. Additive front-end noise
% =============================================================

noise_sigma = 1e-3;               % illustrative RMS noise [V]
noise_variance = noise_sigma^2;

noise_Ts = 0.01;                  % noise sample time [s]
noise_seed = 7;                   % deterministic/reproducible noise


%% ============================================================
%  9. Analog front-end bandwidth
% =============================================================

tau_amp_default = 0.05;           % s
tau_amp_strong_filter = 0.20;     % s, useful for visual comparison

tau_amp = tau_amp_default;

% First-order front-end model:
%
% H_amp(s) = 1 / (tau_amp*s + 1)
%
% Approximate cutoff:
% f_c = 1 / (2*pi*tau_amp)


%% ============================================================
%  10. Amplifier output rails
% =============================================================

V_min = 0.0;                      % V
V_max = 0.030;                    % V
% Intentionally narrow educational range to demonstrate clipping.


%% ============================================================
%  11. ADC
% =============================================================

N_adc = 8;                        % ADC resolution [bits]

V_adc_min = 0.0;                  % ADC input minimum [V]
V_adc_max = 0.030;                % ADC input maximum [V]

q_adc = ...
    (V_adc_max - V_adc_min) / (2^N_adc - 1);
% ADC LSB / quantization step [V/code]


%% ============================================================
%  12. Digital calibration
% =============================================================

V_offset_est = V_offset;          % ideal offset estimate for first demo

% Reconstruction chain used in the manual model:
%
% v_corrected = v_adc_reconstructed - V_offset_est
%
% DeltaC_hat = v_corrected / G_C
%
% xi_hat = DeltaC_hat / S_C
%
% x_hat = xi_hat / alpha_x


%% ============================================================
%  13. Simulation
% =============================================================

Tsim = 20;                        % default manual-demo stop time [s]


%% ============================================================
%  14. Derived quantities for reference
% =============================================================

omega_n = sqrt(k);
zeta = r / (2*sqrt(k));
Q_approx = 1 / (2*zeta);

f_amp_cutoff = 1 / (2*pi*tau_amp);

fprintf('\nManual MEMS demo parameters loaded.\n');
fprintf('-----------------------------------\n');
fprintf('Natural frequency        : %.4f rad/s\n', omega_n);
fprintf('Damping ratio            : %.4f\n', zeta);
fprintf('Approximate Q            : %.4f\n', Q_approx);
fprintf('Nominal capacitance C0   : %.3f fF\n', C0*1e15);
fprintf('Capacitive sensitivity   : %.3e F/m\n', S_C);
fprintf('ADC LSB                  : %.3f mV/code\n', q_adc*1e3);
fprintf('Amplifier cutoff         : %.3f Hz\n', f_amp_cutoff);
fprintf('alpha_x                  : %.3f um/unit\n', alpha_x*1e6);
fprintf('\n');