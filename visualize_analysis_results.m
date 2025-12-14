function visualize_analysis_results(time_data, avg_hops, diameter, variability)
% 可视化分析结果

    figure('Position', [100, 100, 1200, 800], 'Name', '网络性能分析');
    
    subplot(2,2,1);
    plot(time_data, avg_hops, 'b-', 'LineWidth', 2);
    xlabel('时间 (秒)'); ylabel('平均路径跳数');
    title('平均路径跳数时间序列'); grid on;
    
    subplot(2,2,2);
    plot(time_data, diameter, 'r-', 'LineWidth', 2);
    xlabel('时间 (秒)'); ylabel('网络直径');
    title('网络直径时间序列'); grid on;
    
    subplot(2,2,3);
    plot(time_data(2:end), variability(2:end), 'g-', 'LineWidth', 2);
    xlabel('时间 (秒)'); ylabel('拓扑变化率');
    title('拓扑动态性分析'); grid on;
    
    subplot(2,2,4);
    scatter(avg_hops, diameter, 50, 'filled');
    xlabel('平均路径跳数'); ylabel('网络直径');
    title('跳数与直径关系'); grid on;
    
    % 添加统计信息
    info_str = sprintf(['统计信息:\n' ...
                       '平均跳数: %.3f ± %.3f\n' ...
                       '网络直径: %.1f ± %.1f\n' ...
                       '平均变化率: %.4f'], ...
                       mean(avg_hops), std(avg_hops), ...
                       mean(diameter), std(diameter), ...
                       mean(variability(variability>0)));
    
    annotation('textbox', [0.02, 0.02, 0.25, 0.15], ...
               'String', info_str, 'FontSize', 10, ...
               'BackgroundColor', 'white', 'EdgeColor', 'black');
end