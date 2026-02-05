function updated_graph = apply_solar_radiation_effect(graph_matrix, current_positions, sun_unit_vector, fov_degrees)
% 应用太阳辐射效应对卫星拓扑的影响
% 当太阳矢量与星间链路矢量代表的直线夹角小于视场角(FOV)时，以50%概率断开该连接
% 直线夹角考虑两种情况：angle < FOV 或 angle > (pi - FOV)
%
% 输入:
%   graph_matrix - 卫星连接关系的对称矩阵 (T x T)
%   current_positions - 当前时刻卫星位置矩阵 (T x 3)，每行是[x, y, z]坐标
%   sun_unit_vector - 太阳到地心的单位矢量 (1 x 3 或 3 x 1)
%   fov_degrees - 卫星天线视场角(FOV)，单位为度，默认0.7度
%
% 输出:
%   updated_graph - 应用太阳辐射效应后的更新连接矩阵
    
    % 设置断链概率（50%）
    break_probability = 0.5;
    
    % 确保sun_unit_vector是行向量
    if size(sun_unit_vector, 1) > 1
        sun_unit_vector = sun_unit_vector';
    end
    
    % 将FOV从度转换为弧度
    fov_radians = deg2rad(fov_degrees);
    
    % 获取卫星总数
    T = size(graph_matrix, 1);
    
    % 创建更新后的图矩阵副本
    updated_graph = graph_matrix;
    
    fprintf('      应用太阳辐射效应 (FOV=%.1f°, 断链概率=%.0f%%)...\n', fov_degrees, break_probability*100);
    
    % 遍历所有可能的连接
    broken_links_count = 0;
    for i = 1:T
        for j = i+1:T  % 只检查上三角，因为矩阵是对称的
            if graph_matrix(i, j) == 1
                % 计算卫星i到卫星j的连接矢量
                link_vector = current_positions(j, :) - current_positions(i, :);
                
                % 归一化连接矢量
                link_magnitude = norm(link_vector);
                if link_magnitude > 0
                    link_unit_vector = link_vector / link_magnitude;
                    
                    % 计算连接矢量与太阳矢量的夹角
                    % 使用点积公式: cos(theta) = a·b / (|a||b|)
                    % 由于都是单位向量，所以 cos(theta) = a·b
                    cos_angle = dot(link_unit_vector, sun_unit_vector);
                    
                    % 处理数值精度问题
                    cos_angle = max(min(cos_angle, 1), -1);
                    
                    % 计算实际夹角（弧度）
                    angle_radians = acos(cos_angle);
                    
                    % 检查直线夹角是否小于FOV
                    % 直线夹角 = min(angle, pi - angle)
                    line_angle = min(angle_radians, pi - angle_radians);
                    
                    % 如果直线夹角小于FOV，则以50%概率断开连接
                    if line_angle < fov_radians
                        if rand() < break_probability
                            % 断开连接（双向）
                            updated_graph(i, j) = 0;
                            updated_graph(j, i) = 0;
                            broken_links_count = broken_links_count + 1;
                        end
                    end
                end
            end
        end
    end
    
    % 统计被太阳辐射断开的连接数
    if broken_links_count > 0
        fprintf('      太阳辐射导致 %d 条链路断开\n', broken_links_count);
    else
        fprintf('      无链路受太阳辐射影响\n');
    end
end