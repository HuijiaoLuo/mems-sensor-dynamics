%RUN_DEMO Build the portfolio models and generate local validation figures.
%
% This script intentionally does not run during repository preparation. Run
% it in MATLAB from the repository root after reviewing the source files.

repo_root = fileparts(mfilename('fullpath'));
addpath(fullfile(repo_root, 'matlab'));

params = init_params();
build_models(params);
generate_results(params);

disp('Demo complete. Inspect the models/ and results/ folders.');
