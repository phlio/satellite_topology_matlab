%% 选择高风险区域最优建链方案分析
clear; clc; close all;

%% 1. 加载预处理数据
fprintf('=== 高风险区域最优建链方案选择分析 ===\n');
fprintf('1. 加载预处理数据...\n');

if ~exist('processed_data.mat', 'file')
    error('错误: processed_data.mat 文件不存在！请先运行 data_preprocessing.m');
end

% 直接加载所有变量
load('processed_data.mat');

fprintf('   成功加载预处理数据\n');
fprintf('   星座参数: %d/%d/%d, 高度=%dkm, FOV=%.1f°, SEU概率=%.4f, 碎片概率=%.4f\n', T, P, S, h, fov_degrees, seu_probability, debris_probability);
fprintf('   时间点数量: %d\n', num_time_points);

%% 2. 选择时间点（默认为第5个时间点）
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

%% 4. 为每个U值选择最优的建链方案
fprintf('4. 为每个U值选择高风险区域内路径跳数最优的建链方案...\n');
[optimal_offsets, avg_hops_results] = select_optimal_offsets_for_high_risk(offset_combinations_indexed, current_positions, sat_mapping, current_sat_lat_lon, T, P, S, h, Re);

%% 5. 分析和展示结果
fprintf('\n5. 最优建链方案分析结果:\n');

% 找出全局最优的U值和方案
best_u = -1;
best_avg_hops = inf;
for u = 1:S
    if ~isempty(avg_hops_results{u})
        [min_hops, ~] = min(avg_hops_results{u});
        if min_hops < best_avg_hops && isfinite(min_hops)
            best_avg_hops = min_hops;
            best_u = u;
        end
    end
end

if best_u > 0
    fprintf('   全局最优方案: U = %d (sum_mod = %d), 平均路径跳数 = %.4f\n', best_u-1, best_u-1, best_avg_hops);
    fprintf('   最优offset组合: [%s]\n', mat2str(optimal_offsets(best_u, :)));
else
    fprintf('   未找到有效的最优方案\n');
end

%% 6. 可视化各U值的最优性能
figure('Name', '各U值最优建链方案的高风险区域性能对比', 'Position', [150, 150, 800, 600]);
best_avg_hops_per_u = zeros(S, 1);
u_values = 0:(S-1);

for u = 1:S
    if ~isempty(avg_hops_results{u})
        valid_hops = avg_hops_results{u}(isfinite(avg_hops_results{u}));
        if ~isempty(valid_hops)
            best_avg_hops_per_u(u) = min(valid_hops);
        else
            best_avg_hops_per_u(u) = NaN;
        end
    else
        best_avg_hops_per_u(u) = NaN;
    end
end

% 绘制柱状图
valid_indices = ~isnan(best_avg_hops_per_u);
bar_handle = bar(u_values(valid_indices), best_avg_hops_per_u(valid_indices), 'FaceColor', [0.2, 0.6, 0.8], 'EdgeColor', 'k');

% 在每条柱子上显示数值标签
hold on;
for i = 1:length(valid_indices)
    if valid_indices(i)
        % 获取柱子的高度值
        value = best_avg_hops_per_u(i);
        % 在柱子顶部上方显示数值，保留4位小数
        text(u_values(i), value + 0.05, sprintf('%.4f', value), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 9, 'FontWeight', 'bold');
    end
end

% 为每个U值的最佳组合添加不同颜色的标记
colors = lines(sum(valid_indices)); % 为每个有效U值生成不同颜色
color_idx = 1;
for u = 1:S
    if ~isnan(best_avg_hops_per_u(u))
        % 在柱状图顶部添加彩色圆点标记
        plot(u-1, best_avg_hops_per_u(u), 'o', 'MarkerSize', 8, ...
             'MarkerFaceColor', colors(color_idx, :), 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
        color_idx = color_idx + 1;
    end
end

xlabel('U值 (sum\_mod)');
ylabel('高风险区域最优平均路径跳数');
title('各U值下最优建链方案的高风险区域网络性能（不同颜色标记各U值最佳方案）');
grid on;


%% 7. 构建并展示最优拓扑
fprintf('\n6. 自动构建并展示最优拓扑...\n');
if best_u > 0
    selected_offsets = optimal_offsets(best_u, :);
    
    % 构建基础拓扑
    fprintf('   构建最优拓扑 (U = %d)...\n', best_u-1);
    base_graph_matrix = build_topology_with_selected_offsets(current_positions, sat_mapping, selected_offsets, T, P, S, h, Re);
    
    % 识别高风险区域内的卫星
    lat_min = -55; lat_max = 15; lon_min = -90; lon_max = 15;
    high_risk_satellites = false(T, 1);
    for i = 1:T
        lat = current_sat_lat_lon(i, 1);
        lon = current_sat_lat_lon(i, 2);
        in_latitude_zone = (lat >= lat_min) && (lat <= lat_max);
        in_longitude_zone = (lon >= lon_min) && (lon <= lon_max);
        if in_latitude_zone && in_longitude_zone
            high_risk_satellites(i) = true;
        end
    end
    
    % 计算高风险区域内的实际平均路径跳数
    actual_avg_hops = calculate_high_risk_avg_hops(base_graph_matrix, high_risk_satellites);
    fprintf('   实际高风险区域平均路径跳数: %.4f\n', actual_avg_hops);
    
    % 绘制完整拓扑
%     figure('Name', sprintf('最优建链方案拓扑 - U=%d, 时间点 %d', best_u-1, time_data(time_point_idx)), ...
%            'Position', [200, 200, 900, 700]);
    plotSatelliteTopology(base_graph_matrix, T, P, S, [], high_risk_satellites, time_data(time_point_idx));
    
    fprintf('   最优拓扑可视化完成！\n');
else
    fprintf('   无法构建最优拓扑，未找到有效方案。\n');
end

fprintf('\n高风险区域最优建链方案选择分析完成！\n');