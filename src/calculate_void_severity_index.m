function [severity_info] = calculate_void_severity_index(void_info, baseline_info, weights)
% calculate_void_severity_index - 计算拓扑空洞严重程度综合指数
%
% 将多个量化指标整合为一个综合评分，便于论文中的横向对比和时序分析
%
% 输入:
%   void_info - detect_topological_void返回的指标结构体
%   baseline_info - 失效前的基准指标结构体（可选，用于计算退化率）
%   weights - 权重向量 [w_connectivity, w_isolated, w_components, w_lambda]
%             默认 [0.35, 0.25, 0.25, 0.15]
%
% 输出:
%   severity_info - 包含综合评分和详细分解的结构体
%
% 作者: 基于创新点一要求设计
% 日期: 2026-03-30

    %% 默认权重
    if nargin < 3 || isempty(weights)
        weights = [0.35, 0.25, 0.25, 0.15];
    end
    
    %% 提取关键指标
    Rc = void_info.connectivity_rate;
    Ri = void_info.isolated_rate;
    Nc = void_info.num_components;
    Av = void_info.void_area_index;
    lambda2 = void_info.algebraic_connectivity;
    Hc = void_info.component_entropy;
    
    % 获取总节点数（从component_sizes推断）
    if isfield(void_info, 'main_component_size')
        total_nodes = void_info.main_component_size;
        for c = 1:length(void_info.component_sizes)
            if c ~= find(void_info.component_sizes == void_info.main_component_size, 1)
                total_nodes = total_nodes + void_info.component_sizes{c};
            end
        end
    else
        total_nodes = sum(void_info.component_sizes);
    end
    
    %% 归一化各指标到0~1范围
    % 指标1: 连通率缺失度 (0=无缺失, 1=完全缺失)
    norm_connectivity = 1 - Rc;
    
    % 指标2: 孤立节点率 (0=无孤立, 1=全部孤立)
    norm_isolated = Ri;
    
    % 指标3: 连通分量数归一化 (Nc=1时为0, Nc=T时为1)
    norm_components = min((Nc - 1) / max(total_nodes - 1, 1), 1);
    
    % 指标4: 代数连通度归一化
    max_possible_lambda2 = max(sum(void_info.component_sizes > 0));
    norm_lambda = 1 - min(lambda2 / max(max_possible_lambda2, 1), 1);
    
    % 指标5: 空洞面积指数（已经是0~1）
    norm_area = Av;
    
    % 指标6: 熵归一化
    max_entropy = log(Nc);
    norm_entropy = Hc / max(max_entropy, 1);
    
    %% 计算加权综合指数
    severity_info.raw_score = weights(1) * norm_connectivity + ...
                              weights(2) * norm_isolated + ...
                              weights(3) * norm_components + ...
                              weights(4) * norm_lambda;
    
    severity_info.void_area_score = norm_area;
    severity_info.entropy_score = norm_entropy;
    
    severity_info.composite_score = 0.6 * severity_info.raw_score + ...
                                   0.25 * norm_area + ...
                                   0.15 * norm_entropy;
    
    severity_info.composite_score = max(0, min(1, severity_info.composite_score));
    severity_info.raw_score = max(0, min(1, severity_info.raw_score));
    
    %% 基准退化计算
    if nargin >= 2 && ~isempty(baseline_info)
        severity_info.connectivity_degradation = (baseline_info.connectivity_rate - Rc) / baseline_info.connectivity_rate;
        severity_info.lambda2_degradation = (baseline_info.algebraic_connectivity - lambda2) / max(baseline_info.algebraic_connectivity, 1e-10);
        severity_info.diameter_degradation = 0;
        severity_info.degradation_based_score = ...
            0.4 * max(0, severity_info.connectivity_degradation) + ...
            0.3 * max(0, severity_info.lambda2_degradation);
    else
        severity_info.connectivity_degradation = 0;
        severity_info.lambda2_degradation = 0;
        severity_info.diameter_degradation = 0;
        severity_info.degradation_based_score = 0;
    end
    
    %% 空洞等级划分
    if severity_info.composite_score < 0.1
        severity_info.grade = '无空洞 (None)';
        severity_info.grade_code = 0;
    elseif severity_info.composite_score < 0.3
        severity_info.grade = '轻微空洞 (Minor)';
        severity_info.grade_code = 1;
    elseif severity_info.composite_score < 0.5
        severity_info.grade = '中等空洞 (Moderate)';
        severity_info.grade_code = 2;
    elseif severity_info.composite_score < 0.7
        severity_info.grade = '严重空洞 (Severe)';
        severity_info.grade_code = 3;
    else
        severity_info.grade = '极度严重空洞 (Critical)';
        severity_info.grade_code = 4;
    end
    
    severity_info.details = struct(...
        'norm_connectivity', norm_connectivity, ...
        'norm_isolated', norm_isolated, ...
        'norm_components', norm_components, ...
        'norm_lambda', norm_lambda, ...
        'norm_area', norm_area, ...
        'norm_entropy', norm_entropy, ...
        'weights_used', weights);
    
    %% 打印摘要
    fprintf('拓扑空洞严重程度评估:\n');
    fprintf('  综合评分: %.4f\n', severity_info.composite_score);
    fprintf('  空洞等级: %s\n', severity_info.grade);
    fprintf('  连通率缺失: %.2f%%\n', norm_connectivity * 100);
    fprintf('  孤立节点率: %.2f%%\n', norm_isolated * 100);
    fprintf('  连通分量数: %d\n', Nc);
    fprintf('  空洞面积指数: %.4f\n', Av);
    fprintf('\n');
end