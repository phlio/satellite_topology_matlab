function [avg_hops, diameter] = calculate_network_metrics(graph_matrix)
% 计算网络平均路径跳数和直径
% 输入: graph_matrix-邻接矩阵
% 输出: avg_hops-平均路径跳数, diameter-网络直径

    algorithm = 2;   % 1 = BFS算法,2 = Dijkstra算法
    N = size(graph_matrix, 1);
    all_distances = [];
    diameter = 0;
    
    for i = 1:N
        switch algorithm
            case 1  % 1 = BFS算法（无权图最短路径，效率更高）
                dist = -ones(1, N); % -1表示未访问
                dist(i) = 0;
                queue = i; % BFS队列
                
                while ~isempty(queue)
                    current = queue(1);
                    queue(1) = []; % 出队
                    
                    % 找到当前节点的所有邻居
                    neighbors = find(graph_matrix(current, :) > 0);
                    for j = neighbors
                        if dist(j) == -1
                            dist(j) = dist(current) + 1;
                            queue(end+1) = j; % 入队
                            
                            % 更新网络直径
                            if dist(j) > diameter
                                diameter = dist(j);
                            end
                        end
                    end
                end
                
            case 2  % 2 = Dijkstra算法（兼容有权图，泛用性更强）
                dist = ones(1, N) * inf; % 初始距离设为无穷大
                dist(i) = 0; % 源点到自身距离为0
                visited = false(1, N); % 标记是否已访问
                
                while ~all(visited)
                    % 步骤1：找到未访问的距离最小的节点
                    unvisited = find(~visited); % 提取所有未访问节点的索引
                    if isempty(unvisited)      % 无未访问节点，退出循环
                        break;
                    end
                    
                    % 在未访问节点中找距离最小的节点
                    [min_dist, idx] = min(dist(unvisited));
                    current = unvisited(idx);  % 最小距离节点的真实索引
                    
                    if min_dist == inf         % 剩余未访问节点均不可达，退出循环
                        break;
                    end
                    visited(current) = true;   % 标记为已访问
                    
                    % 步骤2：松弛操作，更新邻居距离
                    neighbors = find(graph_matrix(current, :) > 0);
                    for j = neighbors
                        if ~visited(j) && (dist(current) + 1 < dist(j))
                            dist(j) = dist(current) + 1;
                            
                            % 更新网络直径
                            if dist(j) > diameter
                                diameter = dist(j);
                            end
                        end
                    end
                end        
        end
        
        % 收集有效距离（排除自身和不可达节点）
        if algorithm == 1
            valid_dist = dist(dist > 0); % BFS：dist>0为有效（-1=不可达，0=自身）
        else
            valid_dist = dist(dist < inf & dist > 0); % Dijkstra：dist<inf且>0为有效
        end
        all_distances = [all_distances, valid_dist];
    end
    
    % 计算平均路径跳数
    if ~isempty(all_distances)
        avg_hops = mean(all_distances);
    else
        avg_hops = 0;
    end
end