function [reconnected_matrix, added_links, high_risk_links_reconnected] = reconnect_high_risk_subgraph_quiet(current_matrix, positions, mapping, high_risk_flags, T, P, S, h, Re)
% 在断链后的子图中重新建链，优化高风险区域内的平均路径跳数（静默版本）
% 输入:
%   current_matrix - 当前邻接矩阵（断链后）
%   positions - 卫星位置坐标
%   mapping - 卫星映射信息
%   high_risk_flags - 高风险区域标识
%   T, P, S, h, Re - 星座参数
% 输出:
%   reconnected_matrix - 重新建链后的邻接矩阵
%   added_links - 新增的链路列表
%   high_risk_links_reconnected - 重建链后高风险区域内的链路数量

    reconnected_matrix = current_matrix;
    added_links = [];
    num_nodes = size(current_matrix, 1);
    
    % 计算最大链路距离（与build_geometry_based_topology保持一致）
    max_link_distance = calculate_max_link_distance(h, Re);
    
    % 获取当前高风险区域内的平均路径跳数作为基准
    [current_avg_hops, ~] = calculate_high_risk_avg_hops(reconnected_matrix, high_risk_flags);
    
    % 获取高风险区域内的卫星索引
    high_risk_indices = find(high_risk_flags);
    num_high_risk = length(high_risk_indices);
    
    if num_high_risk <= 1
        % 计算重建链后高风险区域内的链路数量
        high_risk_links_reconnected = 0;
        for i = 1:num_nodes
            for j = i+1:num_nodes
                if reconnected_matrix(i, j) == 1 && (high_risk_flags(i) || high_risk_flags(j))
                    high_risk_links_reconnected = high_risk_links_reconnected + 1;
                end
            end
        end
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
        
        iteration = iteration + 1;
    end
    
    % 计算重建链后高风险区域内的链路数量
    high_risk_links_reconnected = 0;
    for i = 1:num_nodes
        for j = i+1:num_nodes
            if reconnected_matrix(i, j) == 1 && (high_risk_flags(i) || high_risk_flags(j))
                high_risk_links_reconnected = high_risk_links_reconnected + 1;
            end
        end
    end
end