function analyze_detailed_topology(sat_positions, sat_mapping, topology_sequence, time_data, T, P, S, max_time_points)
% 详细拓扑分析

    fprintf('   详细拓扑分析...\n');
    
    % 选择关键时间点进行深度分析
    if max_time_points >= 3
        key_timepoints = [1, round(max_time_points/2), max_time_points];
    else
        key_timepoints = 1:max_time_points;
    end
    
    for i = 1:length(key_timepoints)
        t_idx = key_timepoints(i);
        fprintf('\n--- 时间点 %d (t=%.1f秒) 详细分析 ---\n', t_idx, time_data(t_idx));
        
        current_positions = sat_positions{t_idx};
        graph_matrix = topology_sequence{t_idx};
        
        % 分析拓扑特性
        analyze_topology_properties(graph_matrix, current_positions, sat_mapping, T, P, S, time_data(t_idx));
    end
end