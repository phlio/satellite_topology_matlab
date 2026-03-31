function mapping = create_satellite_mapping(sat_names, P, S)
% 创建卫星名称到轨道/卫星编号的映射
% 输入: sat_names-卫星名称数组, P-轨道数, S-每轨卫星数
% 输出: mapping-映射结构体

    mapping = struct();
    % 计算轨道号和卫星号所需的位数（确保能覆盖最大编号）
    orbit_digits = ceil(log10(P + 1));  % 轨道号位数
    sat_digits = ceil(log10(S + 1));    % 每轨卫星号位数
    total_digits = orbit_digits + sat_digits;  % 总位数
    
    for i = 1:length(sat_names)
        name = sat_names{i};
        
        % 提取数字部分（保留字符串形式以处理前导零）
        num_str = regexp(name, '\d+', 'match');
        if ~isempty(num_str)
            digits_str = num_str{1};
            
            % 检查数字长度是否符合预期
            if length(digits_str) ~= total_digits
                warning('卫星名称%s的数字部分长度不符合预期（应为%d位）', name, total_digits);
                continue;
            end
            
            % 分割轨道号和卫星号字符串
            orbit_str = digits_str(1:orbit_digits);
            sat_str = digits_str(orbit_digits+1:end);
            
            % 转换为数字
            orbit_num = str2double(orbit_str);
            sat_in_orbit = str2double(sat_str);
            
            % 验证范围
            if orbit_num >= 1 && orbit_num <= P && sat_in_orbit >= 1 && sat_in_orbit <= S
                mapping(i).orbit = orbit_num;
                mapping(i).sat_in_orbit = sat_in_orbit;
                mapping(i).original_name = name;
                
                fprintf('   %s -> 轨道%d, 卫星%d\n', name, orbit_num, sat_in_orbit);
            else
                warning('卫星名称%s的编号超出范围（轨道%d，卫星%d）', name, orbit_num, sat_in_orbit);
            end
        else
            warning('卫星名称%s中未找到有效数字', name);
        end
    end
end