% ==================================================
% 卫星位置数据读取和分析MATLAB代码 - 最终修复版
% 文件名: location.csv
% 功能: 读取多颗卫星的位置数据，进行轨道分析和可视化
% ==================================================

clear; clc; close all;

% 文件读取设置
filename = 'location.csv';
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
            lines{end+1} = line;
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

% 显示文件前几行内容用于调试
fprintf('\n=== 文件前10行内容 ===\n');
for i = 1:min(10, length(lines))
    fprintf('行%4d: %s\n', i, lines{i});
end

% 解析卫星数据
satelliteData = struct();
satelliteCount = 0;

% 寻找所有包含"Satellite"的行作为卫星数据标识
satelliteIndices = find(contains(lines, 'Satellite'));
fprintf('\n找到 %d 个卫星标识\n', length(satelliteIndices));

if isempty(satelliteIndices)
    fprintf('错误: 未找到卫星数据标识\n');
    return;
end

% 处理每个卫星数据块
for i = 1:length(satelliteIndices)
    headerIdx = satelliteIndices(i);
    headerLine = lines{headerIdx};
    
    fprintf('\n处理卫星数据块 %d/%d\n', i, length(satelliteIndices));
    fprintf('标题行: %s\n', headerLine);
    
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
        dataLines = lines(headerIdx+1:nextHeaderIdx-1);
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
    
    % 显示前3行数据内容用于调试
    fprintf('  前3行数据内容:\n');
    for j = 1:min(3, length(dataLines))
        fprintf('    行%d: %s\n', j, dataLines{j});
    end
    
    % 解析数据 - 使用逗号分隔符
    [time, x, y, z, success] = parseSatelliteDataCommaSeparated(dataLines);
    
    if success && ~isempty(time)
        satelliteCount = satelliteCount + 1;
        fieldName = sprintf('Sat%03d', str2double(satNumber));
        
        % 存储数据
        satelliteData.(fieldName).time = time;
        satelliteData.(fieldName).x = x;
        satelliteData.(fieldName).y = y;
        satelliteData.(fieldName).z = z;
        satelliteData.(fieldName).position = [x, y, z];
        
        fprintf('  成功读取卫星 %s: %d 个数据点\n', fieldName, length(time));
        fprintf('  时间范围: %.1f 到 %.1f 秒\n', min(time), max(time));
    else
        fprintf('  卫星 %s 数据解析失败\n', satNumber);
    end
end

fprintf('\n总共成功读取 %d 颗卫星的数据\n', satelliteCount);

if satelliteCount == 0
    fprintf('错误: 未能读取任何卫星数据\n');
    return;
end

% 显示成功读取的卫星列表
satelliteNames = fieldnames(satelliteData);
fprintf('\n成功读取的卫星:\n');
for i = 1:length(satelliteNames)
    fprintf('  %s\n', satelliteNames{i});
end

% 基本数据分析
fprintf('\n数据验证:\n');
firstSat = satelliteNames{1};
data = satelliteData.(firstSat);
fprintf('卫星 %s 数据验证:\n', firstSat);
fprintf('  时间点数量: %d\n', length(data.time));
fprintf('  时间范围: %.1f 到 %.1f\n', min(data.time), max(data.time));
fprintf('  X坐标范围: %.2f 到 %.2f\n', min(data.x), max(data.x));
fprintf('  Y坐标范围: %.2f 到 %.2f\n', min(data.y), max(data.y));
fprintf('  Z坐标范围: %.2f 到 %.2f\n', min(data.z), max(data.z));

% 轨道分析
fprintf('\n轨道分析:\n');
for i = 1:min(10, length(satelliteNames))
    satName = satelliteNames{i};
    data = satelliteData.(satName);
    
    % 计算轨道半径
    r = sqrt(data.x.^2 + data.y.^2 + data.z.^2);
    meanRadius = mean(r);
    
    % 计算速度
    dt = diff(data.time);
    dx = diff(data.x); dy = diff(data.y); dz = diff(data.z);
    v = sqrt((dx./dt).^2 + (dy./dt).^2 + (dz./dt).^2);
    meanVelocity = mean(v);
    
    fprintf('卫星 %s: 平均轨道半径 = %.2f km, 平均速度 = %.2f km/s\n', ...
        satName, meanRadius, meanVelocity);
end

% 可视化分析
if satelliteCount > 0
    createVisualizations(satelliteData, satelliteNames);
end

% 保存处理后的数据
outputFile = 'satellite_data_processed.mat';
save(outputFile, 'satelliteData', 'satelliteNames');
fprintf('\n数据已保存到: %s\n', outputFile);

% 生成分析报告
% generateAnalysisReport(satelliteData, satelliteNames);

fprintf('\n分析完成\n');

% ==================================================
% 辅助函数定义
% ==================================================

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
        
        % 调试：显示前3行的解析过程
        if i <= 3
            fprintf('    解析行 %d: %s\n', i, line);
        end
        
        % 使用逗号分割字符串
        tokens = strsplit(line, ',');
        tokens = strtrim(tokens); % 去除每个token的空格
        
        % 移除空token
        tokens = tokens(~cellfun(@isempty, tokens));
        
        if length(tokens) < 4
            if i <= 3
                fprintf('      分割后只有%d个元素\n', length(tokens));
            end
            continue;
        end
        
        % 尝试将前4个token转换为数值
        numTokens = str2double(tokens(1:4));
        if any(isnan(numTokens))
            if i <= 3
                fprintf('      转换数值失败\n');
            end
            continue;
        end
        
        validCount = validCount + 1;
        time_temp(validCount) = numTokens(1);
        x_temp(validCount) = numTokens(2);
        y_temp(validCount) = numTokens(3);
        z_temp(validCount) = numTokens(4);
        
        if i <= 3
            fprintf('      解析成功: 时间=%.3f, x=%.3f, y=%.3f, z=%.3f\n', ...
                numTokens(1), numTokens(2), numTokens(3), numTokens(4));
        end
    end
    
    if validCount > 0
        time = time_temp(1:validCount);
        x = x_temp(1:validCount);
        y = y_temp(1:validCount);
        z = z_temp(1:validCount);
        success = true;
        
        fprintf('    成功解析 %d/%d 行数据\n', validCount, n);
    else
        fprintf('    所有行解析失败\n');
    end
end

function createVisualizations(satelliteData, satelliteNames)
    % 创建数据可视化图表
    
    % 1. 所有卫星的3D轨道图
    figure('Name', '卫星轨道可视化', 'Position', [100, 100, 1200, 800]);
    
    subplot(2,2,1);
    hold on; grid on;
    colors = lines(length(satelliteNames));
    
    for i = 1:length(satelliteNames)
        satName = satelliteNames{i};
        data = satelliteData.(satName);
        plot3(data.x, data.y, data.z, 'Color', colors(i,:), 'LineWidth', 1);
    end
    
    xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
    title('所有卫星的3D轨道');
    legend(satelliteNames, 'Location', 'eastoutside');
    view(3);
    
    % 2. 卫星轨道与地球参考
    subplot(2,2,2);
    hold on; grid on;
    
    % 绘制地球（简化模型）
    [xx, yy, zz] = sphere(50);
    earthRadius = 6371; % 地球半径 km
    surf(xx*earthRadius, yy*earthRadius, zz*earthRadius, ...
        'FaceAlpha', 0.3, 'EdgeColor', 'none', 'FaceColor', 'blue');
    
    % 绘制卫星轨道
    for i = 1:min(20, length(satelliteNames))
        satName = satelliteNames{i};
        data = satelliteData.(satName);
        plot3(data.x, data.y, data.z, 'Color', colors(i,:), 'LineWidth', 1.5);
    end
    
    xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
    title('卫星轨道与地球参考');
    axis equal;
    
    % 3. 卫星速度变化
    subplot(2,2,3);
    if length(satelliteNames) >= 1
        satName = satelliteNames{1};
        data = satelliteData.(satName);
        
        % 计算速度
        dt = diff(data.time);
        dx = diff(data.x); dy = diff(data.y); dz = diff(data.z);
        v = sqrt((dx./dt).^2 + (dy./dt).^2 + (dz./dt).^2);
        
        plot(data.time(2:end), v, 'b-', 'LineWidth', 2);
        xlabel('时间 (秒)'); ylabel('速度 (km/s)');
        title(sprintf('卫星 %s 的速度变化', satName));
        grid on;
    end
    
    % 4. 卫星间距离矩阵
    subplot(2,2,4);
    if length(satelliteNames) >= 5
        % 选择前5颗卫星计算t=0时的距离
        selectedSats = satelliteNames(1:5);
        n = length(selectedSats);
        distanceMatrix = zeros(n);
        
        for i = 1:n
            for j = 1:n
                if i == j
                    distanceMatrix(i,j) = 0;
                else
                    sat1 = satelliteData.(selectedSats{i});
                    sat2 = satelliteData.(selectedSats{j});
                    % 计算第一个时间点的距离
                    pos1 = [sat1.x(1), sat1.y(1), sat1.z(1)];
                    pos2 = [sat2.x(1), sat2.y(1), sat2.z(1)];
                    distanceMatrix(i,j) = norm(pos1 - pos2);
                end
            end
        end
        
        imagesc(distanceMatrix);
        colorbar;
        title('卫星间距离矩阵 (t=0时刻, km)');
        xlabel('卫星编号'); ylabel('卫星编号');
        set(gca, 'XTick', 1:n, 'XTickLabel', selectedSats);
        set(gca, 'YTick', 1:n, 'YTickLabel', selectedSats);
    end
end

function generateAnalysisReport(satelliteData, satelliteNames)
    % 生成分析报告
    reportFilename = 'satellite_analysis_report.txt';
    fid = fopen(reportFilename, 'w');
    
    fprintf(fid, '卫星位置数据分析报告\n');
    fprintf(fid, '生成时间: %s\n\n', datestr(now));
    
    fprintf(fid, '卫星数量: %d\n', length(satelliteNames));
    
    if ~isempty(satelliteNames)
        sampleSat = satelliteNames{1};
        timePoints = length(satelliteData.(sampleSat).time);
        fprintf(fid, '每个卫星数据点数: %d\n', timePoints);
        fprintf(fid, '时间范围: %.1f - %.1f 秒\n\n', ...
            min(satelliteData.(sampleSat).time), max(satelliteData.(sampleSat).time));
    end
    
    fprintf(fid, '各卫星统计信息:\n');
    fprintf(fid, '%-10s %-12s %-12s %-12s %-12s\n', ...
        '卫星', '平均半径(km)', '平均速度(km/s)', '最小半径(km)', '最大半径(km)');
    fprintf(fid, '%s\n', repmat('-', 1, 60));
    
    for i = 1:length(satelliteNames)
        satName = satelliteNames{i};
        data = satelliteData.(satName);
        
        % 计算统计量
        r = sqrt(data.x.^2 + data.y.^2 + data.z.^2);
        meanRadius = mean(r);
        minRadius = min(r);
        maxRadius = max(r);
        
        dt = diff(data.time);
        dx = diff(data.x); dy = diff(data.y); dz = diff(data.z);
        v = sqrt((dx./dt).^2 + (dy./dt).^2 + (dz./dt).^2);
        meanVelocity = mean(v);
        
        fprintf(fid, '%-10s %-12.2f %-12.2f %-12.2f %-12.2f\n', ...
            satName, meanRadius, meanVelocity, minRadius, maxRadius);
    end
    
    fclose(fid);
    fprintf('分析报告已生成: %s\n', reportFilename);
end