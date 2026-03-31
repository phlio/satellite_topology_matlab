function relation_score = calculate_orbit_relation_score(sat1, sat2, mapping)
% 计算轨道关系评分，鼓励形成规则的拓扑结构

    orbit1 = mapping(sat1).orbit;
    orbit2 = mapping(sat2).orbit;
    sat_in_orbit1 = mapping(sat1).sat_in_orbit;
    sat_in_orbit2 = mapping(sat2).sat_in_orbit;
    
    % 轨道差（模运算处理首尾轨道）
    P = max([mapping.orbit]); % 轨道总数
    S = max([mapping.sat_in_orbit]); % 每轨卫星数
    
    orbit_diff = min(abs(orbit1 - orbit2), P - abs(orbit1 - orbit2));
    
    if orbit_diff == 1 % 相邻轨道
        % 鼓励形成近似"同编号"或规则扭曲连接
        sat_diff = min(abs(sat_in_orbit1 - sat_in_orbit2), ...
                      S - abs(sat_in_orbit1 - sat_in_orbit2));
        relation_score = 1 - (sat_diff / (S/2));
    else
        relation_score = 0; % 只连接相邻轨道
    end
end