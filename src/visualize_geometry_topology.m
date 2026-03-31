function visualize_geometry_topology(positions, mapping, graph_matrix, T, P, S, current_time)
% 基于几何位置的拓扑可视化

    figure('Position', [100, 100, 1200, 900], 'Name', sprintf('几何拓扑可视化 (t=%.1f秒)', current_time));
    
    % 提取位置数据
    x = positions(:, 1);
    y = positions(:, 2);
    z = positions(:, 3);
    
    % 1. 三维拓扑图
    subplot(2,3,[1,4]);
    hold on;
    
    % 绘制地球
    Re = 6371.393;
    [X, Y, Z] = sphere(50);
    surf(X*Re, Y*Re, Z*Re, 'FaceColor', [0.2, 0.4, 0.8], 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    
    % 按轨道着色绘制卫星
    colors = lines(P);
    for orbit = 1:P
        orbit_indices = find([mapping.orbit] == orbit);
        scatter3(x(orbit_indices), y(orbit_indices), z(orbit_indices), ...
                 60, 'filled', 'MarkerFaceColor', colors(orbit,:), 'MarkerEdgeColor', 'k');
    end
    
    % 绘制链路
    link_count = 0;
    for i = 1:T
        for j = i+1:T
            if graph_matrix(i, j) > 0
                link_count = link_count + 1;
                orbit_i = mapping(i).orbit;
                orbit_j = mapping(j).orbit;
                
                % 根据链路类型设置颜色和线型
                if orbit_i == orbit_j
                    % 同轨链路 - 实线
                    plot3([x(i), x(j)], [y(i), y(j)], [z(i), z(j)], ...
                          '-', 'Color', colors(orbit_i,:), 'LineWidth', 1.5);
                else
                    % 异轨链路 - 虚线
                    if (orbit_i == 1 && orbit_j == P) || (orbit_i == P && orbit_j == 1)
                        % 首尾轨道间扭曲连接 - 红色粗虚线
                        plot3([x(i), x(j)], [y(i), y(j)], [z(i), z(j)], ...
                              '--', 'Color', 'red', 'LineWidth', 2.5);
                    else
                        % 普通异轨连接 - 灰色虚线
                        plot3([x(i), x(j)], [y(i), y(j)], [z(i), z(j)], ...
                              ':', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1);
                    end
                end
            end
        end
    end
    
    xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
    title(sprintf('三维几何拓扑 (总链路: %d)', link_count));
    grid on; axis equal;
    
    % 2. XY平面投影
    subplot(2,3,2);
    for orbit = 1:P
        orbit_indices = find([mapping.orbit] == orbit);
        scatter(x(orbit_indices), y(orbit_indices), 40, 'filled', ...
                'MarkerFaceColor', colors(orbit,:));
        hold on;
    end
    xlabel('X (km)'); ylabel('Y (km)');
    title('XY平面投影'); grid on;
    
    % 3. 链路长度分布直方图
    subplot(2,3,5);
    link_lengths = [];
    for i = 1:T
        for j = i+1:T
            if graph_matrix(i, j) > 0
                dist = norm(positions(i, :) - positions(j, :));
                link_lengths(end+1) = dist;
            end
        end
    end
    
    if ~isempty(link_lengths)
        histogram(link_lengths, 20, 'FaceColor', [0.3, 0.6, 0.9]);
        xlabel('链路长度 (km)'); ylabel('频数');
        title('链路长度分布');
        grid on;
    end
    
    % 4. 网络度数分布
    subplot(2,3,3);
    node_degrees = sum(graph_matrix, 2);
    histogram(node_degrees, 'FaceColor', [0.9, 0.5, 0.2]);
    xlabel('节点度数'); ylabel('频数');
    title('网络度数分布');
    grid on;
    
    % 5. 拓扑矩阵可视化
    subplot(2,3,6);
    imagesc(graph_matrix);
    colormap([1,1,1; 0,0,0]); % 黑白显示
    xlabel('卫星编号'); ylabel('卫星编号');
    title('邻接矩阵');
    colorbar;
    
    % 添加统计信息
    info_str = sprintf(['拓扑统计信息 (t=%.1fs):\n' ...
                       '卫星总数: %d\n' ...
                       '轨道数: %d\n' ...
                       '总链路数: %d\n' ...
                       '网络直径: %d\n' ...
                       '平均度数: %.2f'], ...
                       current_time, T, P, nnz(graph_matrix)/2, ...
                       calculate_network_diameter(graph_matrix), mean(node_degrees));
    
    annotation('textbox', [0.02, 0.02, 0.25, 0.15], ...
               'String', info_str, 'FontSize', 9, ...
               'BackgroundColor', 'white', 'EdgeColor', 'black');
end