function [updated_graph, high_risk_links_before, high_risk_links_after] = apply_high_risk_link_failure_effect_quiet(graph_matrix, sat_lat_lon, high_risk_satellites)
% 应用高风险区域断链效应对卫星拓扑的影响（静默版本）
% 高风险区域中心断链概率为70%，边缘为20%
% 断链概率与到高风险区域中心的距离相关，越靠近中心断链概率越高
%
% 输入:
%   graph_matrix - 卫星连接关系的对称矩阵 (T x T)
%   sat_lat_lon - 当前时刻所有卫星的经纬度 [纬度, 经度] 矩阵 (T x 2)
%   high_risk_satellites - 高风险区域内的卫星标识向量 (T x 1)
%
% 输出:
%   updated_graph - 应用断链效应后的更新连接矩阵
%   high_risk_links_before - 断链前高风险区域内的链路数量
%   high_risk_links_after - 断链后高风险区域内的链路数量
    
    % 获取卫星总数
    T = size(graph_matrix, 1);
    
    % 创建更新后的图矩阵副本
    updated_graph = graph_matrix;
    
    % 定义高风险区域边界（与stk_analyze_high_risk_subgraph.m保持一致）
    lat_min = -55;   % 南纬55°
    lat_max = 15;    % 北纬15°
    lon_min = -90;   % 西经90°
    lon_max = 15;    % 东经15°
    
    % 计算高风险区域中心点
    center_lat = (lat_min + lat_max) / 2;   % -20°
    center_lon = (lon_min + lon_max) / 2;   % -37.5°
    
    % 计算高风险区域的半宽和半高（用于归一化距离）
    half_lat_range = (lat_max - lat_min) / 2;  % 35°
    half_lon_range = (lon_max - lon_min) / 2;  % 52.5°
    
    % 确保sat_lat_lon是T×2矩阵
    if size(sat_lat_lon, 1) ~= T || size(sat_lat_lon, 2) ~= 2
        error('sat_lat_lon维度不匹配，应为%d×2矩阵', T);
    end
    
    % 计算高风险区域内卫星到中心的归一化距离
    normalized_distances = ones(T, 1); % 默认距离为1（最大距离）
    
    for i = 1:T
        if high_risk_satellites(i)
            lat = sat_lat_lon(i, 1);
            lon = sat_lat_lon(i, 2);
            % 计算到中心点的归一化距离（使用曼哈顿距离的归一化形式）
            norm_lat_diff = abs(lat - center_lat) / half_lat_range;
            norm_lon_diff = abs(lon - center_lon) / half_lon_range;
            % 使用最大值作为归一化距离（确保在[0,1]范围内）
            normalized_distances(i) = max(norm_lat_diff, norm_lon_diff);
        end
    end
    
    % 设置断链概率参数
    center_failure_prob = 0.7;  % 中心断链概率70%
    edge_failure_prob = 0.2;    % 边缘断链概率20%
    
    % 初始化统计变量
    affected_links_count = 0;   % 受高风险区域影响的链路数
    broken_links_count = 0;     % 实际断开的链路数
    
    % 计算断链前高风险区域内的链路数量
    high_risk_links_before = 0;
    for i = 1:T
        for j = i+1:T
            if graph_matrix(i, j) == 1 && (high_risk_satellites(i) || high_risk_satellites(j))
                high_risk_links_before = high_risk_links_before + 1;
            end
        end
    end
    
    % 处理链路失效（遍历所有链路）
    % 遍历上三角矩阵（因为是对称矩阵）
    for i = 1:T
        for j = i+1:T
            if updated_graph(i, j) == 1  % 如果链路存在
                % 检查链路是否至少有一端在高风险区域
                if high_risk_satellites(i) || high_risk_satellites(j)
                    % 增加受影响链路计数
                    affected_links_count = affected_links_count + 1;
                    
                    % 计算链路的归一化距离
                    if high_risk_satellites(i) && high_risk_satellites(j)
                        % 两端都在高风险区域，取较近的距离
                        link_norm_dist = min(normalized_distances(i), normalized_distances(j));
                    elseif high_risk_satellites(i)
                        % 只有i在高风险区域
                        link_norm_dist = normalized_distances(i);
                    else
                        % 只有j在高风险区域
                        link_norm_dist = normalized_distances(j);
                    end
                    
                    % 根据归一化距离计算实际断链概率
                    % 归一化距离0表示中心，1表示边缘
                    % 使用线性插值：prob = edge_prob + (center_prob - edge_prob) * (1 - norm_dist)
                    link_actual_prob = edge_failure_prob + (center_failure_prob - edge_failure_prob) * (1 - link_norm_dist);
                    
                    if rand() < link_actual_prob
                        updated_graph(i, j) = 0;
                        updated_graph(j, i) = 0;
                        % 增加断开链路计数
                        broken_links_count = broken_links_count + 1;
                    end
                end
            end
        end
    end
    
    % 计算断链后高风险区域内的链路数量
    high_risk_links_after = 0;
    for i = 1:T
        for j = i+1:T
            if updated_graph(i, j) == 1 && (high_risk_satellites(i) || high_risk_satellites(j))
                high_risk_links_after = high_risk_links_after + 1;
            end
        end
    end
    
    % 静默版本：移除所有fprintf语句
end