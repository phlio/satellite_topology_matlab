function inter_orbit_candidates_all_times = calculate_inter_orbit_candidates_all_times(all_positions, all_mappings, T, P, S, h, Re)
% 计算所有时间点的异轨可建链候选
% 输入: 
%   all_positions - 所有时间点的卫星位置 (cell array)
%   all_mappings - 所有时间点的卫星映射 (cell array)
%   T, P, S - 星座参数 (总卫星数, 轨道数, 每轨道卫星数)
%   h - 轨道高度, Re - 地球半径
% 输出:
%   inter_orbit_candidates_all_times - cell array, 每个时间点包含一个 P x S 的cell矩阵

    num_time_points = length(all_positions);
    inter_orbit_candidates_all_times = cell(num_time_points, 1);
    
    % 计算建链阈值距离
    max_link_distance = calculate_max_link_distance(h, Re);
    
    for t_idx = 1:num_time_points
        positions = all_positions{t_idx};
        mapping = all_mappings{t_idx};
        
        % 初始化当前时间点的候选矩阵
        inter_orbit_candidates = cell(S, P);
        
        fprintf('      处理时间点 %d/%d 的异轨候选...\n', t_idx, num_time_points);
        
        % 遍历每个轨道
        for orbit = 1:P
            current_orbit_indices = find([mapping.orbit] == orbit);
            if isempty(current_orbit_indices)
                continue;
            end
            
            % 获取东向邻轨
            adj_orbit = mod(orbit, P) + 1;
            adjacent_orbit_indices = find([mapping.orbit] == adj_orbit);
            if isempty(adjacent_orbit_indices)
                continue;
            end
            
            % 邻轨卫星排序
            [~, adj_sort_idx] = sort([mapping(adjacent_orbit_indices).sat_in_orbit]);
            adjacent_orbit_indices = adjacent_orbit_indices(adj_sort_idx);
            
            % 为当前轨道每颗卫星处理异轨建链候选
            for i = 1:length(current_orbit_indices)
                current_sat = current_orbit_indices(i);
                current_pos = positions(current_sat, :);
                
                % 遍历邻轨所有卫星，筛选满足可建链条件的卫星
                temp_candidates = [];
                for adj_sat = adjacent_orbit_indices
                    % 检查可建链条件（距离+视距）
                    dist = norm(current_pos - positions(adj_sat, :));
                    if dist <= max_link_distance && check_visibility(current_pos, positions(adj_sat, :), Re)
                        % 计算相对位置（东向异轨链路相对可建链卫星）
                        relative_position = mod(adj_sat, length(current_orbit_indices));
                        if relative_position - i > S/2
                            relative_position = relative_position - i - S;
                        elseif relative_position - i < -S/2
                            relative_position = relative_position - i + S;
                        else
                            relative_position = relative_position - i;
                        end
                        temp_candidates = [temp_candidates, relative_position];
                    end
                end
                % 存入可建链集合
                inter_orbit_candidates{i, orbit} = temp_candidates;
            end
        end
        
        inter_orbit_candidates_all_times{t_idx} = inter_orbit_candidates;
    end
end