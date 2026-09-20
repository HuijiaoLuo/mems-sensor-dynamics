function matrices = discretize_sensor_model(k, r, sample_time)
%DISCRETIZE_SENSOR_MODEL Exact zero-order-hold matrices for code generation.
%
% The continuous model is
%   x_dot = y
%   y_dot = u - k*x - r*y.
%
% The matrix exponential is evaluated offline.  The returned Ad and Bd
% matrices can then be placed in a Discrete State-Space block or passed to
% discrete_sensor_update.m.  The generated target code only performs the
% fixed-step state update; it does not need to calculate expm at runtime.

if nargin < 3 || sample_time <= 0
    error('discretize_sensor_model:InvalidSampleTime', ...
        'sample_time must be positive.');
end

A = [0, 1; -k, -r];
B = [0; 1];
augmented = [A, B; zeros(1, 3)];
discrete_augmented = expm(augmented .* sample_time);

matrices = struct();
matrices.Ad = discrete_augmented(1:2, 1:2);
matrices.Bd = discrete_augmented(1:2, 3);
matrices.Cd = eye(2);
matrices.Dd = zeros(2, 1);
matrices.sample_time = sample_time;

end
