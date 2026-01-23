function graph_matrix = build_geometry_based_topology(positions, mapping, T, P, S, h, Re, H_atm)
% 基于卫星几何位置构建拓扑
% 修复了所有缺失的函数调用

    graph_matrix = zeros(T, T);
    inter_orbit_candidates = cell(S, P); % 每个卫星对应一个空数组
%     for i = 1:T
%         inter_orbit_candidates{i} = [];
%     end
    
    fprintf('      基于几何位置构建拓扑...\n');
    
    % 计算建链阈值距离
    max_link_distance = calculate_max_link_distance(h, Re, H_atm);
    fprintf('      最大建链距离: %.2f km\n', max_link_distance);
    
    
    %% 1. 同轨链路构建
    fprintf('      构建同轨链路...\n');
    for orbit = 1:P
        % 获取当前轨道的所有卫星
        orbit_indices = find([mapping.orbit] == orbit);
        
        if isempty(orbit_indices)
            continue;
        end
        
        % 按卫星在轨道中的编号排序
        [~, sort_idx] = sort([mapping(orbit_indices).sat_in_orbit]);
        orbit_indices = orbit_indices(sort_idx);
        
        % 构建同轨环形拓扑
        for j = 1:length(orbit_indices)
            current_sat = orbit_indices(j);
            
            % 同轨前向链路（连接到轨道下一颗卫星）
            next_sat_idx = mod(j, length(orbit_indices)) + 1;
            next_sat = orbit_indices(next_sat_idx);
            
            % 计算卫星间距离
            dist = norm(positions(current_sat, :) - positions(next_sat, :));
            
            % 检查距离约束和可见性
            if dist <= max_link_distance && check_visibility(positions(current_sat, :), positions(next_sat, :), Re)
                graph_matrix(current_sat, next_sat) = 1;
                graph_matrix(next_sat, current_sat) = 1;
            end
            
            % 同轨后向链路（连接到轨道上一颗卫星）
            prev_sat_idx = mod(j-2, length(orbit_indices)) + 1;
            prev_sat = orbit_indices(prev_sat_idx);
            
            dist = norm(positions(current_sat, :) - positions(prev_sat, :));
            if dist <= max_link_distance && check_visibility(positions(current_sat, :), positions(prev_sat, :), Re)
                graph_matrix(current_sat, prev_sat) = 1;
                graph_matrix(prev_sat, current_sat) = 1;
            end
        end
    end
    
    
%% 2. 异轨链路构建（原逻辑完全保留，仅新增“记录可建链集合”的步骤）
    fprintf('      构建异轨链路...\n');
    for orbit = 1:P
        current_orbit_indices = find([mapping.orbit] == orbit);
        if isempty(current_orbit_indices)
            continue;
        end
        
        % 原逻辑：相邻轨道选择（一字不改）
%         adjacent_orbits = [mod(orbit-2, P) + 1, mod(orbit, P) + 1];
        adjacent_orbits = mod(orbit, P) + 1;
        for adj_orbit = adjacent_orbits
            adjacent_orbit_indices = find([mapping.orbit] == adj_orbit);
            if isempty(adjacent_orbit_indices)
                continue;
            end
            
            % 原逻辑：邻轨卫星排序（一字不改）
            [~, adj_sort_idx] = sort([mapping(adjacent_orbit_indices).sat_in_orbit]);
            adjacent_orbit_indices = adjacent_orbit_indices(adj_sort_idx);
            
            % 为当前轨道每颗卫星处理异轨建链（原逻辑完全保留）
            for i = 1:length(current_orbit_indices)
                current_sat = current_orbit_indices(i);
                current_pos = positions(current_sat, :);
                
                % ===================== 仅新增：记录当前卫星的可建链邻轨卫星 =====================
                % 遍历邻轨所有卫星，筛选“满足可建链条件”的卫星（仅记录，不影响后续建链）
                temp_candidates = [];
                for adj_sat = adjacent_orbit_indices
                    % 检查可建链条件（距离+视距）
                    dist = norm(current_pos - positions(adj_sat, :));
                    if dist <= max_link_distance && check_visibility(current_pos, positions(adj_sat, :), Re)
                        relative_position = mod(adj_sat,length(current_orbit_indices));% 东向异轨链路相对可建链卫星
                        if relative_position - i > S/2
                            relative_position = relative_position - i - S;
                        elseif relative_position - i < -S/2
                            relative_position = relative_position - i + S;
                        else
                            relative_position = relative_position - i;
                        end
                        temp_candidates = [temp_candidates, relative_position];
                    end
                end
                % 存入可建链集合（仅记录，不修改后续建链逻辑）
                inter_orbit_candidates{i,orbit} = temp_candidates;
                % ==========================================================================
                
                % 原逻辑：调用find_best_inter_orbit_link（一字不改，候选还是全部邻轨卫星）
%                 best_candidate = find_best_inter_orbit_link(current_sat, current_pos, ...
%                                                           adjacent_orbit_indices, positions, ...
%                                                           mapping, max_link_distance, Re);
%                 
%                 if best_candidate > 0
%                     graph_matrix(current_sat, best_candidate) = 1;
%                     graph_matrix(best_candidate, current_sat) = 1;
%                 end
            end
        end
    end
    %% 3. 仅修改这部分：自动从cell提取offset组合（满足U=S/2），异轨建链
    fprintf('      构建异轨链路（自动适配U=S/2）...\n');
    target_U = S / 2; % 目标U值（5）
    orbit_public_acs = cell(1, P); % 存储每个轨道的公共可建链
    
    % 步骤1：自动计算每个轨道的公共可建链
    for orbit = 1:P
        if isempty(inter_orbit_candidates{1, orbit})
            error('轨道%d无任何可建链数据，请检查inter_orbit_candidates', orbit);
        end
        % 取当前轨道10颗卫星可建链的交集（公共可建链）
        public_acs = inter_orbit_candidates{1, orbit};
        for sat_idx = 2:S
            public_acs = intersect(public_acs, inter_orbit_candidates{sat_idx, orbit});
        end
        orbit_public_acs{orbit} = public_acs;
        fprintf('      轨道%d公共可建链: [%s]\n', orbit, num2str(public_acs));
        if isempty(public_acs)
            error('轨道%d无公共可建链，无法建异轨链路', orbit);
        end
    end
    
    % 步骤2：自动生成所有可能的offset组合，筛选sum(mod S)=target_U的组合
    fprintf('      自动筛选满足U=%.0f的offset组合（通用循环）...\n', target_U);
    % 第一步：获取每个轨道公共可建链的长度，构建长度数组（适配任意P）
    acs_lengths = zeros(1, P);
    for orbit = 1:P
        acs_lengths(orbit) = length(orbit_public_acs{orbit});
    end
    
    % 第二步：计算所有可能的组合总数（各轨道长度的乘积）
    total_combinations = 1;
    for orbit = 1:P
        total_combinations = total_combinations * acs_lengths(orbit);
    end
    if total_combinations == 0
        error('无有效可建链组合，请检查公共可建链数据');
    end
    
        % 第三步：遍历所有组合，记录offset和与target_U的差值
    all_combinations = []; % 存储所有组合的offset
    all_diffs = [];        % 存储每个组合的差值（abs(sum_mod - target_U)）
    all_sum_mod = [];      % 存储每个组合的sum(mod S)
    
    for comb_idx = 1:total_combinations
        temp_idx = comb_idx - 1; 
        current_offset = zeros(1, P);
        
        % 分解索引，提取当前组合的offset
        for orbit = P:-1:1
            acs_len = acs_lengths(orbit);
            orbit_idx = mod(temp_idx, acs_len) + 1;
            current_offset(orbit) = orbit_public_acs{orbit}(orbit_idx);
            temp_idx = floor(temp_idx / acs_len);
        end
        
        % 计算sum(mod S)和与target_U的差值
        sum_mod = mod(sum(current_offset), S);
        diff = abs(sum_mod - target_U);
        
        % 存储结果
        all_combinations = [all_combinations; current_offset];
        all_diffs = [all_diffs, diff];
        all_sum_mod = [all_sum_mod, sum_mod];
    end
    
    % 第四步：选择最优组合（先精确匹配，再最接近）
    % 找精确匹配的索引
    exact_match_idx = find(all_diffs == 0);
    if ~isempty(exact_match_idx)
        % 有精确匹配，选第一个
        best_idx = exact_match_idx(1);
        match_type = '精确匹配';
    else
        % 无精确匹配，选差值最小的第一个组合
        [min_diff, min_idx] = min(all_diffs);
        best_idx = min_idx;
        match_type = '最接近匹配';
    end
    
    % 获取最优组合
    found_offset = all_combinations(best_idx, :);
    best_sum_mod = all_sum_mod(best_idx);
    
    % 输出日志（清晰说明匹配类型）
    fprintf('      %s - 选中offset组合: [%s]\n', match_type, num2str(found_offset));
    fprintf('      sum(mod%d)=%.0f，与目标U=%.0f的差值=%.0f\n', ...
        S, best_sum_mod, target_U, all_diffs(best_idx));
    
    % 步骤4：基于找到的offset组合，东向异轨建链（你的原邻轨逻辑）
    for orbit = 1:P
        current_orbit_indices = find([mapping.orbit] == orbit);
        [~, sort_idx] = sort([mapping(current_orbit_indices).sat_in_orbit]);
        current_orbit_sats = current_orbit_indices(sort_idx); % 当前轨道卫星（1-10）
        
        % 东向邻轨（你的原逻辑）
        adj_orbit = mod(orbit, P) + 1;
        adj_orbit_indices = find([mapping.orbit] == adj_orbit);
        [~, adj_sort_idx] = sort([mapping(adj_orbit_indices).sat_in_orbit]);
        adj_orbit_sats = adj_orbit_indices(adj_sort_idx); % 邻轨卫星（1-10）
        
        % 当前轨道的offset（自动找到的组合）
        o = found_offset(orbit);
        % 东向异轨建链（双向，2条/卫星）
        for j = 1:S
            current_sat = current_orbit_sats(j);
            % 相对offset转换为邻轨卫星序号（1-10）
            adj_sat_num = mod(j + o - 1, S) + 1; % 处理正负值
            adj_sat = adj_orbit_sats(adj_sat_num);
            % 双向建链
            graph_matrix(current_sat, adj_sat) = 1;
            graph_matrix(adj_sat, current_sat) = 1;
        end
    end
    %% 3. 拓扑验证与统计
    total_edges = nnz(graph_matrix) / 2;
    node_degrees = sum(graph_matrix, 2);
    avg_degree = mean(node_degrees);
    
    fprintf('      拓扑统计: 总边数=%d, 平均度数=%.2f\n', total_edges, avg_degree);
end
