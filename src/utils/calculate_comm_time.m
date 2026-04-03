function time = calculate_comm_time(task)
% CALCULATE_COMM_TIME Compute theoretical communication time for a task
%   Uses the simplified formula from the original code (HD / Ring)
%   Note: In future versions we can extend this to use actual com_pair + com_data

    if strcmpi(task.cc, 'HD')
        time = 0;
        for j = 0:log2(task.DP)-1
            communicationVolume = 1 / (2^(j+1));
            time = time + communicationVolume;
        end
    elseif strcmpi(task.cc, 'Ring')
        time = 0;
        for j = 1:task.DP-1
            communicationVolume = 1 / task.DP;
            time = time + communicationVolume;
        end
    else
        warning('Unknown cc: %s, using 0', task.cc);
        time = 0;
    end
end