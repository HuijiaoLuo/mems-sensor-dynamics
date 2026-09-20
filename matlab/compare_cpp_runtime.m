function report = compare_cpp_runtime(params)
%COMPARE_CPP_RUNTIME Compare generated C++ runtime output with MATLAB discrete reference.

if nargin < 1
    params = init_params();
end

% Repository root:
% .../mems-sensor-simulink/matlab/compare_cpp_runtime.m
%                    ↑ repo root
repo_root = fileparts(fileparts(mfilename('fullpath')));

csv_file = fullfile(repo_root, 'cpp', 'cpp_runtime.csv');

if exist(csv_file, 'file') ~= 2
    error('compare_cpp_runtime:MissingCSV', ...
        'C++ runtime CSV not found: %s', csv_file);
end

%% Load generated C++ runtime output
cpp = readtable(csv_file);

%% Generate MATLAB discrete reference
[t_matlab, state_matlab] = simulate_discrete_model(params);

%% Basic consistency checks
if height(cpp) ~= numel(t_matlab)
    error('compare_cpp_runtime:LengthMismatch', ...
        'C++ has %d samples, MATLAB has %d samples.', ...
        height(cpp), numel(t_matlab));
end

time_error = max(abs(cpp.time - t_matlab));

%% Numerical errors
error_x = cpp.x - state_matlab(:, 1);
error_y = cpp.y - state_matlab(:, 2);

report.max_abs_error_time = time_error;

report.max_abs_error_x = max(abs(error_x));
report.rms_error_x = sqrt(mean(error_x.^2));

report.max_abs_error_y = max(abs(error_y));
report.rms_error_y = sqrt(mean(error_y.^2));

%% Print report
fprintf('\nGenerated C++ vs MATLAB discrete reference\n');
fprintf('------------------------------------------\n');
fprintf('Samples          : %d\n', height(cpp));
fprintf('Max time error   : %.17g s\n', report.max_abs_error_time);
fprintf('x max abs error  : %.17g\n', report.max_abs_error_x);
fprintf('x RMS error      : %.17g\n', report.rms_error_x);
fprintf('y max abs error  : %.17g\n', report.max_abs_error_y);
fprintf('y RMS error      : %.17g\n', report.rms_error_y);

end