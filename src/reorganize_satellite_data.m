function [time_data, sat_positions, sat_lat_lon, sat_names] = reorganize_satellite_data(satelliteData, satelliteNames, total_sats)
% 将卫星数据重组为统一时间格式
% 输入: satelliteData-卫星数据, satelliteNames-卫星名称, total_sats-总卫星数
% 输出: time_data-统一时间数组, sat_positions-卫星位置cell数组, sat_names-卫星名称

    % 获取第一个卫星的时间序列作为参考
    firstSat = satelliteNames{1};
    reference_time = satelliteData.(firstSat).time;
    
    % 确定统一的时间点（取所有卫星共有的时间点）
    common_time = reference_time;
    for i = 2:length(satelliteNames)
        satName = satelliteNames{i};
        current_time = satelliteData.(satName).time;
        common_time = intersect(common_time, current_time);
    end
    
    fprintf('   统一时间点数量: %d\n', length(common_time));
    time_data = common_time;
    
    % 初始化卫星位置cell数组
    sat_positions = cell(1, length(common_time));
    sat_lat_lon = cell(1, length(common_time));
    sat_names = satelliteNames;
    
    % 对每个时间点，提取所有卫星的位置
    for t_idx = 1:length(common_time)
        current_time = common_time(t_idx);
        positions = zeros(total_sats, 3);
        lat_lon = zeros(total_sats, 2);
        
        for sat_idx = 1:length(satelliteNames)
            satName = satelliteNames{sat_idx};
            sat_time = satelliteData.(satName).time;
            
            % 找到当前时间点在卫星数据中的索引
            time_index = find(sat_time == current_time, 1);
            
            if ~isempty(time_index)
                positions(sat_idx, 1) = satelliteData.(satName).x(time_index);
                positions(sat_idx, 2) = satelliteData.(satName).y(time_index);
                positions(sat_idx, 3) = satelliteData.(satName).z(time_index);
                lat_lon(sat_idx, 1) = satelliteData.(satName).lat(time_index);
                lat_lon(sat_idx, 2) = satelliteData.(satName).lon(time_index);
            else
                % 如果找不到精确匹配，使用线性插值
                fprintf('   警告: 卫星 %s 在时间 %.1f 无数据，使用插值\n', satName, current_time);
                
                % 找到最近的时间点
                [~, nearest_idx] = min(abs(sat_time - current_time));
                positions(sat_idx, :) = [satelliteData.(satName).x(nearest_idx), ...
                                        satelliteData.(satName).y(nearest_idx), ...
                                        satelliteData.(satName).z(nearest_idx)];
            end
        end
        
        sat_positions{t_idx} = positions;
        sat_lat_lon{t_idx} = lat_lon;
    end
    
    fprintf('   数据重组完成: %d个时间点，%d颗卫星\n', length(common_time), total_sats);
end