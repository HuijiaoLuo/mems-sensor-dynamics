function response = frequency_response(k, r, omega)
%FREQUENCY_RESPONSE Frequency response of the normalized sensor dynamics.
%
% The zero-initial-condition transfer function from input u to displacement
% x is
%
%     H(s) = X(s)/U(s) = 1/(s^2 + r*s + k).
%
% Evaluating at s = j*omega gives the sinusoidal steady-state response.

if nargin < 3
    omega = logspace(-2, 1.5, 1200).';
end

omega = omega(:);
if any(omega < 0)
    error('frequency_response:InvalidFrequency', ...
        'Angular frequency must be non-negative.');
end

denominator = k - omega.^2 + 1i .* r .* omega;
H = 1 ./ denominator;

response = struct();
response.omega = omega;
response.H = H;
response.magnitude = abs(H);
response.magnitude_db = 20 .* log10(response.magnitude);
response.phase_deg = unwrap(angle(H)) .* 180 ./ pi;
response.static_gain = 1 / k;

if k > 0
    response.natural_frequency = sqrt(k);
    response.damping_ratio = r / (2 * response.natural_frequency);
else
    response.natural_frequency = NaN;
    response.damping_ratio = NaN;
end

if r > 0
    response.quality_factor = response.natural_frequency / r;
    response.bandwidth_approx = r;
else
    response.quality_factor = Inf;
    response.bandwidth_approx = 0;
end

% A finite resonance peak exists for positive damping and
% 0 < zeta < 1/sqrt(2), equivalently r^2 < 2*k.
if r > 0 && k > 0 && r^2 < 2 * k
    response.resonance_frequency = sqrt(k - 0.5 * r^2);
    response.resonance_magnitude = 1 / ...
        (r * sqrt(k - 0.25 * r^2));
else
    response.resonance_frequency = NaN;
    response.resonance_magnitude = NaN;
end

end
