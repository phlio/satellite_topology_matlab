function [avg_hops_over_time_avg, diameter_over_time_avg] = perform_monte_carlo_simulation(...
    base_graph_matrix, sat_positions, sat_lat_lon, sunUnitVector, time_data, ...
    fov_degrees, seu_probability, debris_probability, num_simulations, max_time_points)
% 执行蒙特卡洛模拟计算网络性能指标（高性能版本）
% 符合项目规范：核心计算模块保持轻量，仅包含基础拓扑构建和重复模拟计算逻辑
%
% 输入:
%   base_graph_matrix - 基础拓扑矩阵
%   sat_positions - 卫星位置数据
%   sat_lat_lon - 卫星经纬度数据  
%   sunUnitVector - 太阳单位向量
%   time_data - 时间数据
%   fov_degrees - 视场角
%   seu_probability - SEU概率
%   debris_probability - 碎片概率
%   num_simulations - 模拟次数
%   max_time_points - 最大时间点数
%
% 输出:
%   avg_hops_over_time_avg - 平均跳数结果
%   diameter_over_time_avg - 网络直径结果

    % 获取卫星总数
    T = size(base_graph_matrix, 1);
    
    % 初始化结果存储
    avg_hops_over_time_avg = zeros(max_time_points, 1);
    diameter_over_time_avg = zeros(max_time_points, 1);
    
    % 预计算太阳辐射影响的链路（每个时间点）
    fprintf('   预计算太阳辐射影响的链路...\n');
    fov_radians = deg2rad(fov_degrees);
    solar_affected_links = cell(max_time_points, 1);
    
    for t_idx = 1:max_time_points
        current_positions = sat_positions{t_idx};
        current_sun_vector = sunUnitVector(t_idx, :);
        
        % 确保sun_unit_vector是行向量
        if size(current_sun_vector, 1) > 1
            current_sun_vector = current_sun_vector';
        end
        
        solar_links = [];
        for i = 1:T
            for j = i+1:T
                if base_graph_matrix(i, j) == 1
                    link_vector = current_positions(j, :) - current_positions(i, :);
                    link_magnitude = norm(link_vector);
                    if link_magnitude > 0
                        link_unit_vector = link_vector / link_magnitude;
                        cos_angle = dot(link_unit_vector, current_sun_vector);
                        cos_angle = max(min(cos_angle, 1), -1);
                        angle_radians = acos(cos_angle);
                        line_angle = min(angle_radians, pi - angle_radians);
                        
                        if line_angle < fov_radians
                            solar_links = [solar_links; i, j];
                        end
                    end
                end
            end
        end
        solar_affected_links{t_idx} = solar_links;
    end
    
    % 预计算每个时间点的SEU高风险卫星和归一化距离
    fprintf('   预计算SEU高风险区域信息...\n');
    seu_high_risk_info = cell(max_time_points, 1);
    max_links_per_time = 0;
    
    for t_idx = 1:max_time_points
        current_sat_lat_lon = sat_lat_lon{t_idx};
        
        % 复制SEU函数中的高风险区域判断逻辑
        lat_min = -55; lat_max = 15; lon_min = -90; lon_max = 15;
        center_lat = (lat_min + lat_max) / 2;
        center_lon = (lon_min + lon_max) / 2;
        half_lat_range = (lat_max - lat_min) / 2;
        half_lon_range = (lon_max - lon_min) / 2;
        
        high_risk_satellites = false(T, 1);
        normalized_distances = ones(T, 1);
        
        for i = 1:T
            lat = current_sat_lat_lon(i, 1);
            lon = current_sat_lat_lon(i, 2);
            in_latitude_zone = (lat >= lat_min) && (lat <= lat_max);
            in_longitude_zone = (lon >= lon_min) && (lon <= lon_max);
            if in_latitude_zone && in_longitude_zone
                high_risk_satellites(i) = true;
                norm_lat_diff = abs(lat - center_lat) / half_lat_range;
                norm_lon_diff = abs(lon - center_lon) / half_lon_range;
                normalized_distances(i) = max(norm_lat_diff, norm_lon_diff);
            end
        end
        
        % 计算该时间点的有效链路数量（用于预分配随机数）
        num_valid_links = 0;
        for i = 1:T
            for j = i+1:T
                if base_graph_matrix(i, j) == 1
                    num_valid_links = num_valid_links + 1;
                end
            end
        end
        
        seu_high_risk_info{t_idx}.high_risk = high_risk_satellites;
        seu_high_risk_info{t_idx}.norm_dist = normalized_distances;
        seu_high_risk_info{t_idx}.num_links = num_valid_links;
        
        if num_valid_links > max_links_per_time
            max_links_per_time = num_valid_links;
        end
    end
    
    % 预生成所有随机数（关键优化步骤）
    fprintf('   预生成所有随机数...\n');
    solar_break_rand = rand(num_simulations, max_time_points) < 0.5;
    debris_failures = rand(num_simulations, T, max_time_points) < debris_probability;
    seu_node_rand = rand(num_simulations, T, max_time_points);
    seu_link_rand = rand(num_simulations, max_links_per_time, max_time_points);
    
    fprintf('   开始批量模拟计算...\n');
    total_start_time = tic;
    
    for t_idx = 1:max_time_points
        fprintf('   处理时间点 %d/%d...%d\n', t_idx, max_time_points, time_data(t_idx));
        
        % 获取当前时间点的数据
        current_positions = sat_positions{t_idx};
        current_sat_lat_lon = sat_lat_lon{t_idx};
        current_sun_vector = sunUnitVector(t_idx, :);
        solar_links = solar_affected_links{t_idx};
        num_links_t = seu_high_risk_info{t_idx}.num_links;
        
        % 初始化累计值
        total_avg_hops = 0;
        total_diameter = 0;
        
        % 批量处理模拟
        sim_start_time = tic;
        for sim_idx = 1:num_simulations
            graph_matrix = base_graph_matrix;
            
            % 应用太阳辐射效应
            if ~isempty(solar_links) && solar_break_rand(sim_idx, t_idx)
                for k = 1:size(solar_links, 1)
                    i = solar_links(k, 1);
                    j = solar_links(k, 2);
                    graph_matrix(i, j) = 0;
                    graph_matrix(j, i) = 0;
                end
            end
            
            % 应用空间碎片效应
            failed_nodes = debris_failures(sim_idx, :, t_idx);
            if any(failed_nodes)
                graph_matrix(failed_nodes, :) = 0;
                graph_matrix(:, failed_nodes) = 0;
            end
            
            % 应用SEU效应（使用高性能版本）
            node_rand_vals = seu_node_rand(sim_idx, :, t_idx);
            link_rand_vals = seu_link_rand(sim_idx, 1:num_links_t, t_idx);
            graph_matrix = apply_single_event_upset_effect_fast(graph_matrix, current_sat_lat_lon, seu_probability, node_rand_vals, link_rand_vals);
            
            % 计算网络性能指标
            [avg_hops, diameter] = calculate_network_metrics(graph_matrix);
            
            % 累加结果
            total_avg_hops = total_avg_hops + avg_hops;
            total_diameter = total_diameter + diameter;
        end
        
        % 计算平均值
        avg_hops_over_time_avg(t_idx) = total_avg_hops / num_simulations;
        diameter_over_time_avg(t_idx) = total_diameter / num_simulations;
        
        sim_elapsed = toc(sim_start_time);
        fprintf('   %d次模拟平均指标: 平均跳数=%.4f, 直径=%.2f (耗时: %.2f秒)\n', ...
                num_simulations, avg_hops_over_time_avg(t_idx), diameter_over_time_avg(t_idx), sim_elapsed);
        fprintf('=====================================================================\n');
    end
    
    total_elapsed = toc(total_start_time);
    fprintf('   总模拟时间: %.2f秒\n', total_elapsed);
end