function distance = point_to_line_distance(point, line_start, line_end)
% 计算点到直线的最短距离
% 输入: point-点坐标, line_start, line_end-直线端点
% 输出: distance-最短距离

    % 直线方向向量
    line_vec = line_end - line_start;
    point_vec = point - line_start;
    
    % 计算投影长度
    t = dot(point_vec, line_vec) / dot(line_vec, line_vec);
    t = max(0, min(1, t)); % 限制在线段范围内
    
    % 计算最近点坐标
    closest_point = line_start + t * line_vec;
    
    % 计算距离
    distance = norm(point - closest_point);
end