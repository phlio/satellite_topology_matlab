function graph_matrix = build_geometry_based_topology(positions, mapping, T, P, S, h, Re, H_atm)
% 基于卫星几何位置构建拓扑
% 修复了所有缺失的函数调用

    graph_matrix = zeros(T, T);
    fprintf('      基于几何位置构建拓扑...\n');
    
    % 计算建链阈值距离
    max_link_distance = calculate_max_link_distance(h, Re, H_atm);
    fprintf('      最大建链距离: %.2f km\n', max_link_distance);
    
    % 提取位置坐标
    x = positions(:, 1);
    y = positions(:, 2);
    z = positions(:, 3);
    
    %% 1. 同轨链路构建
    fprintf('      构建同轨链路...\n');
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
    
    %% 2. 异轨链路构建（基于几何邻近性）
    fprintf('      构建异轨链路...\n');
    for orbit = 1:P
        current_orbit_indices = find([mapping.orbit] == orbit);
        
        if isempty(current_orbit_indices)
            continue;
        end
        
        % 考虑相邻轨道
        adjacent_orbits = [mod(orbit-2, P) + 1, mod(orbit, P) + 1];
        
        for adj_orbit = adjacent_orbits
            adjacent_orbit_indices = find([mapping.orbit] == adj_orbit);
            
            if isempty(adjacent_orbit_indices)
                continue;
            end
            
            % 为当前轨道每颗卫星寻找最佳异轨连接
            for i = 1:length(current_orbit_indices)
                current_sat = current_orbit_indices(i);
                current_pos = positions(current_sat, :);
                
                % 在相邻轨道中寻找几何最近且满足条件的卫星
                best_candidate = find_best_inter_orbit_link(current_sat, current_pos, ...
                                                          adjacent_orbit_indices, positions, ...
                                                          mapping, max_link_distance, Re);
                
                if best_candidate > 0
                    graph_matrix(current_sat, best_candidate) = 1;
                    graph_matrix(best_candidate, current_sat) = 1;
                end
            end
        end
    end
    
    %% 3. 拓扑验证与统计
    total_edges = nnz(graph_matrix) / 2;
    node_degrees = sum(graph_matrix, 2);
    avg_degree = mean(node_degrees);
    
    fprintf('      拓扑统计: 总边数=%d, 平均度数=%.2f\n', total_edges, avg_degree);
end