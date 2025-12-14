function plotSatelliteTopology(graph_matrix)
    % plotSatelliteTopology - 60颗卫星拓扑图（第一/六轨弧线+样式区分，MATLAB 2021a兼容）
    % 输入：graph_matrix - 60x60 double矩阵，0=无连接，1=有连接
    % 特性：1-6轨链路→上凸弧线+虚线；其他链路→直线+实线


    %% 星座基础参数
    orbit_count = 6;       % 轨道数
    sat_per_orbit = 10;    % 每轨卫星数
    node_count = 60;       % 总卫星数

    %% 计算卫星坐标+编号
    x_coords = zeros(node_count, 1);  % 轨道x坐标（1-6）
    y_coords = zeros(node_count, 1);  % 轨道内y坐标（1-10）
    node_labels = cell(node_count, 1);% 编号（101-610）

    for i = 1:node_count
        orbit_idx = ceil(i / sat_per_orbit);        % 轨道号（1-6）
        sat_in_orbit_idx = mod(i-1, sat_per_orbit) + 1; % 轨内序号（1-10）
        x_coords(i) = orbit_idx;
        y_coords(i) = sat_in_orbit_idx;
        node_labels{i} = sprintf('%d%02d', orbit_idx, sat_in_orbit_idx);
    end

    %% 绘制拓扑图
    figure('Name','卫星星座拓扑连接图','Position',[100 100 850 650]);
    hold on; grid on;

    % 1. 绘制卫星节点（白色填充+黑色边框）
    for i = 1:node_count
        plot(x_coords(i), y_coords(i), 'o', ...
            'MarkerSize', 20, 'MarkerFaceColor', 'white', ...
            'MarkerEdgeColor', 'black', 'LineWidth', 1.5);
        % 标注卫星编号
        text(x_coords(i), y_coords(i), node_labels{i}, ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
            'FontSize', 8, 'FontWeight', 'bold');
    end

    % 2. 绘制链路（核心：区分1-6轨弧线+虚线，其他直线+实线）
    link_color = [0.6 0.6 0.6]; % 链路基础灰色
    for i = 1:node_count
        for j = i+1:node_count  % 仅画i<j避免重复
            if graph_matrix(i, j) == 1
                % 获取两个节点的轨道号
                orbit_i = ceil(i / sat_per_orbit);
                orbit_j = ceil(j / sat_per_orbit);
                % 获取节点坐标
                x1 = x_coords(i); y1 = y_coords(i);
                x2 = x_coords(j); y2 = y_coords(j);

                % 情况1：第一轨↔第六轨 → 弧线+虚线
                if (orbit_i==1 && orbit_j==6) || (orbit_i==6 && orbit_j==1)
                    % 生成上凸弧线的参数点（避免与中间轨道重叠）
                    arc_num = 50; % 弧线采样点数（越多越平滑）
                    t = linspace(0, pi/2, arc_num); % 弧度参数
                    % 弧线中点偏移（上凸）
                    mid_x = (x1 + x2)/2;
                    mid_y = (y1 + y2)/2 + 2; % 上凸2个单位，适配图表尺寸
                    % 生成弧线坐标
                    arc_x = mid_x + (x2 - mid_x)*cos(t) - (mid_y - y1)*sin(t);
                    arc_y = mid_y - (mid_y - y1)*cos(t) - (x2 - mid_x)*sin(t);
                    % 绘制弧线（虚线）
                    plot(arc_x, arc_y, '--', 'Color', link_color, 'LineWidth', 0.8);

                % 情况2：其他链路 → 直线+实线
                else
                    plot([x1, x2], [y1, y2], '-', 'Color', link_color, 'LineWidth', 0.8);
                end
            end
        end
    end

    %% 图表美化
    xlabel('轨道编号', 'FontSize', 10);
    ylabel('轨道内卫星编号', 'FontSize', 10);
    title('卫星星座拓扑连接图（1/6轨弧线连接）', 'FontSize', 12);
    xticks(1:orbit_count);
    xticklabels({'1轨道','2轨道','3轨道','4轨道','5轨道','6轨道'});
    yticks(1:sat_per_orbit);
    axis([0, orbit_count+1, 0, sat_per_orbit+1]); % 预留边缘空间
    hold off;
end