function plotSatelliteTopology(graph_matrix, node_count, orbit_count, sat_per_orbit, full_graph_matrix, high_risk_satellites, time_point)

time_point_str = sprintf(' (时间点: %d)', time_point);
figure_name = sprintf('卫星星座拓扑连接图 - 时间点 %d', time_point);

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
figure('Name', figure_name, 'Position',[100 100 850 650]);
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

% 2. 如果提供了高风险区域卫星信息，用黄圈标记
if ~isempty(high_risk_satellites) && length(high_risk_satellites) == node_count
    for i = 1:node_count
        if high_risk_satellites(i)
            plot(x_coords(i), y_coords(i), 'o', ...
                'MarkerSize', 24, 'MarkerFaceColor', 'none', ...
                'MarkerEdgeColor', 'blue', 'LineWidth', 2);
        end
    end
end

% 3. 绘制断链（红色虚线）- 仅当提供了完整拓扑时
if ~isempty(full_graph_matrix) && size(full_graph_matrix, 1) == node_count
    for i = 1:node_count
        for j = i+1:node_count  % 仅画i<j避免重复
            % 如果完整拓扑中有连接，但受损拓扑中没有，则显示为断链
            if full_graph_matrix(i, j) == 1 && graph_matrix(i, j) == 0
                % 获取两个节点的轨道号
                orbit_i = ceil(i / sat_per_orbit);
                orbit_j = ceil(j / sat_per_orbit);
                sat_idx_i = mod(i-1, sat_per_orbit) + 1; % 节点i轨内序号
                sat_idx_j = mod(j-1, sat_per_orbit) + 1; % 节点j轨内序号
                % 获取节点坐标
                x1 = x_coords(i); y1 = y_coords(i);
                x2 = x_coords(j); y2 = y_coords(j);

                % 情况1：第一轨↔第六轨 → 弧线+红色虚线
                if (orbit_i==1 && orbit_j==orbit_count) || (orbit_i==orbit_count && orbit_j==1)
                    % 生成上凸弧线的参数点（避免与中间轨道重叠）
                    arc_num = 60; % 弧线采样点数（越多越平滑）
                    h = -1; % 上凸高度（可自定义，比如2、3等）

                    % 1. 计算贝塞尔曲线控制点（决定上凸位置）
                    mid_x0 = (x1 + x2)/2;  % 两点连线的水平中点
                    mid_y0 = (y1 + y2)/2;  % 两点连线的垂直中点
                    P0 = [x1, y1];         % 起点（贝塞尔曲线第一个控制点）
                    P1 = [mid_x0, mid_y0 + h];  % 上凸控制点（核心：向上偏移h）
                    P2 = [x2, y2];         % 终点（贝塞尔曲线第三个控制点）
                    % 2. 生成贝塞尔曲线参数t（0到1，等间距）
                    t = linspace(0, 1, arc_num);  
                    % 3. 计算贝塞尔曲线坐标（保证起点/终点精准连接）
                    arc_x = (1-t).^2 .* P0(1) + 2*(1-t).*t .* P1(1) + t.^2 .* P2(1);
                    arc_y = (1-t).^2 .* P0(2) + 2*(1-t).*t .* P1(2) + t.^2 .* P2(2);
                    % 绘制弧线（红色虚线）
                    plot(arc_x, arc_y, '--', 'Color', 'red', 'LineWidth', 1.2);
                   
                % 情况2：同轨道内首尾卫星（1号↔10号）→ 竖直下凸弧线+红色虚线
                elseif (orbit_i == orbit_j) && ((sat_idx_i==1 && sat_idx_j==sat_per_orbit) || (sat_idx_i==sat_per_orbit && sat_idx_j==1))
                    arc_num = 60; % 弧线采样点数（越多越平滑）
                    h = 0.5; % 上凸高度（可自定义，比如2、3等）
                    % 1. 计算贝塞尔曲线控制点（决定上凸位置）
                    mid_x0 = (x1 + x2)/2;  % 两点连线的水平中点
                    mid_y0 = (y1 + y2)/2;  % 两点连线的垂直中点
                    P0 = [x1, y1];         % 起点（贝塞尔曲线第一个控制点）
                    P1 = [mid_x0 + h, mid_y0];  % 上凸控制点（核心：向上偏移h）
                    P2 = [x2, y2];         % 终点（贝塞尔曲线第三个控制点）
                    % 2. 生成贝塞尔曲线参数t（0到1，等间距）
                    t = linspace(0, 1, arc_num);  
                    % 3. 计算贝塞尔曲线坐标（保证起点/终点精准连接）
                    arc_x = (1-t).^2 .* P0(1) + 2*(1-t).*t .* P1(1) + t.^2 .* P2(1);
                    arc_y = (1-t).^2 .* P0(2) + 2*(1-t).*t .* P1(2) + t.^2 .* P2(2);
                    % 4. 绘制弧线（红色虚线）
                    plot(arc_x, arc_y, '--', 'Color', 'red', 'LineWidth', 1.2);
                    
                % 情况3：其他链路 → 直线+红色虚线
                else
                    plot([x1, x2], [y1, y2], '--', 'Color', 'red', 'LineWidth', 1.2);
                end
            end
        end
    end
end

% 4. 绘制现有链路（核心：区分1-6轨弧线+虚线，其他直线+实线）
for i = 1:node_count
    for j = i+1:node_count  % 仅画i<j避免重复
        if graph_matrix(i, j) == 1
            % 获取两个节点的轨道号
            orbit_i = ceil(i / sat_per_orbit);
            orbit_j = ceil(j / sat_per_orbit);
            sat_idx_i = mod(i-1, sat_per_orbit) + 1; % 节点i轨内序号
            sat_idx_j = mod(j-1, sat_per_orbit) + 1; % 节点j轨内序号
            % 获取节点坐标
            x1 = x_coords(i); y1 = y_coords(i);
            x2 = x_coords(j); y2 = y_coords(j);

            % 情况1：第一轨↔第六轨 → 弧线+虚线
            if (orbit_i==1 && orbit_j==orbit_count) || (orbit_i==orbit_count && orbit_j==1)
                % 生成上凸弧线的参数点（避免与中间轨道重叠）
                arc_num = 60; % 弧线采样点数（越多越平滑）
                h = -1; % 上凸高度（可自定义，比如2、3等）

                % 1. 计算贝塞尔曲线控制点（决定上凸位置）
                mid_x0 = (x1 + x2)/2;  % 两点连线的水平中点
                mid_y0 = (y1 + y2)/2;  % 两点连线的垂直中点
                P0 = [x1, y1];         % 起点（贝塞尔曲线第一个控制点）
                P1 = [mid_x0, mid_y0 + h];  % 上凸控制点（核心：向上偏移h）
                P2 = [x2, y2];         % 终点（贝塞尔曲线第三个控制点）
                % 2. 生成贝塞尔曲线参数t（0到1，等间距）
                t = linspace(0, 1, arc_num);  
                % 3. 计算贝塞尔曲线坐标（保证起点/终点精准连接）
                arc_x = (1-t).^2 .* P0(1) + 2*(1-t).*t .* P1(1) + t.^2 .* P2(1);
                arc_y = (1-t).^2 .* P0(2) + 2*(1-t).*t .* P1(2) + t.^2 .* P2(2);
                % 绘制弧线（虚线）
                plot(arc_x, arc_y, '-', 'Color', 'cyan', 'LineWidth', 0.8);
               
            % 情况2：同轨道内首尾卫星（1号↔10号）→ 竖直下凸弧线+虚线
            elseif (orbit_i == orbit_j) && ((sat_idx_i==1 && sat_idx_j==sat_per_orbit) || (sat_idx_i==sat_per_orbit && sat_idx_j==1))
                arc_num = 60; % 弧线采样点数（越多越平滑）
                h = 0.5; % 上凸高度（可自定义，比如2、3等）
                % 1. 计算贝塞尔曲线控制点（决定上凸位置）
                mid_x0 = (x1 + x2)/2;  % 两点连线的水平中点
                mid_y0 = (y1 + y2)/2;  % 两点连线的垂直中点
                P0 = [x1, y1];         % 起点（贝塞尔曲线第一个控制点）
                P1 = [mid_x0 + h, mid_y0];  % 上凸控制点（核心：向上偏移h）
                P2 = [x2, y2];         % 终点（贝塞尔曲线第三个控制点）
                % 2. 生成贝塞尔曲线参数t（0到1，等间距）
                t = linspace(0, 1, arc_num);  
                % 3. 计算贝塞尔曲线坐标（保证起点/终点精准连接）
                arc_x = (1-t).^2 .* P0(1) + 2*(1-t).*t .* P1(1) + t.^2 .* P2(1);
                arc_y = (1-t).^2 .* P0(2) + 2*(1-t).*t .* P1(2) + t.^2 .* P2(2);
                % 4. 绘制弧线（颜色/线宽可自定义）
                plot(arc_x, arc_y, '-', 'Color', 'cyan', 'LineWidth', 0.8);
                
            % 情况3：其他链路 → 直线+实线
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
    title('卫星星座拓扑连接图', 'FontSize', 12);
else
    title(['卫星星座拓扑连接图' time_point_str], 'FontSize', 12);
end
xticks(1:orbit_count);
%     xticklabels({'1轨道','2轨道','3轨道','4轨道','5轨道','6轨道'});
yticks(1:sat_per_orbit);
axis([0, orbit_count+1, 0, sat_per_orbit+1]); % 预留边缘空间
hold off;