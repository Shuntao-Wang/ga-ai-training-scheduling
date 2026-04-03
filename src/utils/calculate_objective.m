function objective = calculate_objective(solution, tasks)
% CALCULATE_OBJECTIVE Main fitness function used by GA
%   Combines communication time + penalty for overlaps / out-of-bound

    [penalty, ~] = deal_constraints(solution, tasks);
    objective = 0;
    
    for i = 1:length(solution)
        task = tasks{i};
        objective = objective + calculate_comm_time(task);
        
        % Extra penalty for non-continuous allocation between tasks
        if i > 1 && solution(i) ~= solution(i-1) + tasks{i-1}.total_npu
            objective = objective + 1000;
        end
    end
    
    objective = objective + 10000 * penalty;   % heavy penalty on infeasible solutions
end