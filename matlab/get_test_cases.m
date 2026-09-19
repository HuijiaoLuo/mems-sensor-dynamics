function cases = get_test_cases()
%GET_TEST_CASES Return the requested second-order dynamic regimes.

names = {'Stable focus', 'Center', 'Unstable focus', ...
    'Stable node', 'Unstable node', 'Saddle'};
k_values = [1.2, 1.2, 1.2, 1.2, 1.2, -0.5];
r_values = [0.2, 0, -0.2, 2.5, -2.5, 0.2];

cases = repmat(struct( ...
    'name', '', 'k', 0, 'r', 0, 'A', zeros(2), ...
    'eigenvalues', zeros(2, 1), 'classification', ''), 1, numel(names));

for index = 1:numel(names)
    A = [0, 1; -k_values(index), -r_values(index)];
    lambda = eig(A);

    cases(index).name = names{index};
    cases(index).k = k_values(index);
    cases(index).r = r_values(index);
    cases(index).A = A;
    cases(index).eigenvalues = lambda;
    cases(index).classification = local_classify(lambda, A);
end

end

function label = local_classify(lambda, A)
tol = 1e-10;

if det(A) < -tol
    label = 'Saddle';
    return;
end

if any(abs(imag(lambda)) > tol)
    real_part = real(lambda(1));
    if abs(real_part) <= tol
        label = 'Center';
    elseif real_part < 0
        label = 'Stable focus';
    else
        label = 'Unstable focus';
    end
    return;
end

if max(real(lambda)) < -tol
    label = 'Stable node';
elseif min(real(lambda)) > tol
    label = 'Unstable node';
else
    label = 'Degenerate / marginal';
end

end

