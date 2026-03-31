%% STK Walker 星座拓扑分析（基于预处理数据）
clear; clc; close all;

%% 添加 src 函数路径
addpath(fullfile(pwd, 'src'));

%% 1. 加载预处理数据
fprintf('=== STK Walker 星座拓扑分析 ===\n');
fprintf('1. 加载预处理数据...\n');

data_dir = fullfile(pwd, 'data');
if ~exist(fullfile(data_dir, 'processed_data.mat'), 'file')
    error('错误：processed_data.mat 文件不存在！请先运行 data_preprocessing.m');
end

% 直接加载所有变量
load(fullfile(data_dir, 'processed_data.mat'));

fprintf('   成功加载预处理数据\n');
fprintf('   星座参数: %d/%d/%d, 高度=%dkm, FOV=%.1f°, SEU概率=%.4f, 碎片概率=%.4f\n', T, P, S, h, fov_degrees, seu_probability, debris_probability);
fprintf('   时间点数量: %d\n', num_time_points);

%% 2. 基于几何位置的拓扑构建（使用全局公共可建链）
fprintf('2. 基于几何位置的拓扑构建（全局公共可建链）...\n');

% 只分析前几个时间点以加快速度（可修改为完整分析）
max_time_points = min(61, num_time_points); % 限制分析的时间点数量

% 提取所有时间点的位置数据
all_positions = sat_positions(1:max_time_points);
all_mappings = repmat({sat_mapping}, max_time_points, 1);

% 步骤1: 计算所有时间点的异轨可建链候选
fprintf('   计算所有时间点的异轨可建链候选...\n');
inter_orbit_candidates_all_times = calculate_inter_orbit_candidates_all_times(all_positions, all_mappings, T, P, S, h, Re);

% 步骤2: 计算全局公共可建链（跨所有时间点和所有卫星的并集）
fprintf('   计算全局公共可建链...\n');
global_orbit_public_acs = calculate_global_orbit_public_acs(inter_orbit_candidates_all_times, S, P, max_time_points);

% 步骤3: 生成按sum_mod索引的offset组合（基于全局公共可建链）
fprintf('   生成按sum_mod索引的offset组合（全局）...\n');
global_offset_combinations_indexed = generate_global_offset_combinations_indexed(global_orbit_public_acs, S, P);

% 步骤4: 选择初始offset组合（保持与原代码一致的情况）
target_U = S / 2;
selected_global_offsets = select_initial_global_offsets(global_offset_combinations_indexed, target_U);
% selected_global_offsets = global_offset_combinations_indexed{1}(1, :);%{S + 1}

% 存储每个时间点的基础拓扑（所有时间点使用相同的拓扑结构）
high_risk_satellites = [];
current_time = 0;

% 构建统一的基础拓扑（所有时间点相同）
fprintf('   构建统一的基础拓扑（所有时间点相同）...\n');
% 使用第一个时间点的位置数据来构建拓扑结构（但实际连接关系适用于所有时间点）
reference_positions = sat_positions{1};
base_graph_matrix = build_topology_with_selected_offsets(reference_positions, sat_mapping, selected_global_offsets, T, P, S, h, Re);

plotSatelliteTopology(base_graph_matrix, T, P, S, [], high_risk_satellites, current_time);


%% 3. 1000次蒙特卡洛模拟计算平均指标
fprintf('3. 执行1000次蒙特卡洛模拟计算平均指标...\n');

% 初始化结果存储（1000次模拟的平均值）
num_simulations = 1000;
avg_hops_over_time_avg = zeros(max_time_points, 1);
diameter_over_time_avg = zeros(max_time_points, 1);

for t_idx = 1:max_time_points
    fprintf('   处理时间点 %d/%d...%d\n', t_idx, max_time_points, time_data(t_idx));
    
    % 获取当前时间点的数据
    current_positions = sat_positions{t_idx};
    current_sat_lat_lon = sat_lat_lon{t_idx};
    current_sun_vector = sunUnitVector(t_idx, :);
    
    % 初始化累计值
    total_avg_hops = 0;
    total_diameter = 0;
    
    % 执行1000次模拟
    for sim_idx = 1:num_simulations
        % 复制基础拓扑
        graph_matrix = base_graph_matrix;
        
        % 应用空间环境效应
        graph_matrix = apply_solar_radiation_effect(graph_matrix, current_positions, current_sun_vector, fov_degrees);
        [graph_matrix, ~] = apply_single_event_upset_effect(graph_matrix, current_sat_lat_lon, seu_probability);
        graph_matrix = apply_space_debris_effect(graph_matrix, debris_probability);
        
        % 计算网络性能指标
        [avg_hops, diameter] = calculate_network_metrics(graph_matrix);
        
        % 累加结果
        total_avg_hops = total_avg_hops + avg_hops;
        total_diameter = total_diameter + diameter;
    end
    
    % 计算平均值
    avg_hops_over_time_avg(t_idx) = total_avg_hops / num_simulations;
    diameter_over_time_avg(t_idx) = total_diameter / num_simulations;
    
    fprintf('   1000次模拟平均指标: 平均跳数=%.4f, 直径=%.2f\n', ...
            avg_hops_over_time_avg(t_idx), diameter_over_time_avg(t_idx));
    fprintf('=====================================================================\n');
end

%% 4. 保存计算结果到 .mat 文件
% save('simulation_results60u5.mat', 'time_data', 'avg_hops_over_time_avg', 'diameter_over_time_avg', 'num_time_points');

%% 5. 结果可视化（使用1000次模拟的平均结果）

fprintf('5. 结果可视化...\n');
visualize_analysis_results_new_format(time_data(1:max_time_points), avg_hops_over_time_avg, ...
                          diameter_over_time_avg);

fprintf('\n分析完成！结果已保存到 simulation_results.mat\n');