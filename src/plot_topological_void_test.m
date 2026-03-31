function plot_topological_void_test()
% plot_topological_void_test - 测试拓扑空洞可视化功能
%
% 在MATLAB中运行此函数查看可视化效果

    close all;
    T = 60; P = 6; S = 10;
    
    %% 加载真实数据（如果存在）
    if exist('processed_data.mat', 'file')
        load('processed_data.mat');
        fprintf('已加载仿真数据\n');
        
        % 选择一个时间点
        time_idx = 240; % 任意选择
        
        % 使用sat_positions构建简化拓扑
        % 这里需要结合你的建链逻辑
        % 暂时使用随机邻接矩阵演示
        
        % 构建一个示例邻接矩阵（模拟有空洞的情况）
        adj_matrix = build_example_topology_with_void(T, P);
        
        % 模拟失效节点
        failed_nodes = [5, 12, 23, 45]; % 示例失效节点
        
    else
        % 使用模拟数据
        fprintf('未找到processed_data.mat，使用模拟数据\n');
        adj_matrix = build_example_topology_with_void(T, P);
        failed_nodes = [5, 12, 23, 45];
    end
    
    %% 检测拓扑空洞
    [void_info, components, component_sizes] = detect_topological_void(adj_matrix, T);
    
    %% 计算严重程度
    severity = calculate_void_severity_index(void_info);
    
    %% 生成位置矩阵（模拟数据）
    % 实际使用时从sat_lat_lon读取
    pos_matrix = generate_mock_positions(T, P);
    
    %% 调用可视化函数
    h = plot_topological_void(pos_matrix, adj_matrix, failed_nodes, ...
        components, component_sizes, severity, T, P, ...
        'title', '拓扑空洞检测与可视化测试', ...
        'show_saa', true, ...
        'show_orbits', true);
    
    %% 同时显示严重程度详情
    fprintf('\n=== 拓扑空洞检测结果 ===\n');
    fprintf('连通率 Rc = %.4f\n', void_info.connectivity_rate);
    fprintf('连通分量数 Nc = %d\n', void_info.num_components);
    fprintf('孤立节点数 = %d\n', void_info.isolated_nodes);
    fprintf('空洞面积指数 Av = %.4f\n', void_info.void_area_index);
    fprintf('代数连通度 = %.4f\n', void_info.algebraic_connectivity);
    fprintf('自然连通度 = %.4f\n', void_info.natural_connectivity);
    fprintf('\n严重程度评估:\n');
    fprintf('  综合评分 = %.4f\n', severity.composite_score);
    fprintf('  等级 = %s\n', severity.grade);
end

%% 辅助函数：生成示例拓扑（带空洞）
function adj_matrix = build_example_topology_with_void(T, P)
    % 创建一个带有空洞的示例拓扑
    % 主连通分量：大部分节点
    % 空洞区域：少数节点断开或形成小分量
    
    S = T / P; % 每轨道面卫星数
    
    adj_matrix = zeros(T);
    
    % 同轨建链（每个轨道面内）
    for p = 0:P-1
        for s = 0:S-1
            node_idx = p * S + s + 1;
            % 连接同轨邻居
            next_s = mod(s + 1, S);
            next_node = p * S + next_s + 1;
            adj_matrix(node_idx, next_node) = 1;
            adj_matrix(next_node, node_idx) = 1;
        end
    end
    
    % 异轨建链（使用固定的U值）
    U = 5; % 示例U值
    for s = 0:S-1
        for p = 0:P-1
            node1 = p * S + s + 1;
            p2 = mod(p + 1, P);
            s2 = mod(s + U, S);
            node2 = p2 * S + s2 + 1;
            adj_matrix(node1, node2) = 1;
            adj_matrix(node2, node1) = 1;
        end
    end
    
    % 模拟空洞：断开几个节点（设为孤立）
    void_nodes = [5, 12, 23, 45]; % 这些节点变成孤立
    for v = void_nodes
        adj_matrix(v, :) = 0;
        adj_matrix(:, v) = 0;
    end
    
    % 再断开几个链路（模拟区域碎片）
    adj_matrix(3, 8) = 0;
    adj_matrix(8, 3) = 0;
    adj_matrix(15, 25) = 0;
    adj_matrix(25, 15) = 0;
end

%% 辅助函数：生成模拟位置
function pos_matrix = generate_mock_positions(T, P)
    % 生成模拟的卫星位置（经纬度）
    % 实际使用时从sat_lat_lon读取
    
    S = T / P;
    pos_matrix = zeros(T, 3); % [经度, 纬度, 高度]
    
    Re = 6378.14; % 地球半径 km
    h = 1000; % 轨道高度 km
    R = Re + h;
    
    for p = 0:P-1
        % 轨道面经度
        plane_lon = p * (360 / P);
        for s = 0:S-1
            % 卫星在轨道内的相位
            phase = s * (360 / S);
            node_idx = p * S + s + 1;
            
            pos_matrix(node_idx, 1) = mod(plane_lon + phase, 360) - 180; % 经度
            pos_matrix(node_idx, 2) = 0; % 纬度（简化，赤道星座）
            pos_matrix(node_idx, 3) = h; % 高度
        end
    end
end