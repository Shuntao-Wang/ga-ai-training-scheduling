function tasks = load_tasks(scale)
% LOAD_TASKS Load all task JSON files for a given scale
%   tasks = load_tasks(256) or load_tasks(512) or load_tasks(12288)
%
% Input:
%   scale - integer: 256, 512 or 12288
%
% Output:
%   tasks - cell array of structs, each containing one task's JSON data

    if nargin < 1
        error('Please specify scale: 256, 512 or 12288');
    end

    % ================== Auto detect project root ==================
    % Assumes this file is in src/utils/
    projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    
    folder = fullfile(projectRoot, 'data', 'dataset', num2str(scale));
    
    if ~isfolder(folder)
        error('Folder not found: %s\nPlease put your JSON files in data/dataset/%d/', folder, scale);
    end

    files = dir(fullfile(folder, '*.json'));
    numTasks = length(files);
    
    if numTasks == 0
        error('No JSON files found in %s', folder);
    end

    fprintf('Loading %d tasks from %s\n', numTasks, folder);
    
    tasks = cell(1, numTasks);
    for i = 1:numTasks
        filename = fullfile(folder, files(i).name);
        fid = fopen(filename, 'r');
        if fid == -1
            error('Cannot open file: %s', filename);
        end
        raw = fread(fid, inf);
        str = char(raw');
        fclose(fid);
        
        tasks{i} = jsondecode(str);
        fprintf('   Loaded task %d: %s (total_npu=%d, DP=%d, cc=%s)\n', ...
                i, files(i).name, tasks{i}.total_npu, tasks{i}.DP, tasks{i}.cc);
    end
end