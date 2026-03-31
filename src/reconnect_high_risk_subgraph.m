function [reconnected_matrix, added_links] = reconnect_high_risk_subgraph(current_matrix, positions, mapping, high_risk_flags, T, P, S, h, Re)
% 在断链后的子图中重新建链，优化高风险区域内的平均路径跳数
% 输入:
%   current_matrix - 当前邻接矩阵（断链后）
%   positions - 卫星位置坐标
%   mapping - 卫星映射信息
%   high_risk_flags - 高风险区域标识
%   T, P, S, h, Re - 星座参数
% 输出:
%   reconnected_matrix - 重新建链后的邻接矩阵
%   added_links - 新增的链路列表

    reconnected_matrix = current_matrix;
    added_links = [];
    num_nodes = size(current_matrix, 1);
    
    % 计算最大链路距离（与build_geometry_based_topology保持一致）
    max_link_distance = calculate_max_link_distance(h, Re);
    
    % 获取当前高风险区域内的平均路径跳数作为基准
    [current_avg_hops, ~] = calculate_high_risk_avg_hops(reconnected_matrix, high_risk_flags);
    
    if isinf(current_avg_hops)
        fprintf('   高风险区域内无连通路径，开始重新建链...\n');
    else
        fprintf('   当前高风险区域内平均路径跳数: %.4f\n', current_avg_hops);
    end
    
    % 获取高风险区域内的卫星索引
    high_risk_indices = find(high_risk_flags);
    num_high_risk = length(high_risk_indices);
    
    if num_high_risk <= 1
        fprintf('   高风险区域内卫星数量不足，无法优化。\n');
        return;
    end
    
    % 贪心算法：尝试添加链路，每次选择最优的
    max_iterations = 50; % 最大迭代次数，防止无限循环
    iteration = 0;
    
    while iteration < max_iterations
        best_improvement = 0;
        best_link = [];
        
        % 检查每个高风险卫星的链路数量
        current_degrees = sum(reconnected_matrix, 2);
        
        % 尝试在所有可能的高风险卫星对之间添加链路
        for i = 1:num_high_risk
            sat_i = high_risk_indices(i);
            if current_degrees(sat_i) >= 4
                continue; % 已达到最大链路数
            end
            
            for j = i+1:num_high_risk
                sat_j = high_risk_indices(j);
                if current_degrees(sat_j) >= 4
                    continue; % 已达到最大链路数
                end
                
                % 检查是否已经连接
                if reconnected_matrix(sat_i, sat_j) == 1
                    continue;
                end
                
                % 检查建链条件（与build_geometry_based_topology保持一致）
                pos_i = positions(sat_i, :);
                pos_j = positions(sat_j, :);
                distance = norm(pos_i - pos_j);
                
                if distance > max_link_distance
                    continue; % 距离过远
                end
                
                if ~check_visibility(pos_i, pos_j, Re)
                    continue; % 不可见
                end
                
                % 临时添加链路
                temp_matrix = reconnected_matrix;
                temp_matrix(sat_i, sat_j) = 1;
                temp_matrix(sat_j, sat_i) = 1;
                
                % 计算新的平均路径跳数
                [new_avg_hops, ~] = calculate_high_risk_avg_hops(temp_matrix, high_risk_flags);
                
                if isnan(new_avg_hops) || isinf(new_avg_hops)
                    continue; % 无效的连接
                end
                
                % 计算改进效果
                improvement = current_avg_hops - new_avg_hops;
                if improvement > best_improvement
                    best_improvement = improvement;
                    best_link = [sat_i, sat_j];
                end
            end
        end
        
        % 如果没有找到改进的链路，退出循环
        if best_improvement <= 1e-6
            break;
        end
        
        % 添加最佳链路
        sat_i = best_link(1);
        sat_j = best_link(2);
        reconnected_matrix(sat_i, sat_j) = 1;
        reconnected_matrix(sat_j, sat_i) = 1;
        added_links = [added_links; sat_i, sat_j];
        
        % 更新当前平均路径跳数
        [current_avg_hops, ~] = calculate_high_risk_avg_hops(reconnected_matrix, high_risk_flags);
        
        % 获取卫星的实际轨道编号和每轨卫星编号
        orbit_i = mapping.orbit(sat_i);
        sat_in_orbit_i = mapping.sat_in_orbit(sat_i);
        orbit_j = mapping.orbit(sat_j);
        sat_in_orbit_j = mapping.sat_in_orbit(sat_j);
        
        fprintf('   迭代 %d: 添加链路 (%d轨%d星, %d轨%d星), 平均路径跳数改进: %.4f\n', ...
            iteration+1, orbit_i, sat_in_orbit_i, orbit_j, sat_in_orbit_j, best_improvement);
        
        iteration = iteration + 1;
    end
    
    fprintf('   重新建链完成，共添加 %d 条新链路。\n', size(added_links, 1));
end