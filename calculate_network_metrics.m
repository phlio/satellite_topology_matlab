function [avg_hops, diameter] = calculate_network_metrics(graph_matrix)
% 计算网络平均路径跳数和直径
% 输入: graph_matrix-邻接矩阵
% 输出: avg_hops-平均路径跳数, diameter-网络直径

    N = size(graph_matrix, 1);
    all_distances = [];
    diameter = 0;
    
    % 使用BFS计算所有节点对的最短路径
    for i = 1:N
        % BFS计算单源最短路径
        dist = -ones(1, N); % -1表示未访问
        dist(i) = 0;
        queue = i;
        
        while ~isempty(queue)
            current = queue(1);
            queue(1) = [];
            
            neighbors = find(graph_matrix(current, :) > 0);
            for j = neighbors
                if dist(j) == -1
                    dist(j) = dist(current) + 1;
                    queue(end+1) = j;
                    
                    % 更新直径
                    if dist(j) > diameter
                        diameter = dist(j);
                    end
                end
            end
        end
        
        % 收集有效距离（排除自身和不可达节点）
        valid_dist = dist(dist > 0);
        all_distances = [all_distances, valid_dist];
    end
    
    % 计算平均路径跳数
    if ~isempty(all_distances)
        avg_hops = mean(all_distances);
    else
        avg_hops = 0;
    end
    
    fprintf('   网络指标: 平均跳数=%.4f, 直径=%d\n', avg_hops, diameter);
end