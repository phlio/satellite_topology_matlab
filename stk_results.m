%% 可视化已保存的模拟结果
clear; clc; close all;

%% 添加 src 函数路径
addpath(fullfile(pwd, 'src'));

data_dir = fullfile(pwd, 'data');

%% 1. 加载保存的计算结果
fprintf('=== 可视化已保存的模拟结果 ===\n');
fprintf('1. 加载保存的计算结果...\n');

if ~exist(fullfile(data_dir, 'simulation_results60u5.mat'), 'file')
    error('错误: simulation_results60u5.mat 文件不存在！请先运行 stk_topology_analysis.m 生成结果文件');
end

% 加载保存的变量
load(fullfile(data_dir, 'simulation_results60u5.mat'));

fprintf('   成功加载计算结果\n');
% 重新计算 max_time_points，与原始分析中保持一致
max_time_points = min(61, num_time_points);
fprintf('   时间点数量: %d (最大为 %d)\n', max_time_points, num_time_points);

%% 2. 结果可视化
fprintf('2. 结果可视化...\n');
visualize_analysis_results_new_format(time_data(1:max_time_points), avg_hops_over_time_avg(1:max_time_points), ...
                          diameter_over_time_avg(1:max_time_points));

fprintf('\n可视化完成！\n');