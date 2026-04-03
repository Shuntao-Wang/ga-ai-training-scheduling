% ================================================================
% main.m
% Main entry script - One-click execution for GA-based task scheduling
% Supports three scales: 256 / 512 / 12288
% Automatically saves GA convergence curves
% ================================================================

clear; clc; close all;

%% ================== User Configuration ==================
scale = 12288;          % Modify scale here: 256 / 512 / 12288

fprintf('Starting GA-AI-Training-Scheduling (scale = %d NPU)\n\n', scale);

%% ================== Determine Project Root ==================
% Automatically determine project root folder
projectRoot = fileparts(fileparts(mfilename('fullpath')));

% Add src and utils folders to MATLAB path
addpath(fullfile(projectRoot, 'src'));
addpath(fullfile(projectRoot, 'src', 'utils'));

%% ================== 1. Load Configuration ==================
configFile = fullfile(projectRoot, 'config', sprintf('config_%d.json', scale));
if ~isfile(configFile)
    error('Config file not found: %s\nPlease ensure %s exists', configFile, configFile);
end

config = jsondecode(fileread(configFile));
fprintf('Config loaded: PopulationSize=%d, MaxGenerations=%d, Runs=%d\n', ...
        config.population_size, config.max_generations, config.num_runs);

%% ================== 2. Load Task Dataset ==================
tasks = load_tasks(scale);
dataFolder = fullfile(projectRoot, 'data', 'dataset', num2str(scale));
fprintf('Loaded %d tasks from %s\n\n', length(tasks), dataFolder);

%% ================== 3. Run Genetic Algorithm ==================
[bestSolution, bestFval, convergence] = ga_runner(tasks, config);

%% ================== 4. Save Results ==================
resultsDir = fullfile(projectRoot, 'results');
if ~isfolder(resultsDir)
    mkdir(resultsDir);
end

% Save .mat results
save(fullfile(resultsDir, sprintf('best_solution_%d.mat', scale)), ...
     'bestSolution', 'bestFval', 'tasks', 'scale', 'convergence');

% Save text results
fid = fopen(fullfile(resultsDir, sprintf('best_solution_%d.txt', scale)), 'w');
fprintf(fid, 'Best Solution (scale = %d)\n', scale);
fprintf(fid, 'Objective value: %.4f\n\n', bestFval);
for i = 1:length(bestSolution)
    startNPU = round(bestSolution(i));
    endNPU = startNPU + tasks{i}.total_npu - 1;
    fprintf(fid, 'Task %2d: NPUs %5d → %5d (total_npu=%d, DP=%d, cc=%s)\n', ...
            i, startNPU, endNPU, tasks{i}.total_npu, tasks{i}.DP, tasks{i}.cc);
end
fclose(fid);

fprintf('Results saved to results/ folder\n');

%% ================== 5. Visualization ==================
disp('Generating convergence curve and Gantt chart...');

% ---- 5a. Convergence curve ----
figure('Name', sprintf('GA Convergence - %d NPU', scale), 'Position', [100 100 800 400]);
plot(convergence, 'LineWidth', 1.5);
xlabel('Generation');
ylabel('Best Objective Value');
title(sprintf('GA Convergence Curve (scale = %d)', scale));
grid on;
legend(arrayfun(@(x) sprintf('Run %d', x), 1:size(convergence,2), 'UniformOutput', false));
saveas(gcf, fullfile(resultsDir, sprintf('convergence_%d.png', scale)));

% ---- 5b. Simple Gantt chart ----
figure('Name', sprintf('Gantt Chart - %d NPU', scale), 'Position', [100 100 900 500]);
hold on;
for i = 1:length(bestSolution)
    startNPU = round(bestSolution(i));
    duration = tasks{i}.total_npu;
    rectangle('Position', [startNPU, i-0.4, duration, 0.8], ...
              'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'k');
    text(startNPU + duration/2, i, sprintf('Task %d', i), ...
         'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
         'FontWeight', 'bold', 'Color', 'white');
end
xlabel('NPU Index');
ylabel('Task Index');
title(sprintf('Best NPU Allocation (scale = %d, makespan = %.4f)', scale, bestFval));
grid on;
saveas(gcf, fullfile(resultsDir, sprintf('gantt_%d.png', scale)));

fprintf('Visualization completed! Check the results/ folder\n');
fprintf('Execution finished! Best objective value = %.4f\n', bestFval);