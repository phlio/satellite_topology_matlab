function visualize_topology(positions, mapping, graph_matrix, T, P, S, U)
% MATLAB 2021a兼容版拓扑可视化函数
% 移除了不支持的'Alpha'属性，使用颜色和线型区分连接类型

    figure('Position', [100, 100, 1000, 800], 'Name', '卫星网络拓扑可视化（兼容版）');
    
    % 提取位置数据
    x = positions(:, 1);
    y = positions(:, 2);
    z = positions(:, 3);
    
    % 三维散点图
    subplot(2,2,[1,3]);
    scatter3(x, y, z, 50, 'filled', 'MarkerFaceColor', [0.2, 0.4, 0.8]);
    hold on;
    
    % 绘制同轨链路
    colors = lines(P);
    for orbit = 1:P
        orbit_sats = find([mapping.orbit] == orbit);
        orbit_pos = positions(orbit_sats, :);
        
        % 绘制轨道线（使用虚线表示同轨连接）
        plot3(orbit_pos(:,1), orbit_pos(:,2), orbit_pos(:,3), '--', ...
              'Color', colors(orbit,:), 'LineWidth', 1.5);
    end
    
    % 绘制异轨链路（兼容MATLAB 2021a）
    for i = 1:T
        for j = i+1:T
            if graph_matrix(i, j) > 0
                % 检查连接类型
                orbit_i = mapping(i).orbit;
                orbit_j = mapping(j).orbit;
                
                if (orbit_i == P && orbit_j == 1) || (orbit_i == 1 && orbit_j == P)
                    % 首尾轨道间的扭曲连接 - 红色实线
                    plot3([x(i), x(j)], [y(i), y(j)], [z(i), z(j)], ...
                          'r-', 'LineWidth', 2.5, 'Color', [1, 0, 0]);
                else
                    % 普通异轨连接 - 蓝色虚线，使用浅蓝色区分
                    plot3([x(i), x(j)], [y(i), y(j)], [z(i), z(j)], ...
                          ':', 'LineWidth', 1, 'Color', [0.4, 0.6, 1.0]);
                end
            end
        end
    end
    
    xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
    title(sprintf('Walker星座拓扑可视化\n%d/%d/%d, U=%d', T, P, S, U));
    grid on;
    axis equal;
    
    % 添加图例
    legend('卫星节点', '同轨链路', '扭曲异轨链路', '普通异轨链路', ...
           'Location', 'northeastoutside');
    
    % 二维投影图
    subplot(2,2,2);
    scatter(x, y, 40, 'filled', 'MarkerFaceColor', [0.2, 0.4, 0.8]);
    xlabel('X (km)'); ylabel('Y (km)');
    title('XY平面投影'); grid on;
    
    subplot(2,2,4);
    scatter(x, z, 40, 'filled', 'MarkerFaceColor', [0.2, 0.4, 0.8]);
    xlabel('X (km)'); ylabel('Z (km)');
    title('XZ平面投影'); grid on;
    
    % 添加统计信息注释
    avg_hops = mean(graph_matrix(graph_matrix > 0));
    diameter = max(graph_matrix(:));
    
    info_str = sprintf(['拓扑统计信息:\n' ...
                       '卫星总数: %d\n' ...
                       '轨道数: %d\n' ...
                       '每轨卫星: %d\n' ...
                       '扭曲因子: %d\n' ...
                       '平均跳数: %.3f\n' ...
                       '网络直径: %d'], ...
                       T, P, S, U, avg_hops, diameter);
    
    annotation('textbox', [0.02, 0.02, 0.25, 0.15], ...
               'String', info_str, 'FontSize', 9, ...
               'BackgroundColor', 'white', 'EdgeColor', 'black');
end