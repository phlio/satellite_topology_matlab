%% STK Walker星座拓扑分析主程序
% 基于STK导出的卫星位置数据，分析60/6/1 Walker星座的网络性能
% 采用已验证成功的CSV读取逻辑，保持原有拓扑分析功能

clear; clc; close all;

%% 参数设置
filename = 'location.csv'; % STK导出的CSV文件名
T = 60;  % 总卫星数
P = 6;   % 轨道面数  
S = 10;  % 每轨卫星数
U = 5;   % 扭曲因子（Mobius构型）

fprintf('=== STK Walker星座拓扑分析 ===\n');
fprintf('星座参数: %d/%d/%d, U=%d\n', T, P, S, U);

%% 1. 使用已验证的CSV读取方法读取卫星数据
fprintf('1. 读取STK位置数据...\n');
[satelliteData, satelliteNames] = read_stk_data(filename, T);
fprintf('   读取完成: 成功读取 %d 颗卫星的数据\n', length(satelliteNames));

%% 2. 数据重组为统一时间格式
fprintf('2. 数据重组与时间对齐...\n');
[time_data, sat_positions, sat_names] = reorganize_satellite_data(satelliteData, satelliteNames, T);
num_time_points = length(time_data);
fprintf('   重组完成: %d个统一时间点\n', num_time_points);

%% 3. 卫星名称映射
fprintf('3. 建立卫星名称映射...\n');
sat_mapping = create_satellite_mapping(sat_names, P, S);
fprintf('   映射完成: 轨道1-6，每轨卫星1-10\n');

%% 4. 拓扑构建与性能分析
fprintf('4. 拓扑构建与性能分析...\n');

% 初始化结果存储
avg_hops_over_time = zeros(num_time_points, 1);
diameter_over_time = zeros(num_time_points, 1);

for t_idx = 1:num_time_points
    fprintf('   分析时间点 %d/%d...\n', t_idx, num_time_points);
    
    % 获取当前时间点的卫星位置
    current_positions = sat_positions{t_idx};
    
    % 构建拓扑（基于逻辑连接，不依赖位置）
    graph_matrix = build_topology_from_mapping(T, P, S, U, sat_mapping);
    
    % 计算网络性能指标
    [avg_hops, diameter] = calculate_network_metrics(graph_matrix);
    
    avg_hops_over_time(t_idx) = avg_hops;
    diameter_over_time(t_idx) = diameter;
end

%% 5. 结果可视化
fprintf('5. 结果可视化...\n');

% 时间序列图
figure('Position', [100, 100, 1200, 500], 'Name', '网络性能时间序列');

subplot(1,2,1);
plot(time_data, avg_hops_over_time, 'b-', 'LineWidth', 2);
xlabel('时间 (秒)');
ylabel('平均路径跳数');
title('平均路径跳数随时间变化');
grid on;

subplot(1,2,2);
plot(time_data, diameter_over_time, 'r-', 'LineWidth', 2);
xlabel('时间 (秒)');
ylabel('网络直径');
title('网络直径随时间变化');
grid on;

%% 6. 统计分析
fprintf('\n=== 网络性能统计分析 ===\n');
fprintf('平均路径跳数统计:\n');
fprintf('   平均值: %.4f\n', mean(avg_hops_over_time));
fprintf('   标准差: %.4f\n', std(avg_hops_over_time));
fprintf('   最小值: %.4f\n', min(avg_hops_over_time));
fprintf('   最大值: %.4f\n', max(avg_hops_over_time));

fprintf('\n网络直径统计:\n');
fprintf('   平均值: %.4f\n', mean(diameter_over_time));
fprintf('   标准差: %.4f\n', std(diameter_over_time));
fprintf('   最小值: %.4f\n', min(diameter_over_time));
fprintf('   最大值: %.4f\n', max(diameter_over_time));

%% 7. 拓扑可视化（第一个时间点）
fprintf('7. 生成拓扑可视化图...\n');
if num_time_points > 0
    visualize_topology(sat_positions{1}, sat_mapping, graph_matrix, T, P, S, U);
end

fprintf('\n分析完成！\n');

% 保存分析结果
% save('topology_analysis_results.mat', 'time_data', 'avg_hops_over_time', 'diameter_over_time');