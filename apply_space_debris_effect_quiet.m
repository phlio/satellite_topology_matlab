function updated_graph = apply_space_debris_effect_quiet(graph_matrix, debris_probability)
% 应用空间碎片效应对卫星拓扑的影响（静默版本，无输出信息）
% 空间碎片导致所有卫星节点以固定概率失效
%
% 输入:
%   graph_matrix - 卫星连接关系的对称矩阵 (T x T)
%   debris_probability - 空间碎片导致节点失效的概率，默认0.002
%
% 输出:
%   updated_graph - 应用空间碎片效应后的更新连接矩阵
    
    % 获取卫星总数
    T = size(graph_matrix, 1);
    
    % 创建更新后的图矩阵副本
    updated_graph = graph_matrix;
    
    % 处理卫星节点失效（断开受影响卫星的所有链路）
    affected_satellites = false(T, 1);
    
    % 对所有卫星应用空间碎片效应（节点失效）
    rand_vals = rand(T, 1);
    affected_satellites = rand_vals < debris_probability;
    
    % 断开受影响卫星的所有链路
    for i = 1:T
        if affected_satellites(i)
            updated_graph(i, :) = 0;
            updated_graph(:, i) = 0;
        end
    end
end