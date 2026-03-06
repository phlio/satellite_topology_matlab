function graph_matrix = build_topology_with_selected_offsets(positions, mapping, selected_offsets, T, P, S, h, Re)
% 使用选定的offset组合构建拓扑
% 输入:
%   positions - 卫星位置
%   mapping - 卫星映射
%   selected_offsets - 选定的offset向量 (1 x P)
%   T, P, S - 星座参数
%   h - 轨道高度, Re - 地球半径
% 输出:
%   graph_matrix - 拓扑邻接矩阵

    graph_matrix = zeros(T, T);
    
    % 计算建链阈值距离
    max_link_distance = calculate_max_link_distance(h, Re);
    
    %% 1. 同轨链路构建
    for orbit = 1:P
        % 获取当前轨道的所有卫星
        orbit_indices = find([mapping.orbit] == orbit);
        
        if isempty(orbit_indices)
            continue;
        end
        
        % 按卫星在轨道中的编号排序
        [~, sort_idx] = sort([mapping(orbit_indices).sat_in_orbit]);
        orbit_indices = orbit_indices(sort_idx);
        
        % 构建同轨环形拓扑
        for j = 1:length(orbit_indices)
            current_sat = orbit_indices(j);
            
            % 同轨前向链路（连接到轨道下一颗卫星）
            next_sat_idx = mod(j, length(orbit_indices)) + 1;
            next_sat = orbit_indices(next_sat_idx);
            
            % 计算卫星间距离
            dist = norm(positions(current_sat, :) - positions(next_sat, :));
            
            % 检查距离约束和可见性
            if dist <= max_link_distance && check_visibility(positions(current_sat, :), positions(next_sat, :), Re)
                graph_matrix(current_sat, next_sat) = 1;
                graph_matrix(next_sat, current_sat) = 1;
            end
            
            % 同轨后向链路（连接到轨道上一颗卫星）
            prev_sat_idx = mod(j-2, length(orbit_indices)) + 1;
            prev_sat = orbit_indices(prev_sat_idx);
            
            dist = norm(positions(current_sat, :) - positions(prev_sat, :));
            if dist <= max_link_distance && check_visibility(positions(current_sat, :), positions(prev_sat, :), Re)
                graph_matrix(current_sat, prev_sat) = 1;
                graph_matrix(prev_sat, current_sat) = 1;
            end
        end
    end
    
    %% 2. 异轨链路构建（使用选定的offset组合）
    for orbit = 1:P
        current_orbit_indices = find([mapping.orbit] == orbit);
        if isempty(current_orbit_indices)
            continue;
        end
        
        % 当前轨道卫星排序
        [~, sort_idx] = sort([mapping(current_orbit_indices).sat_in_orbit]);
        current_orbit_sats = current_orbit_indices(sort_idx);
        
        % 东向邻轨
        adj_orbit = mod(orbit, P) + 1;
        adj_orbit_indices = find([mapping.orbit] == adj_orbit);
        if isempty(adj_orbit_indices)
            continue;
        end
        
        % 邻轨卫星排序
        [~, adj_sort_idx] = sort([mapping(adj_orbit_indices).sat_in_orbit]);
        adj_orbit_sats = adj_orbit_indices(adj_sort_idx);
        
        % 当前轨道的offset（使用选定的组合）
        o = selected_offsets(orbit);
        
        % 东向异轨建链（双向，2条/卫星）
        for j = 1:S
            current_sat = current_orbit_sats(j);
            % 相对offset转换为邻轨卫星序号（1-10）
            adj_sat_num = mod(j + o - 1, S) + 1; % 处理正负值
            adj_sat = adj_orbit_sats(adj_sat_num);
            % 双向建链
            graph_matrix(current_sat, adj_sat) = 1;
            graph_matrix(adj_sat, current_sat) = 1;
        end
    end
    
    %% 3. 拓扑验证与统计
    total_edges = nnz(graph_matrix) / 2;
    node_degrees = sum(graph_matrix, 2);
    avg_degree = mean(node_degrees);
    
    fprintf('      拓扑统计: 总边数=%d, 平均度数=%.2f\n', total_edges, avg_degree);
end