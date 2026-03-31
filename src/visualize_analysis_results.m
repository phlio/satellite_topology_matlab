function visualize_analysis_results(time_data, avg_hops, diameter, variability)
% 可视化分析结果 - 四个独立图形窗口
% 输入参数：
%   time_data   - 时间序列数据（秒）
%   avg_hops    - 各时间点的平均路径跳数
%   diameter    - 各时间点的网络直径
%   variability - 各时间点的拓扑变化率

    %% ========== 第一个图：平均路径跳数时间序列 ==========
    figure('Position', [100, 100, 800, 600], 'Name', '平均路径跳数时间序列');
    plot(time_data, avg_hops, 'b-', 'LineWidth', 2);
    xlabel('时间 (秒)', 'FontSize', 11); 
    ylabel('平均路径跳数', 'FontSize', 11);
    title('平均路径跳数时间序列', 'FontSize', 12, 'FontWeight', 'bold'); 
    grid on; grid minor; % 显示主/次网格
    set(gca, 'FontSize', 10); % 设置坐标轴字体大小

    %% ========== 第二个图：网络直径时间序列 ==========
    figure('Position', [200, 200, 800, 600], 'Name', '网络直径时间序列');
    plot(time_data, diameter, 'r-', 'LineWidth', 2);
    xlabel('时间 (秒)', 'FontSize', 11); 
    ylabel('网络直径', 'FontSize', 11);
    title('网络直径时间序列', 'FontSize', 12, 'FontWeight', 'bold'); 
    grid on; grid minor;
    set(gca, 'FontSize', 10);

    %% ========== 第三个图：拓扑动态性分析 ==========
    figure('Position', [300, 300, 800, 600], 'Name', '拓扑动态性分析');
    plot(time_data(2:end), variability(2:end), 'g-', 'LineWidth', 2);
    xlabel('时间 (秒)', 'FontSize', 11); 
    ylabel('拓扑变化率', 'FontSize', 11);
    title('拓扑动态性分析', 'FontSize', 12, 'FontWeight', 'bold'); 
    grid on; grid minor;
    set(gca, 'FontSize', 10);

    %% ========== 第四个图：跳数与直径关系 ==========
    figure('Position', [400, 400, 800, 600], 'Name', '跳数与直径关系');
    scatter(avg_hops, diameter, 50, 'filled', 'MarkerEdgeColor', 'k'); % 增加描边更清晰
    xlabel('平均路径跳数', 'FontSize', 11); 
    ylabel('网络直径', 'FontSize', 11);
    title('跳数与直径关系', 'FontSize', 12, 'FontWeight', 'bold'); 
    grid on; grid minor;
    set(gca, 'FontSize', 10);

end