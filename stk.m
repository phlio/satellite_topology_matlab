%% STK Walker星座拓扑分析
clear; clc; close all;

%% 参数设置
filename = 'location.csv';
T = 60; P = 6; S = 10; U = 5;
h = 1000; Re = 6371.393; H_atm = 100;

fprintf('=== STK Walker星座拓扑分析 ===\n');
fprintf('星座参数: %d/%d/%d, 高度=%dkm\n', T, P, S, h);

%% 1. 读取STK位置数据
fprintf('1. 读取STK位置数据...\n');
[satelliteData, satelliteNames] = read_stk_data(filename);
fprintf('   成功读取 %d 颗卫星的数据\n', length(satelliteNames));

%% 2. 数据重组
fprintf('2. 数据重组与时间对齐...\n');
[time_data, sat_positions, sat_names] = reorganize_satellite_data(satelliteData, satelliteNames, T);
num_time_points = length(time_data);
fprintf('   重组完成: %d个时间点\n', num_time_points);

%% 3. 卫星映射
fprintf('3. 建立卫星名称映射...\n');
sat_mapping = create_satellite_mapping(sat_names, P, S);

%% 4. 基于几何位置的拓扑构建与分析
fprintf('4. 基于几何位置的拓扑构建...\n');

% 初始化结果存储
avg_hops_over_time = zeros(num_time_points, 1);
diameter_over_time = zeros(num_time_points, 1);
topology_variability = zeros(num_time_points, 1);

% 存储每个时间点的拓扑
topology_sequence = cell(num_time_points, 1);

% 只分析前几个时间点以加快速度（可修改为完整分析）
% max_time_points = min(10, num_time_points); % 限制分析的时间点数量
max_time_points = num_time_points;

prev_graph = [];

for t_idx = 1:max_time_points
    fprintf('   分析时间点 %d/%d...\n', t_idx, max_time_points);
    
    % 获取当前时间点的卫星位置
    current_positions = sat_positions{t_idx};
    current_time = time_data(t_idx);
    
    % 基于几何位置构建拓扑
    graph_matrix = build_geometry_based_topology(current_positions, sat_mapping, T, P, S, h, Re, H_atm);
    topology_sequence{t_idx} = graph_matrix;

    if ~isequal(graph_matrix, prev_graph) % 矩阵内容不同 → 触发绘图
        plotSatelliteTopology(graph_matrix);% 画卫星星座拓扑图
        prev_graph = graph_matrix; % 更新历史矩阵为当前矩阵
    end
    
    % 计算拓扑变化率
    if t_idx > 1
        prev_topology = topology_sequence{t_idx-1};
        change_rate = calculate_topology_change(prev_topology, graph_matrix);
        topology_variability(t_idx) = change_rate;
    else
        topology_variability(t_idx) = 0;
    end
    
    % 计算网络性能指标
    [avg_hops, diameter] = calculate_network_metrics(graph_matrix);
    avg_hops_over_time(t_idx) = avg_hops;
    diameter_over_time(t_idx) = diameter;
    
    fprintf('   拓扑指标: 平均跳数=%.4f, 直径=%d, 变化率=%.3f\n', ...
            avg_hops, diameter, topology_variability(t_idx));
end

%% 5. 结果可视化
fprintf('5. 结果可视化...\n');
visualize_analysis_results(time_data(1:max_time_points), avg_hops_over_time(1:max_time_points), ...
                          diameter_over_time(1:max_time_points), topology_variability(1:max_time_points));

%% 6. 详细拓扑分析
fprintf('6. 详细拓扑分析...\n');
analyze_detailed_topology(sat_positions, sat_mapping, topology_sequence, time_data, T, P, S, max_time_points);

fprintf('\n分析完成！\n');