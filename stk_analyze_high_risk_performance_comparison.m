%% 高风险区域性能对比分析 - 蒙特卡洛模拟版本
clear; clc; close all;

%% 1. 加载预处理数据
fprintf('=== 高风险区域性能对比分析（蒙特卡洛模拟） ===\n');
fprintf('1. 加载预处理数据...\n');

if ~exist('processed_data.mat', 'file')
    error('错误: processed_data.mat 文件不存在！请先运行 data_preprocessing.m');
end

% 直接加载所有变量
load('processed_data.mat');

fprintf('   成功加载预处理数据\n');
fprintf('   星座参数: %d/%d/%d, 高度=%dkm, FOV=%.1f°, SEU概率=%.4f, 碎片概率=%.4f\n', T, P, S, h, fov_degrees, seu_probability, debris_probability);
fprintf('   时间点数量: %d\n', num_time_points);

%% 2. 选择时间点（默认为第5个时间点，索引5）
time_point_idx = 5; % MATLAB索引从1开始
fprintf('2. 选择时间点 %d (索引 %d)...\n', time_data(time_point_idx), time_point_idx);

%% 3. 基于几何位置的拓扑构建（使用全局公共可建链）
fprintf('3. 基于几何位置的拓扑构建（全局公共可建链）...\n');

% 提取当前时间点的位置数据
current_positions = sat_positions{time_point_idx};
current_sat_lat_lon = sat_lat_lon{time_point_idx};

% 计算异轨可建链候选（仅当前时间点）
fprintf('   计算当前时间点的异轨可建链候选...\n');
inter_orbit_candidates = calculate_inter_orbit_candidates_all_times({current_positions}, {sat_mapping}, T, P, S, h, Re);

% 计算当前时间点的公共可建链
fprintf('   计算当前时间点的公共可建链...\n');
orbit_public_acs = calculate_global_orbit_public_acs(inter_orbit_candidates, S, P, 1);

% 生成按sum_mod索引的offset组合
fprintf('   生成按sum_mod索引的offset组合...\n');
offset_combinations_indexed = generate_global_offset_combinations_indexed(orbit_public_acs, S, P);

%% 4. 使用select_optimal_offsets_for_high_risk函数选择每种U值的最优建链方案
fprintf('4. 为每个U值选择高风险区域内路径跳数最优的建链方案...\n');
[optimal_offsets, avg_hops_results] = select_optimal_offsets_for_high_risk(offset_combinations_indexed, current_positions, sat_mapping, current_sat_lat_lon, T, P, S, h, Re);

%% 5. 定义高风险区域边界和识别高风险卫星
fprintf('5. 识别高风险区域内的卫星...\n');

% 定义高风险区域边界
lat_min = -55;   % 南纬55°
lat_max = 15;    % 北纬15°
lon_min = -90;   % 西经90°
lon_max = 15;    % 东经15°

% 识别高风险区域内的卫星
high_risk_satellites = false(T, 1);
for i = 1:T
    lat = current_sat_lat_lon(i, 1);
    lon = current_sat_lat_lon(i, 2);
    
    % 检查是否在高风险区域内
    in_latitude_zone = (lat >= lat_min) && (lat <= lat_max);
    in_longitude_zone = (lon >= lon_min) && (lon <= lon_max);
    
    if in_latitude_zone && in_longitude_zone
        high_risk_satellites(i) = true;
    end
end

num_high_risk = sum(high_risk_satellites);
fprintf('   高风险区域内的卫星数量: %d\n', num_high_risk);

if num_high_risk == 0
    fprintf('   警告: 没有卫星位于高风险区域内，无法进行性能分析。\n');
    return;
end

%% 7. 蒙特卡洛模拟设置
num_simulations = 1000; % 每种建链方案进行1000次模拟
fprintf('7. 开始蒙特卡洛模拟（%d次/方案）...\n', num_simulations);

% 初始化结果存储
valid_u_values = [];
avg_hops_before_all = [];
avg_hops_after_all = [];
avg_hops_reconnected_all = [];
improvement_rates_all = [];
% 新增链路数量统计
high_risk_links_before_all = [];
high_risk_links_after_all = [];
high_risk_links_reconnected_all = [];

% 找出有效的U值
for u = 1:S
    if ~isempty(optimal_offsets(u, :)) && any(optimal_offsets(u, :) ~= 0)
        valid_u_values = [valid_u_values, u-1]; % U值从0开始
    end
end

if isempty(valid_u_values)
    fprintf('   错误: 没有找到有效的建链方案。\n');
    return;
end

fprintf('   有效的U值: %s\n', mat2str(valid_u_values));

%% 8. 对每个有效U值进行蒙特卡洛模拟
for u_idx = 1:length(valid_u_values)
    u_val = valid_u_values(u_idx);
    selected_offsets = optimal_offsets(u_val + 1, :); % MATLAB索引从1开始
    
    fprintf('   处理 U = %d ...\n', u_val);
    
    % 构建完整拓扑（用于子图构建）
    base_graph_matrix_full = build_topology_with_selected_offsets(current_positions, sat_mapping, selected_offsets, T, P, S, h, Re);
    
    % === 动态构建针对当前U值的子图 ===
    % 第一跳：高风险区域卫星的直接邻居
    first_hop_neighbors = false(T, 1);
    for i = 1:T
        if high_risk_satellites(i)
            neighbors = find(base_graph_matrix_full(i, :) == 1);
            first_hop_neighbors(neighbors) = true;
        end
    end
    
    % 第二跳：第一跳邻居的邻居（但不包括已经包含的节点）
    second_hop_neighbors = false(T, 1);
    all_first_hop = high_risk_satellites | first_hop_neighbors;
    for i = 1:T
        if first_hop_neighbors(i)
            neighbors = find(base_graph_matrix_full(i, :) == 1);
            for j = neighbors
                if ~all_first_hop(j)
                    second_hop_neighbors(j) = true;
                end
            end
        end
    end
    
    % 构建子图节点集合
    subgraph_nodes = high_risk_satellites | first_hop_neighbors | second_hop_neighbors;
    subgraph_node_indices = find(subgraph_nodes);
    num_subgraph_nodes = length(subgraph_node_indices);
    
    % 创建子图的卫星映射信息和经纬度信息
    subgraph_mapping = struct();
    subgraph_mapping.orbit = zeros(num_subgraph_nodes, 1);
    subgraph_mapping.sat_in_orbit = zeros(num_subgraph_nodes, 1);
    subgraph_lat_lon = zeros(num_subgraph_nodes, 2);
    
    for i = 1:num_subgraph_nodes
        original_idx = subgraph_node_indices(i);
        subgraph_mapping.orbit(i) = sat_mapping(original_idx).orbit;
        subgraph_mapping.sat_in_orbit(i) = sat_mapping(original_idx).sat_in_orbit;
        subgraph_lat_lon(i, :) = current_sat_lat_lon(original_idx, :);
    end
    
    % 创建子图中的高风险卫星标识
    high_risk_in_subgraph = false(num_subgraph_nodes, 1);
    for i = 1:num_subgraph_nodes
        original_idx = subgraph_node_indices(i);
        if high_risk_satellites(original_idx)
            high_risk_in_subgraph(i) = true;
        end
    end
    
    % 提取子图邻接矩阵
    subgraph_matrix = base_graph_matrix_full(subgraph_node_indices, subgraph_node_indices);
    
    % 计算断链前的平均路径跳数（固定值，只需计算一次）
    [avg_hops_before_fixed, ~] = calculate_high_risk_avg_hops(subgraph_matrix, high_risk_in_subgraph);
    
    % 计算断链前高风险区域内的链路数量（固定值，只需计算一次）
    high_risk_links_before_fixed = 0;
    for i = 1:num_subgraph_nodes
        for j = i+1:num_subgraph_nodes
            if subgraph_matrix(i, j) == 1 && (high_risk_in_subgraph(i) || high_risk_in_subgraph(j))
                high_risk_links_before_fixed = high_risk_links_before_fixed + 1;
            end
        end
    end
    
    % 存储本次U值的所有模拟结果
    hops_after = zeros(num_simulations, 1);
    hops_reconnected = zeros(num_simulations, 1);
    links_after = zeros(num_simulations, 1);
    links_reconnected = zeros(num_simulations, 1);
    
    % 开始计时
    tic;
    
    for sim = 1:num_simulations
        % 应用高风险链路失效效应（使用增强版静默版本，返回链路数量）
        [subgraph_matrix_with_failure, ~, high_risk_links_after_sim] = apply_high_risk_link_failure_effect_quiet(...
            subgraph_matrix, subgraph_lat_lon, high_risk_in_subgraph);
        
        % 计算断链后的平均路径跳数
        [avg_hops_after, ~] = calculate_high_risk_avg_hops(subgraph_matrix_with_failure, high_risk_in_subgraph);
        hops_after(sim) = avg_hops_after;
        links_after(sim) = high_risk_links_after_sim;
        
        % 重新建链优化（使用增强版静默版本，返回重建后链路数量）
        [subgraph_matrix_reconnected, ~, high_risk_links_reconnected_sim] = reconnect_high_risk_subgraph_quiet(...
            subgraph_matrix_with_failure, ...
            current_positions(subgraph_node_indices, :), ...
            subgraph_mapping, ...
            high_risk_in_subgraph, ...
            num_subgraph_nodes, P, S, h, Re);
        
        [avg_hops_reconnected, ~] = calculate_high_risk_avg_hops(subgraph_matrix_reconnected, high_risk_in_subgraph);
        hops_reconnected(sim) = avg_hops_reconnected;
        links_reconnected(sim) = high_risk_links_reconnected_sim;
    end
    
    % 计算平均值
    avg_hops_after_mean = mean(hops_after);
    avg_hops_reconnected_mean = mean(hops_reconnected);
    high_risk_links_after_mean = mean(links_after);
    high_risk_links_reconnected_mean = mean(links_reconnected);
    
    % 计算提升率
    improvement_rate = (avg_hops_after_mean - avg_hops_reconnected_mean) / avg_hops_after_mean * 100;
    
    % 存储结果
    avg_hops_before_all(u_idx) = avg_hops_before_fixed;
    avg_hops_after_all(u_idx) = avg_hops_after_mean;
    avg_hops_reconnected_all(u_idx) = avg_hops_reconnected_mean;
    improvement_rates_all(u_idx) = improvement_rate;
    high_risk_links_before_all(u_idx) = high_risk_links_before_fixed;
    high_risk_links_after_all(u_idx) = high_risk_links_after_mean;
    high_risk_links_reconnected_all(u_idx) = high_risk_links_reconnected_mean;
    
    % 输出模拟耗时
    elapsed_time = toc;
    fprintf('      完成 %d 次模拟，耗时 %.2f 秒\n', num_simulations, elapsed_time);
    fprintf('      断链前: %.4f, 断链后: %.4f, 重建链后: %.4f, 提升率: %.2f%%\n', ...
        avg_hops_before_fixed, avg_hops_after_mean, avg_hops_reconnected_mean, improvement_rate);
end

%% 9. 计算相对改善率（在保存之前）
relative_improvement = zeros(size(improvement_rates_all));
for i = 1:length(valid_u_values)
    relative_improvement(i) = (avg_hops_before_all(i) - avg_hops_reconnected_all(i)) / avg_hops_before_all(i) * 100;
end

%% 10. 保存结果
% save_filename = sprintf('high_risk_performance_comparison_time%d.mat', time_data(time_point_idx));
% % 保存所有图表中展示的数据
% save(save_filename, 'valid_u_values', 'avg_hops_before_all', 'avg_hops_after_all', 'avg_hops_reconnected_all', ...
%     'improvement_rates_all', 'relative_improvement', 'high_risk_links_before_all', 'high_risk_links_after_all', 'high_risk_links_reconnected_all', ...
%     'time_point_idx', 'num_simulations');
% fprintf('\n结果已保存到: %s\n', save_filename);

%% 11. 调用绘图函数
fprintf('11. 调用绘图函数...\n');
plot_high_risk_performance_results(valid_u_values, avg_hops_before_all, avg_hops_after_all, avg_hops_reconnected_all, ...
    improvement_rates_all, relative_improvement, high_risk_links_before_all, high_risk_links_after_all, high_risk_links_reconnected_all, time_point_idx, num_simulations);

fprintf('\n高风险区域性能对比分析完成！\n');