function analyze_topology_properties(graph_matrix, positions, mapping, T, P, S, current_time)
% 分析拓扑属性

    fprintf('      时间点 t=%.1f秒 拓扑分析:\n', current_time);
    
    % 计算平均链路长度
    total_length = 0;
    link_count = 0;
    
    for i = 1:T
        for j = i+1:T
            if graph_matrix(i, j) > 0
                dist = norm(positions(i, :) - positions(j, :));
                total_length = total_length + dist;
                link_count = link_count + 1;
            end
        end
    end
    
    if link_count > 0
        avg_link_length = total_length / link_count;
        fprintf('        平均链路长度: %.2f km\n', avg_link_length);
    end
    
    % 分析连通性
    [bin, binsize] = conncomp(graph(graph_matrix > 0));
    if max(binsize) == T
        fprintf('        网络连通性: 全连通 ✓\n');
    else
        fprintf('        网络连通性: %d个连通分量\n', length(unique(bin)));
    end
    
    % 分析同轨与异轨链路比例
    intra_orbit_links = 0;
    inter_orbit_links = 0;
    
    for i = 1:T
        for j = i+1:T
            if graph_matrix(i, j) > 0
                orbit_i = mapping(i).orbit;
                orbit_j = mapping(j).orbit;
                
                if orbit_i == orbit_j
                    intra_orbit_links = intra_orbit_links + 1;
                else
                    inter_orbit_links = inter_orbit_links + 1;
                end
            end
        end
    end
    
    fprintf('        链路统计: 同轨链路=%d, 异轨链路=%d\n', intra_orbit_links, inter_orbit_links);
    
    % 分析节点度数分布
    node_degrees = sum(graph_matrix, 2);
    fprintf('        度数分布: ');
    unique_degrees = unique(node_degrees);
    for d = unique_degrees'
        count = sum(node_degrees == d);
        fprintf('%d度:%d ', d, count);
    end
    fprintf('\n');
end