function [void_info, components, component_sizes] = detect_topological_void(adj_matrix, T, pos_matrix)
% detect_topological_void - 拓扑空洞检测与量化评估函数
%
% 输入:
%   adj_matrix - 邻接矩阵 (T x T)，有权图时为距离，无权图时为0/1
%   T - 卫星总数（可选，默认从adj_matrix推断）
%   pos_matrix - 卫星位置矩阵 (T x 3, [经度, 纬度, 高度])（可选，用于地理可视化）
%
% 输出:
%   void_info - 包含所有量化指标的结构体
%   components - 连通分量cell数组，每个cell包含一个分量的节点索引
%   component_sizes - 每个连通分量的大小
%
% 量化指标包含:
%   - connectivity_rate (Rc): 连通率，主连通分量节点数/总节点数
%   - num_components (Nc): 连通分量数量
%   - isolated_nodes: 孤立节点数量
%   - isolated_rate (Ri): 孤立节点率
%   - void_area_index (Av): 空洞面积指数 = 1 - Rc
%   - component_entropy (Hc): 连通分量分布熵
%   - algebraic_connectivity (lambda2): 代数连通度（Laplacian矩阵第二小特征值）
%   - natural_connectivity: 自然连通度（特征根几何平均）
%   - diameter_degradation: 直径退化率（如果有基准数据）
%   - severity_index: 空洞严重程度综合指数
%
% 作者: 基于创新点一要求设计
% 日期: 2026-03-30

    %% 输入参数处理
    if nargin < 2 || isempty(T)
        T = size(adj_matrix, 1);
    end
    if nargin < 3
        pos_matrix = [];
    end
    
    %% Step 1: 连通分量分析（BFS）
    visited = false(T, 1);
    components = cell(0);
    component_sizes = [];
    
    for v = 1:T
        if ~visited(v)
            % BFS遍历找到该连通分量
            [component, visited] = bfs_component(adj_matrix, v, visited);
            components{end+1} = component;
            component_sizes(end+1) = length(component);
        end
    end
    
    % 按大小降序排序
    [component_sizes, sort_idx] = sort(component_sizes, 'descend');
    components = components(sort_idx);
    
    % 主连通分量（最大连通分量）
    [max_size, main_idx] = max(component_sizes);
    
    %% Step 2: 连通性指标计算
    void_info.connectivity_rate = max_size / T;           % Rc
    void_info.num_components = length(components);       % Nc
    void_info.isolated_nodes = sum(component_sizes == 1); % 孤立节点数
    void_info.isolated_rate = void_info.isolated_nodes / T; % Ri
    void_info.void_area_index = 1 - void_info.connectivity_rate; % Av
    void_info.main_component_size = max_size;
    void_info.main_component_ratio = max_size / T;
    
    %% Step 3: 连通分量分布熵 (类似基尼系数思想)
    sizes_norm = component_sizes / T;
    sizes_norm = sizes_norm(sizes_norm > 0);
    void_info.component_entropy = -sum(sizes_norm .* log(sizes_norm + eps)); % Hc
    % 归一化熵（0=完全集中，1=完全均匀分布）
    void_info.normalized_entropy = void_info.component_entropy / log(length(components) + eps);
    
    %% Step 4: 连通分量不均衡度（ Simpson Index）
    void_info.simpson_index = sum(sizes_norm .^ 2); % D = sum(pi^2)
    % 0表示完全均衡（无穷多小分量），1表示完全集中（单一分量）
    
    %% Step 5: 谱指标计算（Laplacian矩阵）
    % 构建度矩阵和Laplacian矩阵
    D = diag(sum(adj_matrix > 0, 2)); % 度矩阵
    L = D - adj_matrix; % Laplacian矩阵（无权）
    
    % 计算特征值
    lambda = eig(L);
    lambda = sort(lambda); % 升序排列
    
    % 代数连通度：第二小特征值，衡量"cut"网络的难度
    % lambda_2 = 0 表示图不连通
    void_info.algebraic_connectivity = lambda(2); % lambda_2
    
    % 自然连通度：特征根的几何平均，物理意义是网络冗余路径的度量
    lambda_nonzero = lambda(lambda > 1e-10); % 排除0特征值
    if ~isempty(lambda_nonzero)
        void_info.natural_connectivity = exp(mean(log(lambda_nonzero)));
    else
        void_info.natural_connectivity = 0;
    end
    
    % 谱半径（最大特征值）
    void_info.spectral_radius = lambda(end);
    
    % 谱隙（spectral gap）：lambda_2 / lambda_n
    void_info.spectral_gap = lambda(2) / (lambda(end) + eps);
    
    %% Step 6: 几何中心分析（如果提供位置信息）
    if ~isempty(pos_matrix) && size(pos_matrix, 1) >= T
        % 计算主连通分量的几何中心
        main_nodes = components{main_idx};
        main_pos = pos_matrix(main_nodes, :);
        void_info.main_component_center = mean(main_pos, 1);
        
        % 计算非主连通分量的节点
        non_main_nodes = [];
        for c = 1:length(components)
            if c ~= main_idx
                non_main_nodes = [non_main_nodes, components{c}];
            end
        end
        
        if ~isempty(non_main_nodes)
            non_main_pos = pos_matrix(non_main_nodes, :);
            void_info.void_centers = mean(non_main_pos, 1);
            void_info.void_spread = std(non_main_pos, 0, 1); % 空洞区域离散程度
        else
            void_info.void_centers = [];
            void_info.void_spread = [];
        end
        
        % 计算各连通分量的地理范围（经纬度跨度）
        void_info.component_spans = zeros(length(components), 2); % [lon_span, lat_span]
        for c = 1:length(components)
            comp_pos = pos_matrix(components{c}, :);
            lon_span = max(comp_pos(:,1)) - min(comp_pos(:,1));
            lat_span = max(comp_pos(:,2)) - min(comp_pos(:,2));
            void_info.component_spans(c, :) = [lon_span, lat_span];
        end
    end
    
    %% Step 7: 空洞类型判断
    % 判断是否存在孤立节点空洞
    void_info.has_isolated_void = void_info.isolated_nodes > 0;
    
    % 判断是否存在区域碎片空洞（多个小分量）
    void_info.has_fragmentation_void = (void_info.num_components > 1) && (max_size < T * 0.95);
    
    % 判断是否存在路径断裂空洞（需要比较失效前后的直径或跳数）
    % 这个指标需要在调用时传入基准数据
    void_info.has_path_disconnection_void = false; % 默认值，会在后续计算中更新
    
    %% Step 8: 空洞严重程度综合指数
    % 设计一个综合多个指标的评分，取值范围0~1，越大空洞越严重
    % 权重可以根据具体场景调整
    w1 = 0.35; % 连通率权重
    w2 = 0.25; % 孤立节点率权重
    w3 = 0.25; % 连通分量数权重（归一化）
    w4 = 0.15; % 代数连通度退化权重
    
    % 归一化各指标到0~1
    norm_connectivity = 1 - void_info.connectivity_rate; % 0=无空洞，1=完全失效
    norm_isolated = void_info.isolated_rate;
    norm_components = min((void_info.num_components - 1) / max(T-1, 1), 1); % 归一化
    norm_lambda = 1 - min(void_info.algebraic_connectivity / max(max(eig(D)), 1), 1); % 归一化
    
    void_info.severity_index = w1 * norm_connectivity + ...
                                w2 * norm_isolated + ...
                                w3 * norm_components + ...
                                w4 * norm_lambda;
    
    % 确保在[0,1]范围内
    void_info.severity_index = max(0, min(1, void_info.severity_index));
    
    %% Step 9: 输出摘要
    void_info.summary = sprintf(...
        'Rc=%.4f, Nc=%d, Av=%.4f, Ri=%.4f, lambda2=%.4f, Hc=%.4f, Sev=%.4f', ...
        void_info.connectivity_rate, void_info.num_components, void_info.void_area_index, ...
        void_info.isolated_rate, void_info.algebraic_connectivity, ...
        void_info.component_entropy, void_info.severity_index);
    
end

%% 辅助函数：BFS遍历找到连通分量
function [component, visited] = bfs_component(adj_matrix, start_node, visited)
    % BFS遍历，返回一个连通分量的所有节点
    queue = start_node;
    component = [];
    
    while ~isempty(queue)
        node = queue(1);
        queue(1) = []; % 出队
        component(end+1) = node;
        
        % 找到当前节点的所有邻居
        neighbors = find(adj_matrix(node, :) > 0);
        for n = neighbors(:)' % 转置确保行向量
            if ~visited(n)
                visited(n) = true;
                queue(end+1) = n; % 入队
            end
        end
    end
end