function plot_high_risk_subgraph(graph_matrix, mapping, high_risk_satellites, time_point, orbit_count, sat_per_orbit)
% 绘制高风险区域子图
% 输入:
%   graph_matrix - 子图邻接矩阵
%   mapping - 卫星映射结构体
%   high_risk_satellites - 高风险卫星标记向量
%   time_point - 当前时间点
%   orbit_count - 轨道总数
%   sat_per_orbit - 每轨道卫星数

    time_point_str = sprintf(' (时间点: %d)', time_point);
    figure_name = sprintf('高风险区域子图拓扑 - 时间点 %d', time_point);

    %% 计算卫星坐标+编号
    node_count = size(graph_matrix, 1);
    x_coords = zeros(node_count, 1);  % 轨道x坐标（1-P）
    y_coords = zeros(node_count, 1);  % 轨道内y坐标（1-S）
    node_labels = cell(node_count, 1);% 编号（轨道号+卫星号）

    for i = 1:node_count
        orbit_idx = mapping.orbit(i);        % 轨道号（1-P）
        sat_in_orbit_idx = mapping.sat_in_orbit(i); % 轨内序号（1-S）
        x_coords(i) = orbit_idx;
        y_coords(i) = sat_in_orbit_idx;
        node_labels{i} = sprintf('%d%02d', orbit_idx, sat_in_orbit_idx);
    end

    %% 绘制拓扑图
    figure('Name', figure_name, 'Position',[100 100 850 650]);
    hold on; grid on;

    % 1. 绘制卫星节点
    for i = 1:node_count
        if high_risk_satellites(i)
            % 高风险卫星：红色填充
            plot(x_coords(i), y_coords(i), 'o', ...
                'MarkerSize', 20, 'MarkerFaceColor', 'red', ...
                'MarkerEdgeColor', 'black', 'LineWidth', 1.5);
        else
            % 普通卫星：白色填充
            plot(x_coords(i), y_coords(i), 'o', ...
                'MarkerSize', 20, 'MarkerFaceColor', 'white', ...
                'MarkerEdgeColor', 'black', 'LineWidth', 1.5);
        end
        % 标注卫星编号
        text(x_coords(i), y_coords(i), node_labels{i}, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontSize', 8, 'FontWeight', 'bold');
    end

    % 2. 绘制链路（核心：区分1-P轨弧线+虚线，其他直线+实线）
    for i = 1:node_count
        for j = i+1:node_count  % 仅画i<j避免重复
            if graph_matrix(i, j) == 1
                % 获取两个节点的轨道号
                orbit_i = mapping.orbit(i);
                orbit_j = mapping.orbit(j);
                sat_idx_i = mapping.sat_in_orbit(i);
                sat_idx_j = mapping.sat_in_orbit(j);
                % 获取节点坐标
                x1 = x_coords(i); y1 = y_coords(i);
                x2 = x_coords(j); y2 = y_coords(j);

                % 情况1：第一轨↔最后一轨 → 弧线
                if (orbit_i==1 && orbit_j==orbit_count) || (orbit_i==orbit_count && orbit_j==1)
                    % 生成上凸弧线的参数点
                    arc_num = 60;
                    h = -1;

                    % 计算贝塞尔曲线控制点
                    mid_x0 = (x1 + x2)/2;
                    mid_y0 = (y1 + y2)/2;
                    P0 = [x1, y1];
                    P1 = [mid_x0, mid_y0 + h];
                    P2 = [x2, y2];
                    % 生成贝塞尔曲线参数t
                    t = linspace(0, 1, arc_num);
                    % 计算贝塞尔曲线坐标
                    arc_x = (1-t).^2 .* P0(1) + 2*(1-t).*t .* P1(1) + t.^2 .* P2(1);
                    arc_y = (1-t).^2 .* P0(2) + 2*(1-t).*t .* P1(2) + t.^2 .* P2(2);
                    % 绘制弧线
                    plot(arc_x, arc_y, '-', 'Color', 'cyan', 'LineWidth', 0.8);
                   
                % 情况2：同轨道内首尾卫星 → 竖直下凸弧线
                elseif (orbit_i == orbit_j) && ((sat_idx_i==1 && sat_idx_j==sat_per_orbit) || (sat_idx_i==sat_per_orbit && sat_idx_j==1))
                    arc_num = 60;
                    h = 0.5;
                    % 计算贝塞尔曲线控制点
                    mid_x0 = (x1 + x2)/2;
                    mid_y0 = (y1 + y2)/2;
                    P0 = [x1, y1];
                    P1 = [mid_x0 + h, mid_y0];
                    P2 = [x2, y2];
                    % 生成贝塞尔曲线参数t
                    t = linspace(0, 1, arc_num);
                    % 计算贝塞尔曲线坐标
                    arc_x = (1-t).^2 .* P0(1) + 2*(1-t).*t .* P1(1) + t.^2 .* P2(1);
                    arc_y = (1-t).^2 .* P0(2) + 2*(1-t).*t .* P1(2) + t.^2 .* P2(2);
                    % 绘制弧线
                    plot(arc_x, arc_y, '-', 'Color', 'cyan', 'LineWidth', 0.8);
                    
                % 情况3：其他链路 → 直线
                else
                    plot([x1, x2], [y1, y2], '-', 'Color', 'cyan', 'LineWidth', 0.8);
                end
            end
        end
    end

    %% 图表美化
    xlabel('轨道编号', 'FontSize', 10);
    ylabel('轨道内卫星编号', 'FontSize', 10);
    if isempty(time_point_str)
        title('高风险区域子图拓扑', 'FontSize', 12);
    else
        title(['高风险区域子图拓扑' time_point_str], 'FontSize', 12);
    end
    xticks(1:orbit_count);
    yticks(1:sat_per_orbit);
    axis([0, orbit_count+1, 0, sat_per_orbit+1]); % 预留边缘空间
    
    % 添加图例说明 - 创建示例点
    % 在图外创建两个不可见的示例点用于图例
    h1 = plot(-10, -10, 'o', 'MarkerSize', 20, 'MarkerFaceColor', 'white', ...
              'MarkerEdgeColor', 'black', 'LineWidth', 1.5);
    h2 = plot(-10, -10, 'o', 'MarkerSize', 20, 'MarkerFaceColor', 'red', ...
              'MarkerEdgeColor', 'black', 'LineWidth', 1.5);
    legend([h1, h2], {'普通卫星', '高风险卫星'}, 'Location', 'northeastoutside');
    
    hold off;
end