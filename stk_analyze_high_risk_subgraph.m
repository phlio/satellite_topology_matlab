%% 高风险区域卫星子图分析
clear; clc; close all;

%% 1. 加载预处理数据
fprintf('=== 高风险区域卫星子图分析 ===\n');
fprintf('1. 加载预处理数据...\n');

if ~exist('processed_data.mat', 'file')
    error('错误: processed_data.mat 文件不存在！请先运行 data_preprocessing.m');
end

% 直接加载所有变量
load('processed_data.mat');

fprintf('   成功加载预处理数据\n');
fprintf('   星座参数: %d/%d/%d, 高度=%dkm, FOV=%.1f°, SEU概率=%.4f, 碎片概率=%.4f\n', T, P, S, h, fov_degrees, seu_probability, debris_probability);
fprintf('   时间点数量: %d\n', num_time_points);

%% 2. 选择时间点（默认为0，即第一个时间点）
time_point_idx = 5; % MATLAB索引从1开始，对应时间点0
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

% 选择特定U值的最优方案（例如U = S/2）
target_U = 5;
selected_offsets = optimal_offsets(target_U + 1, :);
fprintf('   选择U = %d 的最优建链方案: [%s]\n', target_U-1, mat2str(selected_offsets));

% 构建基础拓扑
fprintf('   构建基础拓扑...\n');
base_graph_matrix = build_topology_with_selected_offsets(current_positions, sat_mapping, selected_offsets, T, P, S, h, Re);

%% 5. 识别高风险区域内的卫星
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
    fprintf('   警告: 没有卫星位于高风险区域内，无法进行子图分析。\n');
    return;
end

%% 6. 构建高风险区域卫星及其两跳邻居的子图
fprintf('6. 构建高风险区域卫星及其两跳邻居的子图...\n');

% 第一跳：高风险区域卫星的直接邻居
first_hop_neighbors = false(T, 1);
for i = 1:T
    if high_risk_satellites(i)
        % 找到所有与高风险卫星直接连接的邻居
        neighbors = find(base_graph_matrix(i, :) == 1);
        first_hop_neighbors(neighbors) = true;
    end
end

% 第二跳：第一跳邻居的邻居（但不包括已经包含的节点）
second_hop_neighbors = false(T, 1);
all_first_hop = high_risk_satellites | first_hop_neighbors;
for i = 1:T
    if first_hop_neighbors(i)
        neighbors = find(base_graph_matrix(i, :) == 1);
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

fprintf('   子图节点总数: %d (高风险:%d, 第一跳:%d, 第二跳:%d)\n', ...
    num_subgraph_nodes, num_high_risk, ...
    sum(first_hop_neighbors & ~high_risk_satellites), ...
    sum(second_hop_neighbors));

%% 7. 提取子图邻接矩阵
subgraph_matrix = base_graph_matrix(subgraph_node_indices, subgraph_node_indices);

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

%% 8. 对子图添加断链影响
fprintf('7. 对子图添加高风险区域断链影响...\n');
subgraph_matrix_with_failure = apply_high_risk_link_failure_effect(subgraph_matrix, subgraph_lat_lon, high_risk_in_subgraph);

%% 9. 计算断链影响前后的高风险区域内平均路径跳数
fprintf('8. 计算断链影响前后的高风险区域内平均路径跳数...\n');

% 计算断链前的平均路径跳数
[avg_hops_before, diameter_before] = calculate_high_risk_avg_hops(subgraph_matrix, high_risk_in_subgraph);
fprintf('   断链前 - 高风险区域内平均路径跳数: %.4f, 直径: %d\n', avg_hops_before, diameter_before);

% 计算断链后的平均路径跳数
[avg_hops_after, diameter_after] = calculate_high_risk_avg_hops(subgraph_matrix_with_failure, high_risk_in_subgraph);
if isinf(avg_hops_after)
    fprintf('   断链后 - 高风险区域内卫星间无连通路径\n');
else
    fprintf('   断链后 - 高风险区域内平均路径跳数: %.4f, 直径: %d\n', avg_hops_after, diameter_after);
end

%% 10. 重新建链优化
fprintf('9. 执行重新建链优化...\n');
[subgraph_matrix_reconnected, added_links] = reconnect_high_risk_subgraph(...
    subgraph_matrix_with_failure, ...
    current_positions(subgraph_node_indices, :), ...
    subgraph_mapping, ...
    high_risk_in_subgraph, ...
    num_subgraph_nodes, P, S, h, Re);

% 计算重新建链后的平均路径跳数
[avg_hops_reconnected, diameter_reconnected] = calculate_high_risk_avg_hops(subgraph_matrix_reconnected, high_risk_in_subgraph);
if isinf(avg_hops_reconnected)
    fprintf('   重新建链后 - 高风险区域内卫星间仍无连通路径\n');
else
    fprintf('   重新建链后 - 高风险区域内平均路径跳数: %.4f, 直径: %d\n', avg_hops_reconnected, diameter_reconnected);
    improvement = avg_hops_after - avg_hops_reconnected;
    if improvement > 0
        fprintf('   重新建链效果: 平均路径跳数减少 %.4f\n', improvement);
    else
        fprintf('   重新建链效果: 无显著改进\n');
    end
end

%% 11. 绘制子图（断链前、断链后和重新建链后）
fprintf('10. 绘制高风险区域子图...\n');

% 绘制断链前的子图
plot_high_risk_subgraph(subgraph_matrix, subgraph_mapping, high_risk_in_subgraph, time_data(time_point_idx), P, S);
title(sprintf('SAA区域子图 - 时间点 %d (断链前)', time_data(time_point_idx)));

% 绘制断链后的子图（显示断开的链路）
plot_high_risk_subgraph_with_failures(subgraph_matrix_with_failure, subgraph_matrix, subgraph_mapping, high_risk_in_subgraph, time_data(time_point_idx), P, S);
title(sprintf('SSA区域子图 - 时间点 %d (断链后)', time_data(time_point_idx)));

% 绘制重新建链后的子图
if ~isempty(added_links)
    plot_high_risk_subgraph_with_reconnect(subgraph_matrix_reconnected, subgraph_matrix_with_failure, subgraph_matrix, subgraph_mapping, high_risk_in_subgraph, time_data(time_point_idx), P, S);
    title(sprintf('SAA区域子图 - 时间点 %d (重新建链后)', time_data(time_point_idx)));
    fprintf('   已绘制重新建链后的子图\n');
end

fprintf('\n高风险区域子图分析完成！\n');