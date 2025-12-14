function is_visible = check_visibility(pos1, pos2, Re)
% 检查两颗卫星之间是否视距可见（不被地球遮挡）
% 输入: pos1, pos2-卫星位置向量, Re-地球半径
% 输出: is_visible-是否可见

    % 计算地心到两点连线的垂直距离
    earth_center = [0, 0, 0];
    d_min = point_to_line_distance(earth_center, pos1, pos2);
    
    % 如果最小距离大于地球半径，则可见（考虑5%安全余量）
    is_visible = (d_min > Re * 1.05);
end