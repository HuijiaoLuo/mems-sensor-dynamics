function report = validate_cpp_vs_simulink(params)
%VALIDATE_CPP_VS_SIMULINK
% Run the generated C++ executable and numerically compare its trajectory
% against the fixed-step Simulink code-generation model.

if nargin < 1
    params = init_params();
end

%% Paths
repo_root = fileparts(fileparts(mfilename('fullpath')));

exe_file = fullfile(repo_root, 'cpp', 'sensor_codegen_test.exe');
csv_file = fullfile(repo_root, 'cpp', 'cpp_runtime.csv');

if exist(exe_file, 'file') ~= 2
    error('validate_cpp_vs_simulink:MissingExecutable', ...
        'C++ executable not found: %s', exe_file);
end

%% 1. Run generated C++ executable
if ispc
    command = sprintf('cd /d "%s" && "%s"', repo_root, exe_file);
else
    command = sprintf('cd "%s" && "%s"', repo_root, exe_file);
end

[status, command_output] = system(command);

if status ~= 0
    error('validate_cpp_vs_simulink:CppRuntimeFailed', ...
        'C++ executable failed:\n%s', command_output);
end

fprintf('%s', command_output);

if exist(csv_file, 'file') ~= 2
    error('validate_cpp_vs_simulink:MissingCSV', ...
        'C++ runtime did not create: %s', csv_file);
end

cpp = readtable(csv_file);

required_columns = {'time', 'x', 'y'};
if ~all(ismember(required_columns, cpp.Properties.VariableNames))
    error('validate_cpp_vs_simulink:MissingColumns', ...
        'C++ runtime CSV must contain time, x, and y columns.');
end

%% 2. Run fixed-step Simulink model
model_file = params.model_files.codegen;

if exist(model_file, 'file') ~= 2
    error('validate_cpp_vs_simulink:MissingModel', ...
        'Simulink model not found: %s', model_file);
end

[~, model_name] = fileparts(model_file);

load_system(model_file);
cleanup = onCleanup(@() close_system(model_name, 0));

sim_in = Simulink.SimulationInput(model_name);

sim_in = sim_in.setModelParameter( ...
    'StartTime', num2str(params.tspan(1), '%.17g'), ...
    'StopTime',  num2str(params.tspan(2), '%.17g'), ...
    'SaveOutput', 'on', ...
    'OutputSaveName', 'yout', ...
    'SaveFormat', 'Dataset');

sim_out = sim(sim_in);

x_sig = sim_out.yout{1};
y_sig = sim_out.yout{2};

t_sim = x_sig.Values.Time;
x_sim = x_sig.Values.Data(:);
y_sim = y_sig.Values.Data(:);

%% 3. Structural checks
if height(cpp) ~= numel(t_sim)
    error('validate_cpp_vs_simulink:LengthMismatch', ...
        'C++ has %d samples, Simulink has %d samples.', ...
        height(cpp), numel(t_sim));
end

%% 4. Numerical comparison
error_t = cpp.time - t_sim;
error_x = cpp.x - x_sim;
error_y = cpp.y - y_sim;

report.samples = height(cpp);

report.max_abs_error_time = max(abs(error_t));

report.max_abs_error_x = max(abs(error_x));
report.rms_error_x = sqrt(mean(error_x.^2));

report.max_abs_error_y = max(abs(error_y));
report.rms_error_y = sqrt(mean(error_y.^2));

%% 5. Tolerances
time_tolerance = 1e-12;
state_tolerance = 1e-12;

report.pass = ...
    report.max_abs_error_time <= time_tolerance && ...
    report.max_abs_error_x <= state_tolerance && ...
    report.max_abs_error_y <= state_tolerance;

%% 6. Report
fprintf('\nGenerated C++ vs Simulink runtime\n');
fprintf('---------------------------------\n');
fprintf('Samples          : %d\n', report.samples);
fprintf('Max time error   : %.17g s\n', report.max_abs_error_time);
fprintf('x max abs error  : %.17g\n', report.max_abs_error_x);
fprintf('x RMS error      : %.17g\n', report.rms_error_x);
fprintf('y max abs error  : %.17g\n', report.max_abs_error_y);
fprintf('y RMS error      : %.17g\n', report.rms_error_y);

if report.pass
    fprintf('Validation       : PASS\n');
else
    fprintf('Validation       : FAIL\n');

    error('validate_cpp_vs_simulink:ToleranceExceeded', ...
        'Generated C++ and Simulink differ beyond tolerance.');
end

end
