%% 查看高风险区域性能对比分析结果
clear; clc; close all;

fprintf('=== 查看高风险区域性能对比分析结果 ===\n');

% 指定要加载的结果文件（可以根据需要修改时间点）
time_point_idx = 5; % 默认使用第5个时间点的结果
save_filename = sprintf('high_risk_performance_comparison_time%d.mat', (time_point_idx - 1) * 60);

if ~exist(save_filename, 'file')
    fprintf('错误: 结果文件 %s 不存在！\n', save_filename);
    fprintf('请先运行 stk_analyze_high_risk_performance_comparison.m 生成结果文件。\n');
    return;
end

% 加载保存的结果数据
fprintf('加载结果文件: %s\n', save_filename);
load(save_filename);

% 验证必要的变量是否存在
required_vars = {'valid_u_values', 'avg_hops_before_all', 'avg_hops_after_all', 'avg_hops_reconnected_all', ...
    'improvement_rates_all', 'relative_improvement', 'high_risk_links_before_all', 'high_risk_links_after_all', 'high_risk_links_reconnected_all'};
for i = 1:length(required_vars)
    if ~exist(required_vars{i}, 'var')
        fprintf('错误: 缺少必要的变量 %s\n', required_vars{i});
        return;
    end
end

% 设置默认值（如果某些变量不存在）
if ~exist('time_point_idx', 'var')
    time_point_idx = 5;
end
if ~exist('num_simulations', 'var')
    num_simulations = 1000;
end

fprintf('成功加载结果数据！\n');
fprintf('有效的U值: %s\n', mat2str(valid_u_values));
fprintf('时间点: %d, 蒙特卡洛模拟次数: %d\n', time_point_idx, num_simulations);

% 调用绘图函数
fprintf('调用绘图函数...\n');
plot_high_risk_performance_results(valid_u_values, avg_hops_before_all, avg_hops_after_all, avg_hops_reconnected_all, ...
    improvement_rates_all, relative_improvement, high_risk_links_before_all, high_risk_links_after_all, high_risk_links_reconnected_all, time_point_idx, num_simulations);

fprintf('\n结果查看完成！\n');