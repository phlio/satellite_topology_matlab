function [satelliteData, satelliteNames] = read_stk_data(filename)
% 基于已验证成功的CSV读取逻辑读取STK数据
% 输入: filename-CSV文件名, total_sats-总卫星数
% 输出: satelliteData-卫星数据结构, satelliteNames-卫星名称列表

    fprintf('开始读取文件: %s\n', filename);

    % 读取文件内容
    try
        fid = fopen(filename, 'r');
        if fid == -1
            error('无法打开文件: %s', filename);
        end
        
        % 读取所有行
        lines = {};
        while ~feof(fid)
            line = fgetl(fid);
            if ischar(line)
                lines{end+1} = line;% lines获取每行的数据，“，”分隔开，包括空行
            end
        end
        fclose(fid);
        
        fprintf('文件总行数: %d\n', length(lines));
        
        % 移除空行
        nonEmptyLines = cellfun(@(x) ~isempty(strtrim(x)), lines);
        lines = lines(nonEmptyLines);
        fprintf('移除空行后行数: %d\n', length(lines));
        
    catch ME
        fprintf('文件读取错误: %s\n', ME.message);
        return;
    end

    % 解析卫星数据
    satelliteData = struct();
    satelliteCount = 0;

    % 寻找所有包含"Satellite"的行作为卫星数据标识
    satelliteIndices = find(contains(lines, 'Satellite'));% satelliteIndices每个卫星数据的表头的列数
    fprintf('找到 %d 个卫星标识\n', length(satelliteIndices));

    if isempty(satelliteIndices)
        fprintf('错误: 未找到卫星数据标识\n');
        return;
    end

    % 处理每个卫星数据块
    for i = 1:length(satelliteIndices)
        headerIdx = satelliteIndices(i);
        headerLine = lines{headerIdx};
        
        fprintf('处理卫星数据块 %d/%d: %s\n', i, length(satelliteIndices), headerLine);
        
        % 提取卫星编号
        satNumber = extractSatelliteNumber(headerLine);
        if isempty(satNumber)
            fprintf('  无法提取卫星编号，跳过\n');
            continue;
        end
        
        fprintf('  卫星编号: %s\n', satNumber);
        
        % 确定数据块范围
        if i < length(satelliteIndices)
            nextHeaderIdx = satelliteIndices(i+1);
            dataLines = lines(headerIdx+1:nextHeaderIdx-1);% dataLines从lines中截取每个卫星的数据
        else
            dataLines = lines(headerIdx+1:end);
        end
        
        % 移除数据块中的空行
        dataLines = dataLines(cellfun(@(x) ~isempty(strtrim(x)), dataLines));
        
        fprintf('  数据行数: %d\n', length(dataLines));
        
        if isempty(dataLines)
            fprintf('  无数据行，跳过\n');
            continue;
        end
        
        % 解析数据 - 使用逗号分隔符
        [time, x, y, z, success] = parseSatelliteDataCommaSeparated(dataLines);
        
        if success && ~isempty(time)
            satelliteCount = satelliteCount + 1;
%             fieldName = sprintf('Sat%d', str2double(satNumber));
            fieldName = sprintf('Sat%s', satNumber);
            
            % 存储数据
            satelliteData.(fieldName).time = time;
            satelliteData.(fieldName).x = x;
            satelliteData.(fieldName).y = y;
            satelliteData.(fieldName).z = z;
            satelliteData.(fieldName).position = [x, y, z];
            
            fprintf('  成功读取卫星 %s: %d 个数据点\n', fieldName, length(time));
        else
            fprintf('  卫星 %s 数据解析失败\n', satNumber);
        end
    end

    fprintf('总共成功读取 %d 颗卫星的数据\n', satelliteCount);

    if satelliteCount == 0
        fprintf('错误: 未能读取任何卫星数据\n');
        return;
    end

    % 获取卫星名称列表
    satelliteNames = fieldnames(satelliteData);
    fprintf('成功读取的卫星: %s\n', strjoin(satelliteNames, ', '));
end

function satNumber = extractSatelliteNumber(headerLine)
    % 从标题行中提取卫星编号
    satNumber = [];
    
    % 尝试多种模式匹配卫星编号
    patterns = {
        'Satellite(\d+)',      % 标准模式: Satellite101
        'Satellite\s*(\d+)',   % 允许空格: Satellite 101
        'Sat(\d+)',           % 简写模式: Sat101
        'Sat\s*(\d+)'         % 允许空格: Sat 101
    };
    
    for i = 1:length(patterns)
        tokens = regexp(headerLine, patterns{i}, 'tokens');
        if ~isempty(tokens)
            satNumber = tokens{1}{1};
            break;
        end
    end
end

function [time, x, y, z, success] = parseSatelliteDataCommaSeparated(dataLines)
    % 解析卫星数据行 - 使用逗号分隔符
    time = []; x = []; y = []; z = [];
    success = false;
    
    n = length(dataLines);
    if n == 0
        return;
    end
    
    % 预分配数组
    time_temp = zeros(n, 1);
    x_temp = zeros(n, 1);
    y_temp = zeros(n, 1);
    z_temp = zeros(n, 1);
    
    validCount = 0;
    
    for i = 1:n
        line = strtrim(dataLines{i});
        if isempty(line)
            continue;
        end
        
        % 使用逗号分割字符串
        tokens = strsplit(line, ',');
        tokens = strtrim(tokens); % 去除每个token的空格
        
        % 移除空token
        tokens = tokens(~cellfun(@isempty, tokens));
        
        if length(tokens) < 4
            continue;
        end
        
        % 尝试将前4个token转换为数值
        numTokens = str2double(tokens(1:4));
        if any(isnan(numTokens))
            continue;
        end
        
        validCount = validCount + 1;
        time_temp(validCount) = numTokens(1);
        x_temp(validCount) = numTokens(2);
        y_temp(validCount) = numTokens(3);
        z_temp(validCount) = numTokens(4);
    end
    
    if validCount > 0
        time = time_temp(1:validCount);
        x = x_temp(1:validCount);
        y = y_temp(1:validCount);
        z = z_temp(1:validCount);
        success = true;
    end
end