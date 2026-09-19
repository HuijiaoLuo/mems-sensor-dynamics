function build_models(params)
%BUILD_MODELS Create the two educational Simulink models.
%
% The function creates model binaries only when run locally in MATLAB with
% Simulink installed. Existing files are left untouched.

if nargin < 1
    params = init_params();
end

if exist(params.model_files.sensor_dynamics, 'file') ~= 2
    local_build_sensor_dynamics(params);
else
    warning('build_models:ExistingDynamics', ...
        'Keeping existing model: %s', params.model_files.sensor_dynamics);
end

if exist(params.model_files.signal_chain, 'file') ~= 2
    local_build_signal_chain(params);
else
    warning('build_models:ExistingSignalChain', ...
        'Keeping existing model: %s', params.model_files.signal_chain);
end

end

function local_build_sensor_dynamics(params)
model_name = 'sensor_dynamics';
model_file = params.model_files.sensor_dynamics;
local_prepare_model_folder(model_file);
local_close_partial_model(model_name);

new_system(model_name);
set_param(model_name, 'Solver', 'ode45', ...
    'RelTol', '1e-6', 'AbsTol', '1e-8', ...
    'StopTime', num2str(params.tfinal));

local_add_step(model_name, 'u_step', params);
local_add_state_space(model_name, 'mechanical_dynamics', params);
add_block('simulink/Signal Routing/Demux', ...
    [model_name '/state_demux'], 'Outputs', '2', ...
    'Position', [390 85 420 145]);
add_block('simulink/Sinks/Out1', [model_name '/x'], ...
    'Position', [500 80 530 100]);
add_block('simulink/Sinks/Out1', [model_name '/y'], ...
    'Position', [500 130 530 150]);
local_add_to_workspace(model_name, 'log_x', 'x_sim', [585 75 700 105]);
local_add_to_workspace(model_name, 'log_y', 'y_sim', [585 125 700 155]);

add_line(model_name, 'u_step/1', 'mechanical_dynamics/1');
add_line(model_name, 'mechanical_dynamics/1', 'state_demux/1');
add_line(model_name, 'state_demux/1', 'x/1');
add_line(model_name, 'state_demux/2', 'y/1');
add_line(model_name, 'state_demux/1', 'log_x/1');
add_line(model_name, 'state_demux/2', 'log_y/1');

save_system(model_name, model_file);
close_system(model_name, 0);
end

function local_build_signal_chain(params)
model_name = 'sensor_signal_chain';
model_file = params.model_files.signal_chain;
local_prepare_model_folder(model_file);
local_close_partial_model(model_name);

new_system(model_name);
set_param(model_name, 'Solver', 'ode45', ...
    'RelTol', '1e-6', 'AbsTol', '1e-8', ...
    'StopTime', num2str(params.tfinal));

local_add_step(model_name, 'u_step', params);
local_add_state_space(model_name, 'mechanical_dynamics', params);
add_block('simulink/Signal Routing/Demux', ...
    [model_name '/state_demux'], 'Outputs', '2', ...
    'Position', [390 80 420 140]);
add_block('simulink/Math Operations/Gain', [model_name '/transduction_gain'], ...
    'Gain', num2str(params.transduction_gain), ...
    'Position', [470 70 540 100]);
add_block('simulink/Sources/Constant', [model_name '/bias'], ...
    'Value', num2str(params.bias), 'Position', [470 160 540 190]);
add_block('simulink/Math Operations/Sum', [model_name '/add_bias'], ...
    'Inputs', '++', 'Position', [590 75 620 125]);
add_block('simulink/Sources/Random Number', [model_name '/measurement_noise'], ...
    'Mean', '0', ...
    'Variance', num2str(params.noise_amplitude^2), ...
    'Seed', num2str(params.noise_seed), 'SampleTime', '0.01', ...
    'Position', [580 170 660 210]);
add_block('simulink/Math Operations/Sum', [model_name '/add_noise'], ...
    'Inputs', '++', 'Position', [710 80 740 130]);
add_block('simulink/Continuous/Transfer Fcn', [model_name '/lowpass'], ...
    'Numerator', '[1]', ...
    'Denominator', sprintf('[%g 1]', params.lowpass_tau), ...
    'Position', [790 85 880 125]);
add_block('simulink/Sources/Constant', [model_name '/bias_estimate'], ...
    'Value', num2str(params.bias_estimate), ...
    'Position', [790 170 880 200]);
add_block('simulink/Math Operations/Sum', [model_name '/subtract_bias'], ...
    'Inputs', '+-', 'Position', [930 85 960 135]);
add_block('simulink/Math Operations/Gain', [model_name '/calibration_scale'], ...
    'Gain', num2str(params.calibration_scale), ...
    'Position', [1000 90 1080 130]);
add_block('simulink/Sinks/Out1', [model_name '/calibrated_output'], ...
    'Position', [1130 95 1160 115]);

local_add_to_workspace(model_name, 'log_x', 'x_sim', [470 255 585 285]);
local_add_to_workspace(model_name, 'log_raw', 'v_raw_sim', [770 255 885 285]);
local_add_to_workspace(model_name, 'log_filtered', ...
    'v_filtered_sim', [920 255 1040 285]);
local_add_to_workspace(model_name, 'log_calibrated', ...
    'calibrated_output_sim', [1090 255 1230 285]);

add_line(model_name, 'u_step/1', 'mechanical_dynamics/1');
add_line(model_name, 'mechanical_dynamics/1', 'state_demux/1');
add_line(model_name, 'state_demux/1', 'transduction_gain/1');
add_line(model_name, 'state_demux/1', 'log_x/1');
add_line(model_name, 'transduction_gain/1', 'add_bias/1');
add_line(model_name, 'bias/1', 'add_bias/2');
add_line(model_name, 'add_bias/1', 'add_noise/1');
add_line(model_name, 'measurement_noise/1', 'add_noise/2');
add_line(model_name, 'add_noise/1', 'lowpass/1');
add_line(model_name, 'add_noise/1', 'log_raw/1');
add_line(model_name, 'lowpass/1', 'subtract_bias/1');
add_line(model_name, 'lowpass/1', 'log_filtered/1');
add_line(model_name, 'bias_estimate/1', 'subtract_bias/2');
add_line(model_name, 'subtract_bias/1', 'calibration_scale/1');
add_line(model_name, 'calibration_scale/1', 'calibrated_output/1');
add_line(model_name, 'calibration_scale/1', 'log_calibrated/1');

save_system(model_name, model_file);
close_system(model_name, 0);
end

function local_add_step(model_name, block_name, params)
add_block('simulink/Sources/Step', [model_name '/' block_name], ...
    'Time', num2str(params.input.step_time), ...
    'Before', num2str(params.input.before), ...
    'After', num2str(params.input.after), ...
    'Position', [35 95 90 125]);
end

function local_add_state_space(model_name, block_name, params)
add_block('simulink/Continuous/State-Space', ...
    [model_name '/' block_name], ...
    'A', sprintf('[0 1; -%g -%g]', params.k, params.r), ...
    'B', '[0; 1]', 'C', '[1 0; 0 1]', 'D', '[0; 0]', ...
    'X0', sprintf('[%g; %g]', params.x0, params.y0), ...
    'Position', [145 80 330 140]);
end

function local_add_to_workspace(model_name, block_name, variable_name, position)
add_block('simulink/Sinks/To Workspace', [model_name '/' block_name], ...
    'VariableName', variable_name, 'SaveFormat', 'Timeseries', ...
    'Position', position);
end

function local_prepare_model_folder(model_file)
model_folder = fileparts(model_file);
if exist(model_folder, 'dir') ~= 7
    mkdir(model_folder);
end
end

function local_close_partial_model(model_name)
% A failed build can leave an unsaved model loaded in memory.
if bdIsLoaded(model_name)
    close_system(model_name, 0);
end
end
