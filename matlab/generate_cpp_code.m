function output_folder = generate_cpp_code(params)
%GENERATE_CPP_CODE Build C++ for the fixed-step code-generation model.
%
% This function requires Simulink Coder. It intentionally generates source
% code only for the discrete mechanics model; compiling a host executable is
% a separate toolchain step. Generated source files remain local build
% artifacts and are ignored by Git.

if nargin < 1
    params = init_params();
end

if ~license('test', 'Simulink')
    error('generate_cpp_code:MissingSimulink', ...
        'A Simulink license is required to build the code-generation model.');
end
if ~license('test', 'Real-Time_Workshop')
    error('generate_cpp_code:MissingSimulinkCoder', ...
        'Simulink Coder is required to generate C/C++ code.');
end

model_file = params.model_files.codegen;
if exist(model_file, 'file') ~= 2
    build_models(params);
end

[~, model_name] = fileparts(model_file);
load_system(model_file);
cleanup = onCleanup(@() close_system(model_name, 0));

% Target language is selected at the model level. GenerateCodeOnly avoids a
% dependency on a local C++ compiler while still producing the complete C++
% source and header set.
config_set = getActiveConfigSet(model_name);
set_param(config_set, 'SystemTargetFile', 'grt.tlc', ...
    'TargetLang', 'C++', 'GenCodeOnly', 'on');
% MAT-file/Dataset logging is useful for simulation but is not part of the
% reusable generated algorithm. Disable both the root-output logging and the
% code-generation MAT-file logging before invoking TLC.
set_param(model_name, 'SaveOutput', 'off', ...
    'SaveTime', 'off', ...
    'SaveState', 'off', ...
    'SaveFinalState', 'off', ...
    'SignalLogging', 'off', ...
    'DSMLogging', 'off');
set_param(config_set, 'MatFileLogging', 'off');
save_system(model_name, model_file);
slbuild(model_name, 'StandaloneCoderTarget');

% Simulink Coder places the build folder under the configured code-generation
% folder, which is not necessarily the folder containing the .slx file.
build_folders = RTW.getBuildDir(model_name);
output_folder = build_folders.BuildDirectory;
fprintf('Generated C++ build artifacts in:\n%s\n', output_folder);

end
