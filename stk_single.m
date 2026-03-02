%% STK Walker星座拓扑分析（基于预处理数据）
clear; clc; close all;

%% 1. 加载预处理数据
fprintf('=== STK Walker星座拓扑分析 ===\n');
fprintf('1. 加载预处理数据...\n');

if ~exist('processed_data.mat', 'file')
    error('错误: processed_data.mat 文件不存在！请先运行 data_preprocessing.m');
end

% 直接加载所有变量
load('processed_data.mat');

fprintf('   成功加载预处理数据\n');
fprintf('   星座参数: %d/%d/%d, 高度=%dkm, FOV=%.1f°, SEU概率=%.4f, 碎片概率=%.4f\n', T, P, S, h, fov_degrees, seu_probability, debris_probability);
fprintf('   时间点数量: %d\n', num_time_points);

%% 2. 基于几何位置的拓扑构建与分析
fprintf('2. 基于几何位置的拓扑构建...\n');

% 初始化结果存储
avg_hops_over_time = zeros(num_time_points, 1);
diameter_over_time = zeros(num_time_points, 1);
topology_variability = zeros(num_time_points, 1);

% 存储每个时间点的拓扑
topology_sequence = cell(num_time_points, 1);

% 只分析前几个时间点以加快速度（可修改为完整分析）
max_time_points = min(61, num_time_points); % 限制分析的时间点数量

prev_graph = [];
high_risk_satellites = [];

for t_idx = 1:max_time_points
    fprintf('   分析时间点 %d/%d...%d\n', t_idx, max_time_points, time_data(t_idx));
    
    % 获取当前时间点的卫星位置、经纬度和太阳矢量
    current_positions = sat_positions{t_idx};
    current_sat_lat_lon = sat_lat_lon{t_idx};
    current_time = time_data(t_idx);
    current_sun_vector = sunUnitVector(t_idx, :);
    
    % 基于几何位置构建拓扑
    graph_matrix = build_geometry_based_topology(current_positions, sat_mapping, T, P, S, h, Re);
    full_graph_matrix = graph_matrix;
    
    % 应用太阳辐射效应
    graph_matrix = apply_solar_radiation_effect(graph_matrix, current_positions, current_sun_vector, fov_degrees);
    
    % 应用单粒子翻转(SEU)效应
    [graph_matrix, high_risk_satellites] = apply_single_event_upset_effect(graph_matrix, current_sat_lat_lon, seu_probability);
    
    % 应用空间碎片效应
    graph_matrix = apply_space_debris_effect(graph_matrix, debris_probability);
    
    topology_sequence{t_idx} = graph_matrix;

%     if ~isequal(graph_matrix, prev_graph) % 矩阵内容不同 → 触发绘图
%         plotSatelliteTopology(graph_matrix, T, P, S, full_graph_matrix, high_risk_satellites, current_time);% 画卫星星座拓扑图
%         prev_graph = graph_matrix; % 更新历史矩阵为当前矩阵
%     end
    
    % 计算网络性能指标
    [avg_hops, diameter] = calculate_network_metrics(graph_matrix);
    avg_hops_over_time(t_idx) = avg_hops;
    diameter_over_time(t_idx) = diameter;
    
    fprintf('   拓扑指标: 平均跳数=%.4f, 直径=%d\n', ...
            avg_hops, diameter);
    fprintf('=====================================================================\n');
end

%% 3. 结果可视化
fprintf('3. 结果可视化...\n');
visualize_analysis_results_new_format(time_data(1:max_time_points), avg_hops_over_time(1:max_time_points), ...
                          diameter_over_time(1:max_time_points));

%% 4. 详细拓扑分析
fprintf('4. 详细拓扑分析...\n');
analyze_detailed_topology(sat_positions, sat_mapping, topology_sequence, time_data, T, P, S, max_time_points);

fprintf('\n分析完成！\n');