function mapping = create_satellite_mapping(sat_names, P, S)
% 创建卫星名称到轨道/卫星编号的映射
% 输入: sat_names-卫星名称数组, P-轨道数, S-每轨卫星数
% 输出: mapping-映射结构体

    mapping = struct();
    
    for i = 1:length(sat_names)
        name = sat_names{i};
        
        % 提取数字部分（Satellite101 -> 101）
        num_str = regexp(name, '\d+', 'match');
        if ~isempty(num_str)
            sat_num = str2double(num_str{1});
            
            % 解析轨道编号和卫星编号
            orbit_num = floor(sat_num / 100);  % 百位：轨道编号
            sat_in_orbit = mod(sat_num, 100); % 后两位：卫星编号
            
            % 验证范围
            if orbit_num >= 1 && orbit_num <= P && sat_in_orbit >= 1 && sat_in_orbit <= S
                mapping(i).orbit = orbit_num;
                mapping(i).sat_in_orbit = sat_in_orbit;
                mapping(i).original_name = name;
                
                fprintf('   %s -> 轨道%d, 卫星%d\n', name, orbit_num, sat_in_orbit);
            else
                warning('卫星名称解析异常: %s', name);
            end
        end
    end
end