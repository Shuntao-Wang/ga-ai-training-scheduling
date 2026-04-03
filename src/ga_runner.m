function [bestSolution, bestFval, convergence] = ga_runner(tasks, config)
% GA_RUNNER Run the Genetic Algorithm for a given scale
%   Supports multiple independent runs, local search, and tracks convergence.
%
% Input:
%   tasks  - cell array of task structs (from load_tasks.m)
%   config - struct loaded from config/config_*.json
%
% Output:
%   bestSolution - best starting NPU indices
%   bestFval     - best objective value (makespan + penalty)
%   convergence  - maxGenerations x numRuns matrix of best fval per generation

    fprintf(' Starting GA for scale = %d NPU (%d tasks)\n', config.scale, length(tasks));

    % Extract parameters
    numTasks          = length(tasks);
    populationSize    = config.population_size;
    maxGenerations    = config.max_generations;
    numRuns           = config.num_runs;
    crossoverFraction = config.crossover_fraction;
    mutationRate      = config.mutation_rate;
    eliteCount        = config.elite_count;
    localSearchInterval = config.local_search_interval;

    % Bounds and integer constraints
    lb = ones(1, numTasks);
    ub = config.total_npu * ones(1, numTasks);
    intcon = 1:numTasks;

    % Objective and constraint functions
    objectiveFunction = @(x) calculate_objective(x, tasks);
    constraintFunction = @(x) deal_constraints(x, tasks);

    % GA options
    options = optimoptions('ga', ...
        'PopulationSize', populationSize, ...
        'MaxGenerations', maxGenerations, ...
        'Display', config.display, ...
        'PlotFcn', @gaplotbestf, ...
        'CrossoverFraction', crossoverFraction, ...
        'MutationFcn', {@mutationadaptfeasible, mutationRate}, ...
        'SelectionFcn', @selectiontournament, ...
        'EliteCount', eliteCount, ...
        'FunctionTolerance', 1e-6, ...
        'ConstraintTolerance', 1e-6, ...
        'OutputFcn', @(options, state, flag) outputFunction(options, state, flag, tasks, localSearchInterval));

    % Initial population
    initialPopulation = createInitialPopulation(populationSize, numTasks, tasks, config.total_npu);
    options = optimoptions(options, 'InitialPopulation', initialPopulation);

    % Prepare convergence matrix
    convergence = zeros(maxGenerations, numRuns);

    % Run GA multiple times
    bestSolution = [];
    bestFval = Inf;

    for run = 1:numRuns
        fprintf('   Run %d/%d ...\n', run, numRuns);
        try
            [x, fval] = ga(objectiveFunction, numTasks, [], [], [], [], ...
                           lb, ub, constraintFunction, intcon, options);

            % Retrieve convergence for this run
            runConv = evalin('base', 'ga_convergence_temp');
            nGen = length(runConv);
            convergence(1:nGen, run) = runConv;

            % Update best overall solution
            if fval < bestFval
                bestSolution = x;
                bestFval = fval;
                fprintf('      New best! fval = %.4f\n', bestFval);
            end
        catch ME
            fprintf('      Error in run %d: %s\n', run, ME.message);
        end
    end

    if isempty(bestSolution)
        error('No feasible solution found after %d runs.', numRuns);
    end

    fprintf('GA finished! Best objective value = %.4f\n', bestFval);
end

%% ====================== Helper Functions ======================

function initialPopulation = createInitialPopulation(populationSize, numTasks, tasks, totalNPU)
    initialPopulation = zeros(populationSize, numTasks);
    for i = 1:populationSize
        solution = zeros(1, numTasks);
        availableNPU = 1;
        for j = 1:numTasks
            solution(j) = availableNPU;
            availableNPU = availableNPU + tasks{j}.total_npu;
        end
        % Add small random perturbation
        solution = solution + randi([-50, 50], 1, numTasks);
        solution = max(solution, 1);
        solution = min(solution, totalNPU);
        initialPopulation(i, :) = solution;
    end
end

function [state, options, optchanged] = outputFunction(options, state, flag, tasks, localSearchInterval)
% OutputFcn for GA to track best value and apply local search
    persistent bestSoFar genCount convVec;
    optchanged = false;

    switch flag
        case 'init'
            bestSoFar = Inf;
            genCount = 0;
            convVec = [];
        case 'iter'
            genCount = genCount + 1;
            convVec(genCount) = state.Best(end);  % Save current best

            % Apply local search periodically
            if mod(state.Generation, localSearchInterval) == 0
                currentBest = state.Best(end);
                if currentBest < bestSoFar
                    bestSoFar = currentBest;
                    improved = local_search(state.Population(1,:), tasks);
                    improvedObj = calculate_objective(improved, tasks);
                    if improvedObj < currentBest
                        state.Population(1,:) = improved;
                        optchanged = true;
                        fprintf('Local search improved best solution at generation %d\n', state.Generation);
                    end
                end
            end
        case 'done'
            % Save this run's convergence to base workspace
            assignin('base', 'ga_convergence_temp', convVec);
    end
end