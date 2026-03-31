function [boundary_density, boundary_nodes] = calculate_boundary_density(adj_matrix, components, main_idx, pos_matrix)
% calculate_boundary_density - 计算拓扑空洞边界节点密度
%
% 边界节点定义：属于非主连通分量，但至少有一个邻居属于主连通分量的节点
% 这些节点是连接空洞区域与主网络的"桥接点"
%
% 输入:
%   adj_matrix - 邻接矩阵 (T x T)
%   components - 连通分量cell数组
%   main_idx - 主连通分量的索引
%   pos_matrix - 卫星位置矩阵 (T x 3, [经度, 纬度, 高度])（可选）
%
% 输出:
%   boundary_density - 边界节点密度 = 边界节点数 / 空洞总节点数
%   boundary_nodes - 边界节点的索引数组
%
% 作者: 基于创新点一要求设计
% 日期: 2026-03-30

    T = size(adj_matrix, 1);
    
    %% 获取主连通分量和非主连通分量的节点
    main_nodes = components{main_idx}; % 主连通分量节点
    non_main_nodes = []; % 非主连通分量节点
    
    for c = 1:length(components)
        if c ~= main_idx
            non_main_nodes = [non_main_nodes, components{c}];
        end
    end
    
    if isempty(non_main_nodes)
        boundary_density = 0;
        boundary_nodes = [];
        return;
    end
    
    %% 找出边界节点
    % 边界节点定义：属于非主分量，但有邻居在主分量中
    boundary_nodes = [];
    
    for node = non_main_nodes
        neighbors = find(adj_matrix(node, :) > 0);
        % 检查是否有邻居在主连通分量中
        if any(ismember(neighbors, main_nodes))
            boundary_nodes = [boundary_nodes, node];
        end
    end
    
    %% 计算边界节点密度
    % 边界密度 = 边界节点数 / 空洞区域总节点数
    void_size = length(non_main_nodes);
    if void_size > 0
        boundary_density = length(boundary_nodes) / void_size;
    else
        boundary_density = 0;
    end
    
    %% 额外分析：如果提供位置信息，计算边界的地理分布
    if nargin >= 4 && ~isempty(pos_matrix) && length(boundary_nodes) > 0
        % 边界节点的地理中心
        boundary_pos = pos_matrix(boundary_nodes, :);
        boundary_center = mean(boundary_pos, 1);
        
        % 边界节点到主连通分量中心的方向（判断空洞相对于主网络的方向）
        main_pos = pos_matrix(main_nodes, :);
        main_center = mean(main_pos, 1);
        
        % 计算边界节点的经度/纬度分布范围
        boundary_lon_range = [min(boundary_pos(:,1)), max(boundary_pos(:,1))];
        boundary_lat_range = [min(boundary_pos(:,2)), max(boundary_pos(:,2))];
        
        % 存储地理分析结果（可选输出）
        % 这些信息可以用于后续的地理可视化
    end
    
    %% 另一种边界定义：仅考虑空洞区域内部的"切割边界"
    % 这种边界是空洞区域内部，将空洞分割成更小区域的"喉管"
    % 对于复杂形状的空洞区域，这可能更有意义
    
    % 检测内部边界（两个非主分量之间的连接节点）
    internal_boundary_nodes = [];
    for c1 = 1:length(components)
        if c1 == main_idx, continue; end
        for c2 = c1+1:length(components)
            if c2 == main_idx, continue; end
            % 查找同时连接这两个分量的节点
            comp1_nodes = components{c1};
            comp2_nodes = components{c2};
            for node = [comp1_nodes, comp2_nodes]
                neighbors = find(adj_matrix(node, :) > 0);
                has_in_c1 = any(ismember(neighbors, comp1_nodes));
                has_in_c2 = any(ismember(neighbors, comp2_nodes));
                if has_in_c1 && has_in_c2
                    internal_boundary_nodes = [internal_boundary_nodes, node];
                end
            end
        end
    end
    
    % 返回结构体（包含额外的分析结果）
    if nargout == 1
        boundary_density = struct(...
            'boundary_density', boundary_density, ...
            'boundary_count', length(boundary_nodes), ...
            'void_size', void_size, ...
            'internal_boundary_count', length(internal_boundary_nodes));
    end
end