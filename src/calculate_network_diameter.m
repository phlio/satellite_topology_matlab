function diameter = calculate_network_diameter(graph_matrix)
% 计算网络直径（最长最短路径）
% 输入: graph_matrix-邻接矩阵
% 输出: diameter-网络直径

    N = size(graph_matrix, 1);
    diameter = 0;
    
    for i = 1:N
        % BFS计算单源最短路径
        dist = -ones(1, N);
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
                    
                    if dist(j) > diameter
                        diameter = dist(j);
                    end
                end
            end
        end
    end
end