function change_rate = calculate_topology_change(prev_topology, current_topology)
% 计算拓扑变化率
% 输入: prev_topology-前一时刻拓扑, current_topology-当前时刻拓扑
% 输出: change_rate-拓扑变化率（0-1）

    % 计算杰卡德距离
    intersection = nnz(prev_topology & current_topology);
    union = nnz(prev_topology | current_topology);
    
    if union == 0
        change_rate = 0;
    else
        change_rate = 1 - intersection / union;
    end
end