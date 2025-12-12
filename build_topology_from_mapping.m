function graph_matrix = build_topology_from_mapping(T, P, S, U, mapping)
% 基于卫星映射构建拓扑（遵循论文第三章建链原则）
% 输入: T,P,S,U-星座参数, mapping-卫星映射
% 输出: graph_matrix-邻接矩阵

    graph_matrix = zeros(T, T);
    
    fprintf('   构建拓扑: 轨道数=%d, 每轨卫星=%d, 扭曲因子U=%d\n', P, S, U);
    
    %% 同轨链路构建
    for orbit = 1:P
        orbit_sats = find([mapping.orbit] == orbit);
        [~, idx] = sort([mapping(orbit_sats).sat_in_orbit]);
        orbit_sats = orbit_sats(idx);
        
        for j = 1:length(orbit_sats)
            current_sat = orbit_sats(j);
            
            % 同轨前向链路
            next_sat = orbit_sats(mod(j, length(orbit_sats)) + 1);
            graph_matrix(current_sat, next_sat) = 1;
            
            % 同轨后向链路
            prev_sat = orbit_sats(mod(j-2, length(orbit_sats)) + 1);
            graph_matrix(current_sat, prev_sat) = 1;
        end
    end
    
    %% 异轨链路构建（关键部分）
    for orbit = 1:P
        for sat_num = 1:S
            % 找到当前卫星的索引
            current_idx = find([mapping.orbit] == orbit & [mapping.sat_in_orbit] == sat_num);
            
            if isempty(current_idx)
                continue;
            end
            
            % 东向异轨链路
            next_orbit = mod(orbit, P) + 1;
            if orbit == P
                % 最后一轨到第一轨：应用扭曲因子U
                target_sat_num = mod(sat_num + U - 1, S) + 1;
            else
                % 其他轨道间：同编号连接
                target_sat_num = sat_num;
            end
            
            target_idx = find([mapping.orbit] == next_orbit & [mapping.sat_in_orbit] == target_sat_num);
            if ~isempty(target_idx)
                graph_matrix(current_idx, target_idx) = 1;
            end
            
            % 西向异轨链路
            prev_orbit = mod(orbit-2, P) + 1;
            if orbit == 1
                % 第一轨到最后一轨：应用扭曲因子U
                target_sat_num = mod(sat_num - U - 1, S) + 1;
            else
                % 其他轨道间：同编号连接
                target_sat_num = sat_num;
            end
            
            target_idx = find([mapping.orbit] == prev_orbit & [mapping.sat_in_orbit] == target_sat_num);
            if ~isempty(target_idx)
                graph_matrix(current_idx, target_idx) = 1;
            end
        end
    end
    
    % 确保对称性
    graph_matrix = max(graph_matrix, graph_matrix');
    
    % 验证拓扑
    total_edges = nnz(graph_matrix) / 2;
    fprintf('   拓扑验证: 总边数=%d, 期望=%d\n', total_edges, T*2);
end