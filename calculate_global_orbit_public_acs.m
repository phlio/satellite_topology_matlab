function global_orbit_public_acs = calculate_global_orbit_public_acs(inter_orbit_candidates_all_times, S, P, num_time_points)
% 计算全局公共可建链（在每个时间点内求交集，再跨时间点求交集）
% 输入:
%   inter_orbit_candidates_all_times - 所有时间点的异轨可建链候选
%   S - 每轨道卫星数, P - 轨道数, num_time_points - 时间点数量
% 输出:
%   global_orbit_public_acs - 1 x P 的cell数组，每个轨道包含全局公共可建链

    global_orbit_public_acs = cell(1, P);
    
    % 为每个轨道计算全局公共可建链
    for orbit = 1:P
        fprintf('      处理轨道 %d/%d 的全局公共可建链...\n', orbit, P);
        
        % 存储所有时间点该轨道的公共可建链（每个时间点内先求交集）
        time_point_public_acs_list = {};
        
        for t_idx = 1:num_time_points
            inter_orbit_candidates = inter_orbit_candidates_all_times{t_idx};
            
            % 在当前时间点内，对该轨道所有卫星求交集（公共可建链）
            if isempty(inter_orbit_candidates{1, orbit})
                current_time_public_acs = []; % 当前时间点无数据
            else
                current_time_public_acs = inter_orbit_candidates{1, orbit};
                for sat_idx = 2:S
                    if ~isempty(inter_orbit_candidates{sat_idx, orbit})
                        current_time_public_acs = intersect(current_time_public_acs, inter_orbit_candidates{sat_idx, orbit});
                    else
                        current_time_public_acs = []; % 如果有任何卫星没有候选，则当前时间点公共可建链为空
                        break;
                    end
                end
            end
            
            % 存储当前时间点的公共可建链结果
            time_point_public_acs_list{end+1} = current_time_public_acs;
        end
        
        % 对所有时间点的公共可建链结果求交集
        if ~isempty(time_point_public_acs_list) && ~isempty(time_point_public_acs_list{1})
            global_orbit_public_acs{orbit} = time_point_public_acs_list{1};
            for t_idx = 2:length(time_point_public_acs_list)
                if ~isempty(time_point_public_acs_list{t_idx})
                    global_orbit_public_acs{orbit} = intersect(global_orbit_public_acs{orbit}, time_point_public_acs_list{t_idx});
                else
                    global_orbit_public_acs{orbit} = []; % 如果有任何时间点为空，则全局结果为空
                    break;
                end
            end
        else
            global_orbit_public_acs{orbit} = [];
        end
        
        if ~isempty(global_orbit_public_acs{orbit})
            fprintf('      轨道%d全局公共可建链: [%s]\n', orbit, num2str(global_orbit_public_acs{orbit}));
        else
            fprintf('      轨道%d无全局公共可建链\n', orbit);
        end
    end
end