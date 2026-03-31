function plot_high_risk_performance_results(valid_u_values, avg_hops_before_all, avg_hops_after_all, avg_hops_reconnected_all, ...
    improvement_rates_all, relative_improvement, high_risk_links_before_all, high_risk_links_after_all, high_risk_links_reconnected_all, time_point_idx, num_simulations)
% 绘制高风险区域性能对比分析结果
% 输入参数：
%   valid_u_values - 有效的U值
%   avg_hops_before_all - 断链前平均路径跳数
%   avg_hops_after_all - 断链后平均路径跳数  
%   avg_hops_reconnected_all - 重建链后平均路径跳数
%   improvement_rates_all - 提升率
%   relative_improvement - 相对改善率
%   high_risk_links_before_all - 断链前高风险区域链路数量
%   high_risk_links_after_all - 断链后高风险区域链路数量
%   high_risk_links_reconnected_all - 重建链后高风险区域链路数量
%   time_point_idx - 时间点索引
%   num_simulations - 蒙特卡洛模拟次数

figure('Name', '高风险区域性能对比分析（蒙特卡洛模拟）', 'Position', [100, 100, 1200, 800]);

% 计算y轴的最大值，为标签留出空间
all_hops_values = [avg_hops_before_all, avg_hops_after_all, avg_hops_reconnected_all];
y_max_hops = max(all_hops_values);
y_axis_padding_hops = y_max_hops * 0.4;
y_axis_limit_hops = y_max_hops + y_axis_padding_hops;

% 计算链路数量的最大值
all_links_values = [high_risk_links_before_all, high_risk_links_after_all, high_risk_links_reconnected_all];
y_max_links = max(all_links_values);
y_axis_padding_links = y_max_links * 0.15;
y_axis_limit_links = y_max_links + y_axis_padding_links;

% 创建子图布局
subplot(2, 2, 1);
% 平均路径跳数对比
bar_width = 0.25;
x = 1:length(valid_u_values);
bar(x - bar_width, avg_hops_before_all, bar_width, 'FaceColor', [0.2, 0.6, 0.8], 'EdgeColor', 'k');
hold on;
bar(x, avg_hops_after_all, bar_width, 'FaceColor', [0.8, 0.2, 0.2], 'EdgeColor', 'k');
bar(x + bar_width, avg_hops_reconnected_all, bar_width, 'FaceColor', [0.2, 0.8, 0.2], 'EdgeColor', 'k');
hold off;

% 添加数值标签
for i = 1:length(valid_u_values)
    text(x(i) - bar_width, avg_hops_before_all(i) + 0.05, sprintf('%.2f', avg_hops_before_all(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
    text(x(i), avg_hops_after_all(i) + 0.05, sprintf('%.2f', avg_hops_after_all(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
    text(x(i) + bar_width, avg_hops_reconnected_all(i) + 0.05, sprintf('%.2f', avg_hops_reconnected_all(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
end

xlabel('U值 (sum\_mod)');
ylabel('平均路径跳数');
title('断链前后及重建链后的平均路径跳数对比');
xticks(x);
xticklabels(arrayfun(@(x) sprintf('U=%d', x), valid_u_values, 'UniformOutput', false));
legend('断链前', '断链后', '重建链后', 'Location', 'northwest');
grid on;
ylim([0, y_axis_limit_hops]);

% 提升率对比
subplot(2, 2, 2);
bar(valid_u_values, improvement_rates_all, 'FaceColor', [0.6, 0.4, 0.8], 'EdgeColor', 'k');
hold on;
for i = 1:length(valid_u_values)
    text(valid_u_values(i), improvement_rates_all(i) + 1, sprintf('%.1f%%', improvement_rates_all(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
end
hold off;
xlabel('U值 (sum\_mod)');
ylabel('提升率 (%)');
title('重建链相对于断链后的平均路径跳数提升率');
grid on;
% 为提升率图也添加顶部空间
if ~isempty(improvement_rates_all)
    max_improvement = max(improvement_rates_all);
    ylim([0, max_improvement * 1.2]);
end

% 链路数量变化趋势（只显示链路数量）
subplot(2, 2, 3);
plot(valid_u_values, high_risk_links_before_all, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.3, 0.7, 0.3]);
hold on;
plot(valid_u_values, high_risk_links_after_all, 's-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.9, 0.3, 0.3]);
plot(valid_u_values, high_risk_links_reconnected_all, 'd-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.3, 0.9, 0.3]);
hold off;
xlabel('U值 (sum\_mod)');
ylabel('高风险区域链路数量');
title('不同U值下的高风险区域链路数量变化趋势');
legend('断链前', '断链后', '重建链后', 'Location', 'best');
grid on;
ylim([0, y_axis_limit_links]);

% 相对性能改善
subplot(2, 2, 4);
bar(valid_u_values, relative_improvement, 'FaceColor', [0.9, 0.6, 0.1], 'EdgeColor', 'k');
hold on;
for i = 1:length(valid_u_values)
    text(valid_u_values(i), relative_improvement(i) + 1, sprintf('%.1f%%', relative_improvement(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
end
hold off;
xlabel('U值 (sum\_mod)');
ylabel('提升率 (%)');
title('重建链相对于断链前的相对平均路径跳数提升率');
grid on;
% 为相对改善率图添加顶部空间
if ~isempty(relative_improvement)
    max_relative = max(relative_improvement);
    ylim([0, max_relative * 1.2]);
end

sgtitle(sprintf('高风险区域性能对比分析 - 时间点 %d (%d次蒙特卡洛模拟)', time_point_idx, num_simulations));
end