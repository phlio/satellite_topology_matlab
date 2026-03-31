%% run_void_detection_analysis.m
% 创新点一：拓扑空洞检测与量化评估
% 在 stk_topology_analysis.m 的基础上，增加空洞检测指标
%
% 使用方法:
%   1. 确保已运行 stk_data_preprocessing.m 生成 processed_data.mat
%   2. 直接运行此脚本
%   3. 结果将保存到 void_detection_results.mat
%
% 日期：2026-03-30

clear; clc; close all;

%% 添加 src 函数路径
addpath(fullfile(pwd, 'src'));

data_dir = fullfile(pwd, 'data');

fprintf('=== 拓扑空洞检测与量化评估 ===\n');
fprintf('基于 stk_topology_analysis.m，增加空洞检测指标\n\n');

%% 1. 加载预处理数据
fprintf('1. 加载预处理数据...\n');

if ~exist(fullfile(data_dir, 'processed_data.mat'), 'file')
    error('错误：processed_data.mat 文件不存在！请先运行 stk_data_preprocessing.m');
end

load(fullfile(data_dir, 'processed_data.mat'));

fprintf('   成功加载预处理数据\n');
fprintf('   星座参数: %d/%d/%d, 高度=%dkm\n', T, P, S, h);
fprintf('   时间点数量: %d\n\n', num_time_points);

%% 2. 拓扑构建（与stk_topology_analysis.m相同）
fprintf('2. 基于几何位置的拓扑构建（全局公共可建链）...\n');

max_time_points = min(61, num_time_points);

% 计算异轨可建链候选
inter_orbit_candidates_all_times = calculate_inter_orbit_candidates_all_times(...
    sat_positions(1:max_time_points), ...
    repmat({sat_mapping}, max_time_points, 1), ...
    T, P, S, h, Re);

% 计算全局公共可建链
global_orbit_public_acs = calculate_global_orbit_public_acs(...
    inter_orbit_candidates_all_times, S, P, max_time_points);

% 生成offset组合
global_offset_combinations_indexed = generate_global_offset_combinations_indexed(...
    global_orbit_public_acs, S, P);

% 选择U=S/2的构型
target_U = S / 2;
selected_global_offsets = select_initial_global_offsets(global_offset_combinations_indexed, target_U);

% 构建基础拓扑
reference_positions = sat_positions{1};
base_graph_matrix = build_topology_with_selected_offsets(...
    reference_positions, sat_mapping, selected_global_offsets, T, P, S, h, Re);

fprintf('   基础拓扑构建完成，U=%.1f\n\n', target_U);

%% 3. 1000次蒙特卡洛模拟（增加空洞检测指标）
fprintf('3. 执行1000次蒙特卡洛模拟（含空洞检测）...\n');

num_simulations = 1000;

% 网络性能指标
avg_hops_over_time = zeros(max_time_points, 1);
diameter_over_time = zeros(max_time_points, 1);

% 空洞检测指标（新增）
void_connectivity_rate = zeros(max_time_points, 1);
void_num_components = zeros(max_time_points, 1);
void_isolated_rate = zeros(max_time_points, 1);
void_area_index = zeros(max_time_points, 1);
void_severity_index = zeros(max_time_points, 1);
void_algebraic_connectivity = zeros(max_time_points, 1);

for t_idx = 1:max_time_points
    fprintf('   时间点 %d/%d (时间=%.2f)\n', t_idx, max_time_points, time_data(t_idx));
    
    % 获取当前时间点的数据
    current_positions = sat_positions{t_idx};
    current_sat_lat_lon = sat_lat_lon{t_idx};
    current_sun_vector = sunUnitVector(t_idx, :);
    
    % 累计值初始化
    total_avg_hops = 0;
    total_diameter = 0;
    total_rc = 0;
    total_nc = 0;
    total_ri = 0;
    total_av = 0;
    total_severity = 0;
    total_lambda2 = 0;
    
    for sim_idx = 1:num_simulations
        % 复制基础拓扑
        graph_matrix = base_graph_matrix;
        
        % 应用空间环境效应
        graph_matrix = apply_solar_radiation_effect(graph_matrix, current_positions, current_sun_vector, fov_degrees);
        [graph_matrix, ~] = apply_single_event_upset_effect(graph_matrix, current_sat_lat_lon, seu_probability);
        graph_matrix = apply_space_debris_effect(graph_matrix, debris_probability);
        
        %% ===== 新增：空洞检测 =====
        [void_info, ~, ~] = detect_topological_void(graph_matrix, T);
        severity = calculate_void_severity_index(void_info);
        %% =============================
        
        % 计算网络性能指标
        [avg_hops, diameter] = calculate_network_metrics(graph_matrix);
        
        % 累加
        total_avg_hops = total_avg_hops + avg_hops;
        total_diameter = total_diameter + diameter;
        total_rc = total_rc + void_info.connectivity_rate;
        total_nc = total_nc + void_info.num_components;
        total_ri = total_ri + void_info.isolated_rate;
        total_av = total_av + void_info.void_area_index;
        total_severity = total_severity + severity.composite_score;
        total_lambda2 = total_lambda2 + void_info.algebraic_connectivity;
    end
    
    % 计算平均值
    avg_hops_over_time(t_idx) = total_avg_hops / num_simulations;
    diameter_over_time(t_idx) = total_diameter / num_simulations;
    void_connectivity_rate(t_idx) = total_rc / num_simulations;
    void_num_components(t_idx) = total_nc / num_simulations;
    void_isolated_rate(t_idx) = total_ri / num_simulations;
    void_area_index(t_idx) = total_av / num_simulations;
    void_severity_index(t_idx) = total_severity / num_simulations;
    void_algebraic_connectivity(t_idx) = total_lambda2 / num_simulations;
    
    fprintf('   平均跳数=%.4f, 直径=%.2f, Rc=%.4f, Nc=%.2f, Av=%.4f, 严重度=%.4f\n', ...
        avg_hops_over_time(t_idx), diameter_over_time(t_idx), ...
        void_connectivity_rate(t_idx), void_num_components(t_idx), ...
        void_area_index(t_idx), void_severity_index(t_idx));
end

%% 4. 保存结果
fprintf('\n4. 保存结果...\n');
result_file = 'void_detection_results.mat';
save(result_file, ...
    'time_data', 'avg_hops_over_time', 'diameter_over_time', ...
    'void_connectivity_rate', 'void_num_components', ...
    'void_isolated_rate', 'void_area_index', ...
    'void_severity_index', 'void_algebraic_connectivity', ...
    'num_simulations', 'target_U');
fprintf('   结果已保存到 %s\n', result_file);

%% 5. 可视化结果
fprintf('\n5. 可视化结果...\n');

figure('Position', [100, 100, 1400, 900], 'Name', '拓扑空洞检测结果');

subplot(2, 3, 1);
plot(time_data(1:max_time_points), avg_hops_over_time, 'b-', 'LineWidth', 1.5);
ylabel('平均路径跳数'); xlabel('时间');
title('平均路径跳数随时间变化'); grid on;

subplot(2, 3, 2);
plot(time_data(1:max_time_points), diameter_over_time, 'r-', 'LineWidth', 1.5);
ylabel('网络直径'); xlabel('时间');
title('网络直径随时间变化'); grid on;

subplot(2, 3, 3);
plot(time_data(1:max_time_points), void_connectivity_rate, 'g-', 'LineWidth', 1.5);
ylabel('连通率 Rc'); xlabel('时间');
title('连通率随时间变化'); grid on;
ylim([0, 1.05]);

subplot(2, 3, 4);
plot(time_data(1:max_time_points), void_num_components, 'm-', 'LineWidth', 1.5);
ylabel('连通分量数 Nc'); xlabel('时间');
title('连通分量数随时间变化'); grid on;

subplot(2, 3, 5);
plot(time_data(1:max_time_points), void_area_index, 'k-', 'LineWidth', 1.5);
ylabel('空洞面积指数 Av'); xlabel('时间');
title('空洞面积指数随时间变化'); grid on;

subplot(2, 3, 6);
plot(time_data(1:max_time_points), void_severity_index, 'r-', 'LineWidth', 1.5);
ylabel('严重程度指数'); xlabel('时间');
title('空洞严重程度随时间变化'); grid on;

sgtitle(sprintf('拓扑空洞检测结果 (1000次蒙特卡洛平均, U=%.1f)', target_U));

%% 6. 打印统计摘要
fprintf('\n=== 空洞检测统计摘要 ===\n');
fprintf('平均连通率 Rc: %.4f\n', mean(void_connectivity_rate));
fprintf('平均连通分量数 Nc: %.2f\n', mean(void_num_components));
fprintf('平均孤立节点率 Ri: %.4f\n', mean(void_isolated_rate));
fprintf('平均空洞面积指数 Av: %.4f\n', mean(void_area_index));
fprintf('平均代数连通度 λ2: %.4f\n', mean(void_algebraic_connectivity));
fprintf('平均严重程度: %.4f\n', mean(void_severity_index));
fprintf('最大严重程度: %.4f\n', max(void_severity_index));

fprintf('\n分析完成！\n');