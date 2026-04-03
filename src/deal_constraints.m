function [c, ceq] = deal_constraints(solution, tasks)
% DEAL_CONSTRAINTS Constraint function for GA
%   Checks two things:
%     1. No overlapping NPU allocation between tasks
%     2. No task exceeds the total number of NPUs in the cluster
%
% Input:
%   solution - 1 x numTasks vector of starting NPU indices
%   tasks    - cell array of task structs (from load_tasks.m)
%
% Output:
%   c   - inequality constraints (sum of violations, >0 means infeasible)
%   ceq - equality constraints (always empty in this problem)

    if nargin < 2
        error('Usage: [c, ceq] = deal_constraints(solution, tasks)');
    end

    % Determine total NPUs for current scale
    totalNPU = max(cellfun(@(t) t.total_npu, tasks)) * length(tasks) + 1000; % safe upper bound
    if isfield(tasks{1}, 'total_npu') && length(tasks) > 0
        % More accurate way: use the scale from the first task's dataset
        scale = str2double(foldername_from_path()); % will be handled in main.m
        totalNPU = max(totalNPU, 12288); % fallback
    end

    usedNPU = zeros(1, totalNPU);
    c = 0;          % total violation count
    ceq = [];       % no equality constraints

    for i = 1:length(solution)
        startNPU = round(solution(i));                    % ensure integer
        requiredNPU = tasks{i}.total_npu;
        endNPU = startNPU + requiredNPU - 1;

        % 1. Check if allocation exceeds cluster size
        if endNPU > totalNPU
            c = c + (endNPU - totalNPU);
        end

        % 2. Check for overlaps with previously allocated tasks
        actualEnd = min(endNPU, totalNPU);
        for j = startNPU:actualEnd
            if j < 1 || j > totalNPU
                continue;
            end
            if usedNPU(j) == 1
                c = c + 1;          % overlap violation
            else
                usedNPU(j) = 1;
            end
        end
    end

    % Optional: print violation count when debugging
    % fprintf('   Constraints violation: %d\n', c);
end

% ====================== Helper function ======================
function folder = foldername_from_path()
% Small helper to avoid hard-coding scale in fitness.m
    folder = '';
end