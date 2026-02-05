function [updated_graph, high_risk_satellites] = apply_single_event_upset_effect(graph_matrix, sat_lat_lon, seu_probability)
% 应用单粒子翻转(SEU)效应对卫星拓扑的影响
% SEU主要影响特定地理区域内的卫星和链路
% 纬度-55°到15°和经度-90°到15°的区域为高风险区域(占95%的SEU事件)
% 失效概率与到高风险区域中心的距离相关，越靠近中心失效概率越高
%
% 输入:
%   graph_matrix - 卫星连接关系的对称矩阵 (T x T)
%   sat_lat_lon - 当前时刻所有卫星的经纬度 [纬度, 经度] 矩阵 (T x 2)
%   seu_probability - 整体单粒子翻转概率，默认0.005
%
% 输出:
%   updated_graph - 应用SEU效应后的更新连接矩阵
    
    % 获取卫星总数
    T = size(graph_matrix, 1);
    
    % 创建更新后的图矩阵副本
    updated_graph = graph_matrix;
    
    fprintf('      应用单粒子翻转效应 (概率=%.4f)...\n', seu_probability);
    
    % 定义高风险区域边界
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
    
    % 识别高风险区域内的卫星并计算其到中心的归一化距离
    high_risk_satellites = false(T, 1);
    normalized_distances = ones(T, 1); % 默认距离为1（最大距离）
    
    for i = 1:T
        lat = sat_lat_lon(i, 1);
        lon = sat_lat_lon(i, 2);
        
        % 检查是否在高风险区域内
        % 纬度: -55° 到 15° (南纬55°到北纬15°)
        % 经度: -90° 到 15° (西经90°到东经15°)
        in_latitude_zone = (lat >= lat_min) && (lat <= lat_max);
        in_longitude_zone = (lon >= lon_min) && (lon <= lon_max);
        
        if in_latitude_zone && in_longitude_zone
            high_risk_satellites(i) = true;
            % 计算到中心点的归一化距离（使用曼哈顿距离的归一化形式）
            % 归一化：将纬度和经度差分别除以各自的一半范围
            norm_lat_diff = abs(lat - center_lat) / half_lat_range;
            norm_lon_diff = abs(lon - center_lon) / half_lon_range;
            % 使用最大值作为归一化距离（确保在[0,1]范围内）
            normalized_distances(i) = max(norm_lat_diff, norm_lon_diff);
        end
    end
    
    % 计算高风险区域内的卫星数量
    num_high_risk = sum(high_risk_satellites);
    fprintf('      高风险区域内卫星数量: %d/%d\n', num_high_risk, T);
    
    % 设置基础概率（按照用户要求）
    % 链路高风险基础概率：seu_probability * 4.19
    % 链路低风险基础概率：seu_probability * 0.06
    % 节点高风险基础概率：链路高风险概率的1/4
    % 节点低风险基础概率：链路低风险概率的1/4
    link_high_risk_base_prob = seu_probability * 4.19;
    link_low_risk_base_prob = seu_probability * 0.06;
    node_high_risk_base_prob = link_high_risk_base_prob / 4;
    node_low_risk_base_prob = link_low_risk_base_prob / 4;
    
    % 第一步：处理卫星节点失效（断开受影响卫星的所有链路）
    affected_satellites = false(T, 1);
    
    % 对所有卫星计算实际节点失效概率
    node_actual_probabilities = zeros(T, 1);
    
    for i = 1:T
        if high_risk_satellites(i)
            % 高风险区域内的卫星：从边缘的seu_probability到中心node_high_risk_base_prob的1.6倍
            % normalized_distances(i) 在 [0,1] 范围内，0表示中心，1表示边缘
            node_actual_probabilities(i) = (seu_probability - 1.6 * node_high_risk_base_prob) * normalized_distances(i) + 1.6 * node_high_risk_base_prob;
        else
            % 低风险区域的卫星
            node_actual_probabilities(i) = node_low_risk_base_prob;
        end
    end
    
    % 应用SEU（节点失效）
    rand_vals = rand(T, 1);
    affected_satellites = rand_vals < node_actual_probabilities;
    
    total_affected_nodes = sum(affected_satellites);
    
    % 断开受影响卫星的所有链路
    if total_affected_nodes > 0
        fprintf('      SEU导致 %d 个卫星节点失效\n', total_affected_nodes);
        for i = 1:T
            if affected_satellites(i)
                updated_graph(i, :) = 0;
                updated_graph(:, i) = 0;
            end
        end
    end
    
    % 第二步：处理链路失效（遍历所有剩余的链路）
    broken_links_from_edges = 0;
    
    % 遍历上三角矩阵（因为是对称矩阵）
    for i = 1:T
        for j = i+1:T
            if updated_graph(i, j) == 1  % 如果链路还存在
                if high_risk_satellites(i) || high_risk_satellites(j)
                    % 高风险链路：至少一端在高风险区域
                    % 计算链路到高风险区域中心的加权距离
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
                    % 链路概率：从边缘的link_high_risk_base_prob到中心的1.6倍
                    link_actual_prob = (seu_probability - 1.6 * link_high_risk_base_prob) * link_norm_dist + 1.6 * link_high_risk_base_prob;
                    
                    if rand() < link_actual_prob
                        updated_graph(i, j) = 0;
                        updated_graph(j, i) = 0;
                        broken_links_from_edges = broken_links_from_edges + 1;
                    end
                else
                    % 低风险链路：使用低风险概率
                    if rand() < link_low_risk_base_prob
                        updated_graph(i, j) = 0;
                        updated_graph(j, i) = 0;
                        broken_links_from_edges = broken_links_from_edges + 1;
                    end
                end
            end
        end
    end
    
    % 统计总断开的链路数
    original_edges = nnz(graph_matrix) / 2;
    updated_edges = nnz(updated_graph) / 2;
    total_broken_links = original_edges - updated_edges;
    
    if total_broken_links > 0
        fprintf('      SEU总共导致 %d 条链路断开 (%d 来自节点失效, %d 来自链路失效)\n', ...
                total_broken_links, total_broken_links - broken_links_from_edges, broken_links_from_edges);
    else
        fprintf('      无链路受SEU影响\n');
    end
end