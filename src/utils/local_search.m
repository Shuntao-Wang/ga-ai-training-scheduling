function improvedSolution = local_search(solution, tasks)
% LOCAL_SEARCH Simple hill-climbing local search (used every 10 generations)
%   Tries small offsets on each task's starting NPU and keeps better solutions

    improvedSolution = solution;
    totalNPU = max(cellfun(@(t) t.total_npu, tasks)) * length(tasks) + 1000;  % safe upper bound
    
    for i = 1:length(solution)
        currentStart = solution(i);
        for offset = -10:10   % search range (can be tuned)
            newSolution = solution;
            newStart = max(1, min(totalNPU, currentStart + offset));
            newSolution(i) = newStart;
            
            % Only accept if it improves objective
            if calculate_objective(newSolution, tasks) < calculate_objective(improvedSolution, tasks)
                improvedSolution = newSolution;
            end
        end
    end
end