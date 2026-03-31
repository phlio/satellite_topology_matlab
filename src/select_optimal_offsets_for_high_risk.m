function [optimal_offsets, avg_hops_results] = select_optimal_offsets_for_high_risk(offset_combinations_table, current_positions, sat_mapping, current_sat_lat_lon, T, P, S, h, Re)
% 为每个U值选择在高风险区域内路径跳数最优的建链方案
% 输入:
%   offset_combinations_table - 按sum_mod分类的offset组合 (S x 1 cell array)
%   current_positions - 当前时间点卫星位置
%   sat_mapping - 卫星映射
%   current_sat_lat_lon - 当前时间点卫星经纬度
%   T, P, S - 星座参数
%   h - 轨道高度, Re - 地球半径
% 输出:
%   optimal_offsets - 最优offset组合 (S x P matrix，每行对应一个U值的最优方案)
%   avg_hops_results - 各U值下不同方案的平均路径跳数结果

    % 初始化输出
    optimal_offsets = zeros(S, P);
    avg_hops_results = cell(S, 1);
    
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
        in_latitude_zone = (lat >= lat_min) && (lat <= lat_max);
        in_longitude_zone = (lon >= lon_min) && (lon <= lon_max);
        if in_latitude_zone && in_longitude_zone
            high_risk_satellites(i) = true;
        end
    end
    
    num_high_risk = sum(high_risk_satellites);
    fprintf('   高风险区域内的卫星数量: %d\n', num_high_risk);
    
    if num_high_risk == 0
        fprintf('   警告: 没有卫星位于高风险区域内，返回默认方案。\n');
        % 返回第一个非空的offset组合作为默认方案
        for u = 1:S
            if ~isempty(offset_combinations_table{u})
                optimal_offsets(u, :) = offset_combinations_table{u}(1, :);
                avg_hops_results{u} = [];
                break;
            end
        end
        return;
    end
    
    % 为每个U值（sum_mod）寻找最优方案
    figure('Name', '各U值下不同建链方案的SAA区域平均路径跳数', 'Position', [100, 100, 1000, 600]);
    subplot(2, 3, 1); % 预留空间
    
    valid_u_count = 0;
    for u = 1:S
        if isempty(offset_combinations_table{u})
            fprintf('   U = %d: 无有效组合\n', u-1);
            avg_hops_results{u} = [];
            continue;
        end
        
        combinations = offset_combinations_table{u};
        num_combinations = size(combinations, 1);
        fprintf('   U = %d: 测试 %d 个组合...\n', u-1, num_combinations);
        
        avg_hops_values = zeros(num_combinations, 1);
        valid_combinations = 0;
        
        % 测试每个组合
        for comb_idx = 1:num_combinations
            selected_offsets = combinations(comb_idx, :);
            
            try
                % 构建拓扑
                graph_matrix = build_topology_with_selected_offsets(current_positions, sat_mapping, selected_offsets, T, P, S, h, Re);
                
                % 计算高风险区域内卫星间的平均路径跳数
                avg_hops = calculate_high_risk_avg_hops(graph_matrix, high_risk_satellites);
                avg_hops_values(comb_idx) = avg_hops;
                valid_combinations = valid_combinations + 1;
            catch ME
                fprintf('      组合 %d 失败: %s\n', comb_idx, ME.message);
                avg_hops_values(comb_idx) = inf;
            end
        end
        
        avg_hops_results{u} = avg_hops_values;
        
        % 找到最优方案（最小平均跳数）
        if valid_combinations > 0
            [min_avg_hops, best_idx] = min(avg_hops_values);
            optimal_offsets(u, :) = combinations(best_idx, :);
            fprintf('      最优方案: 组合 %d, 平均跳数 = %.4f, offset组合 = [%s]\n', best_idx, min_avg_hops, mat2str(combinations(best_idx, :)));
        else
            % 如果都失败，选择第一个组合
            optimal_offsets(u, :) = combinations(1, :);
            fprintf('      所有组合失败，选择默认方案: [%s]\n', mat2str(combinations(1, :)));
        end
        
        % 绘制该U值的结果
        if num_combinations > 1 && valid_combinations > 0
            valid_u_count = valid_u_count + 1;
            if valid_u_count <= 6  % 最多显示6个子图
                subplot(2, 3, valid_u_count);
                % 绘制所有组合（蓝色）
                plot(1:num_combinations, avg_hops_values, 'bo-', 'LineWidth', 1.5, 'MarkerSize', 6);
                % 标注最优组合（红色）
                if valid_combinations > 0
                    [min_avg_hops, best_idx] = min(avg_hops_values);
                    hold on;
                    plot(best_idx, min_avg_hops, 'ro', 'MarkerSize', 10, 'LineWidth', 2);
                    hold off;
                end
                xlabel('组合索引');
                ylabel('SAA区域平均路径跳数');
                title(sprintf('U = %d (sum_mod = %d)', u-1, u-1), 'Interpreter', 'none');
                grid on;
                ylim([0, max(avg_hops_values(avg_hops_values < inf)) * 1.1]);
            end
        end
    end
    
    if valid_u_count > 0
        sgtitle('各U值下不同建链方案的SAA区域平均路径跳数对比（红色标记为最优组合）');
    end
    
    fprintf('   最优建链方案选择完成！\n');
end