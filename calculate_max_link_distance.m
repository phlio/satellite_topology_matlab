function max_distance = calculate_max_link_distance(h, Re, H_atm)
% 计算最大建链距离
% 输入: h-轨道高度, Re-地球半径, H_atm-大气层高度
% 输出: max_distance-最大建链距离(km)

    % 计算卫星到地平线的距离
    satellite_altitude = h + Re;
    horizon_distance = sqrt((satellite_altitude)^2 - Re^2);
    
    % 两颗卫星之间的最大可能距离
    max_distance = 2 * horizon_distance;
    
    % 考虑工程约束，设置合理上限
    % max_distance = min(max_distance, 5000); % 工程上限5000km
end