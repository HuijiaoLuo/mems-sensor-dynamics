function cap = capacitive_transduction(displacement, capacitance)
%CAPACITIVE_TRANSDUCTION Evaluate a simplified differential capacitive sensor.
%
%   displacement is the physical proof-mass displacement xi in metres.
%   capacitance must contain epsilon, electrode_area, and gap.
%
% The exact parallel-plate model is
%   C1 = epsilon*A/(d-xi),  C2 = epsilon*A/(d+xi).
% The returned linearized differential capacitance is the small-signal
% approximation around xi = 0.

required_fields = {'epsilon', 'electrode_area', 'gap'};
for index = 1:numel(required_fields)
    if ~isfield(capacitance, required_fields{index})
        error('capacitive_transduction:MissingParameter', ...
            'Missing capacitance parameter: %s.', required_fields{index});
    end
end

epsilon = capacitance.epsilon;
area = capacitance.electrode_area;
gap = capacitance.gap;

if epsilon <= 0 || area <= 0 || gap <= 0
    error('capacitive_transduction:InvalidParameter', ...
        'epsilon, electrode_area, and gap must all be positive.');
end

if any(abs(displacement(:)) >= gap)
    error('capacitive_transduction:GapViolation', ...
        'The model requires abs(displacement) < gap.');
end

capacitance_scale = epsilon .* area;
c1 = capacitance_scale ./ (gap - displacement);
c2 = capacitance_scale ./ (gap + displacement);
sensitivity = 2 .* capacitance_scale ./ gap.^2;

cap = struct();
cap.displacement = displacement;
cap.c1 = c1;
cap.c2 = c2;
cap.delta_c = c1 - c2;
cap.delta_c_linear = sensitivity .* displacement;
cap.common_mode = c1 + c2;
cap.sensitivity = sensitivity;

end
