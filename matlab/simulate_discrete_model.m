function [time, state, input_trace, matrices] = simulate_discrete_model(params)
%SIMULATE_DISCRETE_MODEL Run the fixed-step normalized sensor model.
%
% The input is held constant over each sample interval.  This function is a
% transparent MATLAB reference for the Discrete State-Space Simulink model
% and for the generated C/C++ algorithm.

if nargin < 1
    params = init_params();
end

sample_time = params.codegen.sample_time;
interval = params.tspan(2) - params.tspan(1);
sample_count = round(interval / sample_time);
if abs(sample_count * sample_time - interval) > 1e-12
    error('simulate_discrete_model:NonIntegerSampleCount', ...
        'The simulation interval must be an integer multiple of sample_time.');
end

matrices = discretize_sensor_model(params.k, params.r, sample_time);
time = (params.tspan(1) + (0:sample_count) .* sample_time).';
state = zeros(numel(time), 2);
state(1, :) = [params.x0, params.y0];

input_trace = arrayfun(@(current_time) local_step_input( ...
    current_time, params), time);

for index = 1:sample_count
    state(index + 1, :) = discrete_sensor_update( ...
        state(index, :).', input_trace(index), matrices.Ad, matrices.Bd).';
end

end

function value = local_step_input(time, params)
if time >= params.input.step_time
    value = params.input.after;
else
    value = params.input.before;
end
end
