function generate_geometry_analysis_report(avg_hops, diameter, variability, time_data)
% 生成基于几何位置的拓扑分析报告

    fprintf('\n=== 基于几何位置的拓扑分析报告 ===\n');
    fprintf('分析时间范围: %.1f - %.1f 秒\n', min(time_data), max(time_data));
    fprintf('时间点数量: %d\n', length(time_data));
    
    fprintf('\n1. 路径跳数分析:\n');
    fprintf('   平均值: %.4f ± %.4f\n', mean(avg_hops), std(avg_hops));
    fprintf('   范围: [%.4f, %.4f]\n', min(avg_hops), max(avg_hops));
    fprintf('   变异系数: %.4f\n', std(avg_hops)/mean(avg_hops));
    
    fprintf('\n2. 网络直径分析:\n');
    fprintf('   平均值: %.2f ± %.2f\n', mean(diameter), std(diameter));
    fprintf('   范围: [%d, %d]\n', min(diameter), max(diameter));
    
    fprintf('\n3. 拓扑动态性分析:\n');
    valid_variability = variability(variability > 0);
    if ~isempty(valid_variability)
        fprintf('   平均变化率: %.4f ± %.4f\n', mean(valid_variability), std(valid_variability));
        fprintf('   最大变化率: %.4f\n', max(valid_variability));
        
        % 计算稳定性指标
        stability = 1 - mean(valid_variability);
        fprintf('   拓扑稳定性指数: %.4f\n', stability);
    else
        fprintf('   拓扑保持稳定，无变化\n');
    end
    
    fprintf('\n4. 时间相关性分析:\n');
    if length(avg_hops) > 1
        % 计算自相关性
        time_lags = 1:min(10, length(avg_hops)-1);
        autocorr_values = zeros(size(time_lags));
        
        for i = 1:length(time_lags)
            lag = time_lags(i);
            if lag < length(avg_hops)
                autocorr_values(i) = corr(avg_hops(1:end-lag), avg_hops(lag+1:end));
            end
        end
        
        fprintf('   时间自相关性 (lag=1): %.4f\n', autocorr_values(1));
        if any(autocorr_values > 0.5)
            fprintf('   → 拓扑性能具有较强时间相关性\n');
        else
            fprintf('   → 拓扑性能随时间快速变化\n');
        end
    end
    
    fprintf('\n5. 性能评估:\n');
    avg_performance = mean(avg_hops);
    if avg_performance < 4
        fprintf('   ✅ 网络连通性优秀 (平均跳数 < 4)\n');
    elseif avg_performance < 6
        fprintf('   ⚠️  网络连通性良好 (平均跳数 4-6)\n');
    else
        fprintf('   ❌ 网络连通性较差 (平均跳数 > 6)\n');
    end
    
    if mean(diameter) < 8
        fprintf('   ✅ 网络直径合理\n');
    else
        fprintf('   ⚠️  网络直径偏大\n');
    end
end