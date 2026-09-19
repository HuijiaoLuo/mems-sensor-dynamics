function [t, state, u] = reference_model(params)
%REFERENCE_MODEL Integrate the normalized sensor dynamics with ode45.
%
%   x_dot = y
%   y_dot = u(t) - k*x - r*y
%
% The input is a unit step at params.input.step_time by default. This is
% intentionally the same definition used by build_models.m.

if nargin < 1
    params = init_params();
end

u_fun = @(time) params.input.before + ...
    (params.input.after - params.input.before) .* ...
    (time >= params.input.step_time);

rhs = @(time, state_vector) [ ...
    state_vector(2); ...
    u_fun(time) - params.k * state_vector(1) - params.r * state_vector(2)];

[t, state] = ode45(rhs, params.tspan, [params.x0; params.y0]);
u = arrayfun(u_fun, t);

end

