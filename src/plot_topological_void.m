function h_fig = plot_topological_void(pos_matrix, adj_matrix, failed_nodes, components, component_sizes, void_info, T, P, varargin)
% plot_topological_void - 拓扑空洞可视化函数
%
% 在2D经纬度平面图上显示：
%   - 地球简图背景
%   - 卫星节点位置（颜色区分所属连通分量）
%   - 星间链路
%   - 失效节点标记
%   - SAA高风险区域
%   - 空洞指标注释
%
% 输入:
%   pos_matrix - 卫星位置 (T x 3, [经度, 纬度, 高度])
%   adj_matrix - 邻接矩阵 (T x T)
%   failed_nodes - 失效节点索引数组（可选）
%   components - 连通分量cell数组
%   component_sizes - 各连通分量大小
%   void_info - 空洞检测结果结构体
%   T - 卫星总数
%   P - 轨道面数
%   varargin - 可选参数对:
%     'save_path' - 图片保存路径
%     'title' - 图表标题
%     'show_saa' - 是否显示SAA区域 (default: true)
%     'show_orbits' - 是否显示轨道线 (default: true)
%
% 输出:
%   h_fig - 图形句柄
%
% 作者: 基于创新点一要求设计
% 日期: 2026-03-30

    %% 解析可选参数
    p = inputParser;
    addOptional(p, 'save_path', '', @ischar);
    addOptional(p, 'title', '拓扑空洞可视化', @ischar);
    addOptional(p, 'show_saa', true, @islogical);
    addOptional(p, 'show_orbits', true, @islogical);
    parse(p, varargin{:});
    opts = p.Results;
    
    %% 创建图形窗口
    h_fig = figure('Position', [100, 100, 1200, 700], 'Color', 'w');
    
    %% 1. 绘制地球简图背景
    earth_simplified('2d');
    hold on;
    
    %% 2. 绘制轨道面（灰色虚线）
    if opts.show_orbits
        orbit_colors = 0.8 * ones(P, 3); % 灰色轨道
        for p_idx = 0:P-1
            plane_sats = find(floor((0:T-1)/P) == p_idx);
            if ~isempty(plane_sats)
                plane_lons = pos_matrix(plane_sats, 1);
                plane_lats = pos_matrix(plane_sats, 2);
                % 经度排序绘制轨道
                [~, sort_idx] = sort(plane_lons);
                plot(plane_lons(sort_idx), plane_lats(sort_idx), ...
                    'k--', 'LineWidth', 0.5, 'Color', orbit_colors(p_idx+1,:));
            end
        end
    end
    
    %% 3. 绘制星间链路
    [i, j] = find(adj_matrix > 0);
    % 为了效率，只绘制一部分链路
    link_idx = 1:min(50, length(i)):length(i); % 每隔一定距离绘制一条
    for idx = link_idx(:)'
        lon1 = pos_matrix(i(idx), 1); lat1 = pos_matrix(i(idx), 2);
        lon2 = pos_matrix(j(idx), 1); lat2 = pos_matrix(j(idx), 2);
        plot([lon1, lon2], [lat1, lat2], ...
            'Color', [0.3, 0.5, 0.8], 'LineWidth', 0.3);
    end
    
    %% 4. 确定颜色映射
    % 为主连通分量和每个非主连通分量分配不同颜色
    [~, main_idx] = max(component_sizes);
    colors = lines(length(components)); % 使用lines颜色表
    
    %% 5. 绘制各连通分量的节点
    for c = 1:length(components)
        comp_nodes = components{c};
        lon = pos_matrix(comp_nodes, 1);
        lat = pos_matrix(comp_nodes, 2);
        
        if c == main_idx
            % 主连通分量：黑色圆圈
            scatter(lon, lat, 80, 'k', 'o', 'filled', ...
                'MarkerFaceAlpha', 0.6, 'LineWidth', 1);
        else
            % 非主连通分量（空洞区域）：彩色圆圈
            scatter(lon, lat, 100, colors(c,:), 'o', 'filled', ...
                'MarkerFaceAlpha', 0.7, 'LineWidth', 2);
        end
    end
    
    %% 6. 标记失效节点（红色X）
    if nargin >= 3 && ~isempty(failed_nodes) && any(failed_nodes > 0)
        failed_nodes = failed_nodes(failed_nodes > 0 & failed_nodes <= T);
        if ~isempty(failed_nodes)
            plot(pos_matrix(failed_nodes, 1), pos_matrix(failed_nodes, 2), ...
                'rx', 'MarkerSize', 14, 'LineWidth', 2.5);
        end
    end
    
    %% 7. 高亮SAA区域
    if opts.show_saa
        saa_lon_min = -90; saa_lon_max = 15;
        saa_lat_min = -55; saa_lat_max = 15;
        rectangle('Position', [saa_lon_min, saa_lat_min, ...
            saa_lon_max - saa_lon_min, saa_lat_max - saa_lat_min], ...
            'EdgeColor', 'r', 'LineWidth', 2, 'LineStyle', '--', ...
            'FaceColor', [1, 0, 0, 0.08]);
        text(-40, 25, 'SAA', 'Color', 'r', 'FontSize', 14, 'FontWeight', 'bold');
    end
    
    %% 8. 添加指标注释框
    annotation_text = {
        sprintf('连通率 Rc = %.4f', void_info.connectivity_rate), ...
        sprintf('连通分量数 Nc = %d', void_info.num_components), ...
        sprintf('孤立节点率 Ri = %.4f', void_info.isolated_rate), ...
        sprintf('空洞面积指数 Av = %.4f', void_info.void_area_index), ...
        sprintf('代数连通度 = %.4f', void_info.algebraic_connectivity), ...
        sprintf('严重程度 = %.4f', void_info.severity_index), ...
        sprintf('空洞等级: %s', void_info.severity_index.grade)
    };
    
    annotation('textbox', [0.01, 0.35, 0.18, 0.35], ...
        'String', annotation_text, ...
        'FitBoxToText', 'on', ...
        'BackgroundColor', 'white', ...
        'EdgeColor', 'k', ...
        'FontSize', 9, ...
        'FontName', 'Consolas');
    
    %% 9. 添加图例
    legend_items = {};
    legend_handles = [];
    
    if ~isempty(failed_nodes) && any(failed_nodes > 0)
        [~, h_fail] = plot(nan, nan, 'rx', 'MarkerSize', 10, 'LineWidth', 2);
        legend_items{end+1} = '失效节点';
        legend_handles(end+1) = h_fail;
    end
    
    [~, h_main] = plot(nan, nan, 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
    legend_items{end+1} = '主连通分量';
    legend_handles(end+1) = h_main;
    
    if sum(component_sizes < max(component_sizes)) > 0
        [~, h_void] = plot(nan, nan, 'o', 'MarkerSize', 8, ...
            'MarkerFaceColor', 'flat', 'MarkerEdgeColor', 'auto');
        legend_items{end+1} = '空洞区域';
        legend_handles(end+1) = h_void;
    end
    
    if opts.show_saa
        [~, h_saa] = plot(nan, nan, 'r--', 'LineWidth', 2);
        legend_items{end+1} = 'SAA区域';
        legend_handles(end+1) = h_saa;
    end
    
    if ~isempty(legend_items)
        legend(legend_handles, legend_items, 'Location', 'eastoutside');
    end
    
    %% 10. 设置坐标轴和标题
    xlabel('经度 Longitude (°)', 'FontSize', 12);
    ylabel('纬度 Latitude (°)', 'FontSize', 12);
    title(opts.title, 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    axis equal;
    xlim([-180, 180]);
    ylim([-90, 90]);
    
    hold off;
    
    %% 11. 保存图片
    if ~isempty(opts.save_path)
        saveas(h_fig, opts.save_path);
        fprintf('图片已保存至: %s\n', opts.save_path);
    end
end

%% 辅助函数：绘制简化的地球背景
function earth_simplified(type)
    if strcmp(type, '2d')
        % 绘制经纬网格
        for lat = -60:30:60
            plot([-180, 180], [lat, lat], 'Color', [0.9, 0.9, 0.9], 'LineWidth', 0.3);
        end
        for lon = -150:30:150
            plot([lon, lon], [-90, 90], 'Color', [0.9, 0.9, 0.9], 'LineWidth', 0.3);
        end
        % 绘制赤道和本初子午线
        plot([-180, 180], [0, 0], 'Color', [0.7, 0.7, 0.7], 'LineWidth', 0.5);
        plot([0, 0], [-90, 90], 'Color', [0.7, 0.7, 0.7], 'LineWidth', 0.5);
    end
end