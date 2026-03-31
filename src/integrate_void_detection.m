function [void_metrics_over_time] = integrate_void_detection(data_path, result_path, varargin)
% integrate_void_detection - 将拓扑空洞检测集成到现有仿真流程
%
% 此函数读取已有的仿真数据，对每个时间点进行空洞检测，
% 并输出空洞指标的时间序列
%
% 输入:
%   data_path - 预处理数据路径 (e.g., 'processed_data.mat')
%   result_path - 结果保存路径 (e.g., 'void_detection_results.mat')
%   varargin - 可选参数:
%     'time_indices' - 要检测的时间点索引 (默认: 所有)
%     'monte_carlo_runs' - 蒙特卡洛次数 (默认: 1000)
%
% 输出:
%   void_metrics_over_time - 包含所有时间点空洞指标的结构体
%
% 使用方法:
%   >> void_results = integrate_void_detection('processed_data.mat', 'void_results.mat');
%
% 日期: 2026-03-30

    %% 解析参数
    p = inputParser;
    addOptional(p, 'time_indices', [], @isnumeric);
    addOptional(p, 'monte_carlo_runs', 1000, @isnumeric);
    parse(p, varargin{:});
    opts = p.Results;
    
    %% 加载数据
    fprintf('加载数据...\n');
    load(data_path, 'T', 'P', 'S', 'sat_positions', 'sat_lat_lon', ...
        'time_data', 'sunUnitVector', 'num_time_points');
    
    %% 确定要处理的时间点
    if isempty(opts.time_indices)
        time_indices = 1:min(num_time_points, 100); % 默认最多处理100个时间点
    else
        time_indices = opts.time_indices;
    end
    
    fprintf('将处理 %d 个时间点\n', length(time_indices));
    
    %% 预分配结果存储
    n_times = length(time_indices);
    void_metrics_over_time = struct();
    
    % 每个时间点的指标
    void_metrics_over_time.connectivity_rate = zeros(n_times, 1);
    void_metrics_over_time.num_components = zeros(n_times, 1);
    void_metrics_over_time.isolated_rate = zeros(n_times, 1);
    void_metrics_over_time.void_area_index = zeros(n_times, 1);
    void_metrics_over_time.algebraic_connectivity = zeros(n_times, 1);
    void_metrics_over_time.severity_index = zeros(n_times, 1);
    void_metrics_over_time.component_entropy = zeros(n_times, 1);
    
    % 平均值和标准差（跨蒙特卡洛）
    mc_runs = opts.monte_carlo_runs;
    
    % 对于每个时间点进行检测
    for t_idx = 1:n_times
        time_point = time_indices(t_idx);
        
        if mod(t_idx, 10) == 0
            fprintf('处理时间点 %d/%d...\n', t_idx, n_times);
        end
        
        % 获取该时间点的位置数据
        pos_at_time = sat_positions(time_point, :, :);
        pos_matrix = squeeze(pos_at_time); % (T x 3)
        
        % 获取太阳矢量
        sun_vec = sunUnitVector(time_point, :);
        
        %% 这里需要调用你的拓扑构建函数
        % 由于不知道你的具体实现，假设你需要根据位置和太阳矢量构建邻接矩阵
        % 示例（需要根据你的实际代码调整）：
        % adj_matrix = build_topology_with_environmental_effects(pos_matrix, sun_vec, T, P, S);
        
        % 暂时使用模拟邻接矩阵进行测试
        % TODO: 替换为真实的拓扑构建
        adj_matrix = build_mock_topology(pos_matrix, T, P);
        
        %% 检测拓扑空洞
        [void_info, components, component_sizes] = detect_topological_void(adj_matrix, T);
        
        %% 计算严重程度
        severity = calculate_void_severity_index(void_info);
        
        %% 存储结果
        void_metrics_over_time.connectivity_rate(t_idx) = void_info.connectivity_rate;
        void_metrics_over_time.num_components(t_idx) = void_info.num_components;
        void_metrics_over_time.isolated_rate(t_idx) = void_info.isolated_rate;
        void_metrics_over_time.void_area_index(t_idx) = void_info.void_area_index;
        void_metrics_over_time.algebraic_connectivity(t_idx) = void_info.algebraic_connectivity;
        void_metrics_over_time.severity_index(t_idx) = severity.composite_score;
        void_metrics_over_time.component_entropy(t_idx) = void_info.component_entropy;
        void_metrics_over_time.time_data(t_idx) = time_data(time_point);
    end
    
    %% 计算统计指标
    fprintf('计算统计指标...\n');
    
    void_metrics_over_time.mean_connectivity_rate = mean(void_metrics_over_time.connectivity_rate);
    void_metrics_over_time.std_connectivity_rate = std(void_metrics_over_time.connectivity_rate);
    
    void_metrics_over_time.mean_void_area = mean(void_metrics_over_time.void_area_index);
    void_metrics_over_time.std_void_area = std(void_metrics_over_time.void_area_index);
    
    void_metrics_over_time.mean_severity = mean(void_metrics_over_time.severity_index);
    void_metrics_over_time.std_severity = std(void_metrics_over_time.severity_index);
    
    void_metrics_over_time.max_severity = max(void_metrics_over_time.severity_index);
    void_metrics_over_time.min_severity = min(void_metrics_over_time.severity_index);
    
    %% 可视化结果
    plot_void_metrics_over_time(void_metrics_over_time, time_indices);
    
    %% 保存结果
    fprintf('保存结果到: %s\n', result_path);
    save(result_path, 'void_metrics_over_time', 'time_indices', 'opts');
    
    fprintf('\n=== 空洞检测完成 ===\n');
    fprintf('平均连通率: %.4f ± %.4f\n', ...
        void_metrics_over_time.mean_connectivity_rate, ...
        void_metrics_over_time.std_connectivity_rate);
    fprintf('平均空洞面积指数: %.4f ± %.4f\n', ...
        void_metrics_over_time.mean_void_area, ...
        void_metrics_over_time.std_void_area);
    fprintf('平均严重程度: %.4f ± %.4f\n', ...
        void_metrics_over_time.mean_severity, ...
        void_metrics_over_time.std_severity);
end

%% 辅助函数：绘制空洞指标时间序列
function plot_void_metrics_over_time(void_metrics, time_indices)
    figure('Position', [100, 100, 1400, 800], 'Name', '空洞指标时间序列');
    
    t = 1:length(time_indices);
    
    subplot(2, 3, 1);
    plot(t, void_metrics.connectivity_rate, 'b-', 'LineWidth', 1.5);
    ylabel('连通率 Rc');
    xlabel('时间点');
    title('连通率随时间变化');
    grid on;
    
    subplot(2, 3, 2);
    plot(t, void_metrics.num_components, 'r-', 'LineWidth', 1.5);
    ylabel('连通分量数 Nc');
    xlabel('时间点');
    title('连通分量数随时间变化');
    grid on;
    
    subplot(2, 3, 3);
    plot(t, void_metrics.void_area_index, 'g-', 'LineWidth', 1.5);
    ylabel('空洞面积指数 Av');
    xlabel('时间点');
    title('空洞面积指数随时间变化');
    grid on;
    
    subplot(2, 3, 4);
    plot(t, void_metrics.isolated_rate, 'm-', 'LineWidth', 1.5);
    ylabel('孤立节点率 Ri');
    xlabel('时间点');
    title('孤立节点率随时间变化');
    grid on;
    
    subplot(2, 3, 5);
    plot(t, void_metrics.algebraic_connectivity, 'c-', 'LineWidth', 1.5);
    ylabel('代数连通度 \lambda_2');
    xlabel('时间点');
    title('代数连通度随时间变化');
    grid on;
    
    subplot(2, 3, 6);
    plot(t, void_metrics.severity_index, 'k-', 'LineWidth', 1.5);
    ylabel('严重程度指数');
    xlabel('时间点');
    title('空洞严重程度随时间变化');
    grid on;
    
    sgtitle('拓扑空洞指标时间序列分析');
end

%% 辅助函数：构建模拟拓扑（测试用）
function adj_matrix = build_mock_topology(pos_matrix, T, P)
    % 这是一个简化的模拟拓扑构建
    % 实际使用时替换为真实的建链逻辑
    
    S = T / P;
    adj_matrix = zeros(T);
    
    % 同轨建链
    for p = 0:P-1
        for s = 0:S-1
            node_idx = p * S + s + 1;
            next_s = mod(s + 1, S);
            next_node = p * S + next_s + 1;
            adj_matrix(node_idx, next_node) = 1;
            adj_matrix(next_node, node_idx) = 1;
        end
    end
    
    % 异轨建链
    U = 5;
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
end