function [sunVectorData, sunVectorTime] = read_sun_vector_data(filename)
% 读取STK输出的太阳矢量数据
% 输入: filename - CSV文件名
% 输出: sunVectorData - N×3矩阵，包含每个时间点的太阳矢量[x, y, z]
%       sunVectorTime - N×1向量，包含对应的时间

% 打开文件
fid = fopen(filename, 'r');
if fid == -1
    error('无法打开文件: %s', filename);
end

% 初始化变量
sunVectorData = [];
sunVectorTime = [];

try
    while ~feof(fid)
        line = fgetl(fid);
        
        % 跳过空行
        if isempty(line) || strcmp(line, '')
            continue;
        end
        
        % 检查是否为表头行（包含"Time"或"EpSec"）
        if contains(line, 'Time') || contains(line, 'EpSec')
            % 跳过表头行，继续读取数据
            continue;
        end
        
        % 处理数据行
        data_parts = strsplit(line, ',');
        if length(data_parts) >= 4
            % 解析时间、x、y、z
            time_val = str2double(data_parts{1});
            x_val = str2double(data_parts{2});
            y_val = str2double(data_parts{3});
            z_val = str2double(data_parts{4});
            
            % 验证数据有效性
            if ~isnan(time_val) && ~isnan(x_val) && ~isnan(y_val) && ~isnan(z_val)
                sunVectorTime(end+1) = time_val;
                sunVectorData(end+1, :) = [x_val, y_val, z_val];
            end
        end
    end
    
catch ME
    fclose(fid);
    rethrow(ME);
end

fclose(fid);

end