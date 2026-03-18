function [avg_hops, diameter] = calculate_high_risk_avg_hops(graph_matrix, high_risk_satellites)
% 计算高风险区域内卫星间的平均路径跳数和网络直径
%
% 输入:
%   graph_matrix - 卫星连接关系的对称矩阵 (T x T)
%   high_risk_satellites - 高风险区域内的卫星标识向量 (T x 1)
%
% 输出:
%   avg_hops - 高风险区域内卫星间的平均路径跳数
%   diameter - 高风险区域子图的网络直径

    % 获取卫星总数
    T = size(graph_matrix, 1);
    
    % 检查输入有效性
    if length(high_risk_satellites) ~= T
        error('high_risk_satellites向量长度与图矩阵维度不匹配');
    end
    
    % 找到高风险区域内的卫星索引
    high_risk_indices = find(high_risk_satellites);
    num_high_risk = length(high_risk_indices);
    
    % 处理特殊情况
    if num_high_risk == 0
        avg_hops = 0;
        diameter = 0;
        return;
    elseif num_high_risk == 1
        avg_hops = 0;
        diameter = 0;
        return;
    end
    
    % 使用Dijkstra算法计算高风险区域内卫星间的最短路径
    all_distances = [];
    diameter = 0;
    
    for i = 1:num_high_risk
        source_idx = high_risk_indices(i);
        
        % Dijkstra算法
        dist = ones(1, T) * inf;
        dist(source_idx) = 0;
        visited = false(1, T);
        
        while ~all(visited)
            unvisited = find(~visited);
            if isempty(unvisited)
                break;
            end
            
            [min_dist, idx] = min(dist(unvisited));
            current = unvisited(idx);
            
            if min_dist == inf
                break;
            end
            visited(current) = true;
            
            % 松弛操作
            neighbors = find(graph_matrix(current, :) > 0);
            for j = neighbors
                if ~visited(j) && (dist(current) + 1 < dist(j))
                    dist(j) = dist(current) + 1;
                    if dist(j) > diameter
                        diameter = dist(j);
                    end
                end
            end
        end
        
        % 收集到其他高风险卫星的距离
        for j = 1:num_high_risk
            if i ~= j
                target_idx = high_risk_indices(j);
                if dist(target_idx) < inf
                    all_distances = [all_distances, dist(target_idx)];
                end
            end
        end
    end
    
    if ~isempty(all_distances)
        avg_hops = mean(all_distances);
    else
        avg_hops = inf;
        diameter = inf;
    end
end