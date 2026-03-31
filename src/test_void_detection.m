%% test_void_detection.m - 测试拓扑空洞检测功能
% 用于验证 detect_topological_void 等函数是否正常工作
%
% 使用方法: 在 MATLAB 中运行此脚本
%
% 日期: 2026-03-30

clear; clc; close all;

fprintf('=== 拓扑空洞检测功能测试 ===\n\n');

%% 1. 测试1：简单图（完全图，无空洞）
fprintf('测试1: 完全图（无空洞）\n');
fprintf('---------------------------\n');
T_test = 10;
adj_complete = ones(T_test) - eye(T_test); % 完全图
[void_info, components, sizes] = detect_topological_void(adj_complete, T_test);
fprintf('预期: Rc=1.0, Nc=1, Av=0\n');
fprintf('结果: Rc=%.4f, Nc=%d, Av=%.4f\n\n', ...
    void_info.connectivity_rate, void_info.num_components, void_info.void_area_index);

%% 2. 测试2：带孤立节点的图
fprintf('测试2: 带孤立节点\n');
fprintf('---------------------------\n');
T_test = 10;
adj_isolated = zeros(T_test);
adj_isolated(1:5, 1:5) = ones(5) - eye(5); % 前5个节点连通
adj_isolated(6:8, 6:8) = ones(3) - eye(3); % 6-8节点连通
% 节点9和10孤立
[void_info, components, sizes] = detect_topological_void(adj_isolated, T_test);
fprintf('预期: Rc=0.5, Nc=3, 孤立节点数=2\n');
fprintf('结果: Rc=%.4f, Nc=%d, 孤立节点数=%d\n\n', ...
    void_info.connectivity_rate, void_info.num_components, void_info.isolated_nodes);

%% 3. 测试3：完全断开的图（多个孤立节点）
fprintf('测试3: 完全断开\n');
fprintf('---------------------------\n');
T_test = 6;
adj_disconnected = zeros(T_test); % 所有节点孤立
[void_info, components, sizes] = detect_topological_void(adj_disconnected, T_test);
fprintf('预期: Rc=1/T, Nc=T, Av=(T-1)/T\n');
fprintf('结果: Rc=%.4f, Nc=%d, Av=%.4f\n\n', ...
    void_info.connectivity_rate, void_info.num_components, void_info.void_area_index);

%% 4. 测试4：星形网络（中心节点+叶子节点）
fprintf('测试4: 星形网络\n');
fprintf('---------------------------\n');
T_test = 7;
adj_star = zeros(T_test);
adj_star(1, 2:end) = 1;
adj_star(2:end, 1) = 1; % 节点1为中心
[void_info, components, sizes] = detect_topological_void(adj_star, T_test);
fprintf('预期: Rc=1.0, Nc=1, 无孤立节点\n');
fprintf('结果: Rc=%.4f, Nc=%d, 孤立节点数=%d\n\n', ...
    void_info.connectivity_rate, void_info.num_components, void_info.isolated_nodes);

%% 5. 测试5：检测严重程度指数
fprintf('测试5: 严重程度指数计算\n');
fprintf('---------------------------\n');
adj_test = zeros(10);
adj_test(1:5, 1:5) = ones(5) - eye(5); % 分量1: 5个节点
adj_test(6:8, 6:8) = ones(3) - eye(3); % 分量2: 3个节点
% 节点9,10孤立
[void_info, components, sizes] = detect_topological_void(adj_test, 10);

% 计算严重程度
severity = calculate_void_severity_index(void_info);
fprintf('严重程度综合评分: %.4f\n', severity.composite_score);
fprintf('空洞等级: %s\n', severity.grade);
fprintf('连通率缺失: %.2f%%\n', severity.details.norm_connectivity * 100);
fprintf('孤立节点率: %.2f%%\n', severity.details.norm_isolated * 100);
fprintf('\n');

%% 6. 测试6：使用真实数据（如果processed_data.mat存在）
fprintf('测试6: 使用真实仿真数据\n');
fprintf('---------------------------\n');
if exist('processed_data.mat', 'file')
    load('processed_data.mat');
    fprintf('已加载 processed_data.mat\n');
    
    % 选择一个时间点测试
    time_idx = 240; % 任意选择一个时间点
    fprintf('测试时间点: %d\n', time_idx);
    
    % 构建拓扑（简化版本，使用全局公共可建链）
    % 这里直接使用已有的邻接矩阵进行测试
    if exist('adj_matrix_at_time', 'var')
        [void_info, components, sizes] = detect_topological_void(adj_matrix_at_time, T);
        severity = calculate_void_severity_index(void_info);
        
        fprintf('连通率 Rc = %.4f\n', void_info.connectivity_rate);
        fprintf('连通分量数 Nc = %d\n', void_info.num_components);
        fprintf('空洞面积指数 Av = %.4f\n', void_info.void_area_index);
        fprintf('代数连通度 = %.4f\n', void_info.algebraic_connectivity);
        fprintf('严重程度 = %.4f (%s)\n', severity.composite_score, severity.grade);
    else
        fprintf('注意: processed_data.mat 中没有邻接矩阵数据\n');
        fprintf('请使用 stk_topology_analysis.m 生成包含邻接矩阵的数据\n\n');
    end
else
    fprintf('注意: 未找到 processed_data.mat\n');
    fprintf('请先运行 stk_data_preprocessing.m 生成数据\n\n');
end

%% 7. 测试7：边界节点检测
fprintf('测试7: 边界节点密度检测\n');
fprintf('---------------------------\n');
T_test = 15;
adj_test = zeros(T_test);
% 主连通分量: 节点1-10
adj_test(1:10, 1:10) = ones(10) - eye(10);
% 孤立分量: 节点11-13
adj_test(11:13, 11:13) = ones(3) - eye(3);
% 边界连接: 节点10与节点11之间有链路（边界节点）
adj_test(10, 11) = 1;
adj_test(11, 10) = 1;

[void_info, components, sizes] = detect_topological_void(adj_test, T_test);
main_idx = find(sizes == max(sizes), 1);
boundary_density = calculate_boundary_density(adj_test, components, main_idx);
fprintf('拓扑结构: 主分量10节点 + 孤立分量3节点(含边界连接)\n');
fprintf('边界节点密度: %.4f\n', boundary_density);
fprintf('\n');

%% 测试完成
fprintf('=== 所有测试完成 ===\n');
fprintf('如需查看可视化效果，请运行:\n');
fprintf('  >> plot_topological_void_test()\n');
