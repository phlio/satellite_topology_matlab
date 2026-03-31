function best_candidate = find_best_inter_orbit_link(current_sat, current_pos, candidate_indices, positions, mapping, max_distance, Re)
% 为当前卫星寻找最佳的异轨连接候选

    best_candidate = 0;
    best_score = -inf;
    
    for j = 1:length(candidate_indices)
        candidate_sat = candidate_indices(j);
        candidate_pos = positions(candidate_sat, :);
        
        % 计算距离
        distance = norm(current_pos - candidate_pos);
        
        if distance > max_distance
            continue; % 距离过远
        end
        
        if ~check_visibility(current_pos, candidate_pos, Re)
            continue; % 不可见
        end
        
        % 计算连接评分（综合考虑距离和轨道关系）
        distance_score = 1 - (distance / max_distance); % 距离越近分数越高
        orbit_relation_score = calculate_orbit_relation_score(current_sat, candidate_sat, mapping);
        
        total_score = 0.7 * distance_score + 0.3 * orbit_relation_score;
        
        if total_score > best_score
            best_score = total_score;
            best_candidate = candidate_sat;
        end
    end
end