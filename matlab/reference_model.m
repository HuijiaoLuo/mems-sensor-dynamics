function [t, state, u] = reference_model(params)
%REFERENCE_MODEL Integrate the normalized sensor dynamics with ode45.
%
%   x_dot = y
%   y_dot = u(t) - k*x - r*y
%
% The input is a unit step at params.input.step_time by default. This is
% intentionally the same definition used by build_models.m. The dynamics
% themselves live in sensor_dynamics_model.m so the state equations can be
% inspected and reused independently.

if nargin < 1
    params = init_params();
end

u_fun = @(time) params.input.before + ...
    (params.input.after - params.input.before) .* ...
    (time >= params.input.step_time);

initial_state = [params.x0; params.y0];
step_time = params.input.step_time;

% Integrate on each side of the step separately. This prevents ode45 from
% stepping across the discontinuity and makes the reference comparison with
% Simulink more numerically meaningful.
if step_time > params.tspan(1) && step_time < params.tspan(end)
    rhs_before = @(time, state_vector) sensor_dynamics_model( ...
        time, state_vector, params.k, params.r, ...
        @(~) params.input.before);
    rhs_after = @(time, state_vector) sensor_dynamics_model( ...
        time, state_vector, params.k, params.r, ...
        @(~) params.input.after);

    [t_before, state_before] = ode45( ...
        rhs_before, [params.tspan(1), step_time], initial_state);
    [t_after, state_after] = ode45( ...
        rhs_after, [step_time, params.tspan(end)], state_before(end, :).');

    t = [t_before; t_after(2:end)];
    state = [state_before; state_after(2:end, :)];
else
    rhs = @(time, state_vector) sensor_dynamics_model( ...
        time, state_vector, params.k, params.r, u_fun);
    [t, state] = ode45(rhs, params.tspan, initial_state);
end

u = arrayfun(u_fun, t);

end
