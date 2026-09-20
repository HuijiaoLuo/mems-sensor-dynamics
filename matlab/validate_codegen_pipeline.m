function report = validate_codegen_pipeline(conda_exe, conda_env, params)
%VALIDATE_CODEGEN_PIPELINE Validate generated C++ across MATLAB,
%Simulink, and Python/SciPy references.

if nargin < 1 || isempty(conda_exe)
    conda_exe = 'conda';
end

if nargin < 2 || isempty(conda_env)
    conda_env = 'mems-sensor-dynamics';
end

if nargin < 3
    params = init_params();
end

repo_root = fileparts(fileparts(mfilename('fullpath')));

%% 1. C++ runtime vs Simulink
report.simulink = validate_cpp_vs_simulink(params);

%% 2. C++ runtime vs MATLAB discrete reference
report.matlab = compare_cpp_runtime(params);

%% 3. C++ runtime vs Python/SciPy discrete reference

python_script = fullfile( ...
    repo_root, 'python', 'compare_cpp_runtime.py');

cmd = sprintf( ...
    '"%s" run -n "%s" python "%s" 2>&1', ...
    conda_exe, conda_env, python_script);

[python_status, python_output] = system(cmd);

fprintf('\n%s\n', python_output);

report.python_pass = (python_status == 0);

report.python = struct();
report.python.pass = report.python_pass;
report.python.command = cmd;
report.python.output = python_output;

if ~report.python_pass
    error('validate_codegen_pipeline:PythonValidationFailed', ...
        'Python/SciPy validation failed.');
end

%% Overall status
report.pass = ...
    report.matlab.pass && ...
    report.simulink.pass && ...
    report.python_pass;

fprintf('\nCode-generation validation pipeline\n');
fprintf('-----------------------------------\n');
fprintf('C++ vs MATLAB    : %s\n', local_status(report.matlab.pass));
fprintf('C++ vs Simulink  : %s\n', local_status(report.simulink.pass));
fprintf('C++ vs Python    : %s\n', local_status(report.python_pass));

if report.pass
    fprintf('Overall           : PASS\n');
else
    fprintf('Overall           : FAIL\n');
end

end

function status = local_status(pass)
if pass
    status = 'PASS';
else
    status = 'FAIL';
end
end
