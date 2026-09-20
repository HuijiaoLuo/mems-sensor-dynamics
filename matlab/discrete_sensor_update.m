function state_next = discrete_sensor_update(state, input_value, Ad, Bd)
%DISCRETE_SENSOR_UPDATE Advance the code-generation state by one sample.
%
% This small function contains the operation that a generated target runs in
% its sample loop:
%   z[k+1] = Ad*z[k] + Bd*u[k].

state_next = Ad * state + Bd * input_value;

end
