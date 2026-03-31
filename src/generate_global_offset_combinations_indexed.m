function global_offset_combinations_table = generate_global_offset_combinations_indexed(global_orbit_public_acs, S, P)
% 生成按sum_mod分类的全局offset组合表格
% 输入:
%   global_orbit_public_acs - 全局公共可建链 (1 x P cell array)
%   S - 每轨道卫星数, P - 轨道数
% 输出:
%   global_offset_combinations_table - S x N cell数组，其中N为最大组合数
%                                    第i行(1<=i<=S)存储所有sum_mod = i-1的offset组合
%                                    每个单元格包含一个1 x P的offset向量

    % 初始化结果表格：S行，动态列数
    global_offset_combinations_table = cell(S, 1);
    for i = 1:S
        global_offset_combinations_table{i} = []; % 初始化为空矩阵
    end
    
    % 获取每个轨道公共可建链的长度
    acs_lengths = zeros(1, P);
    for orbit = 1:P
        if ~isempty(global_orbit_public_acs{orbit})
            acs_lengths(orbit) = length(global_orbit_public_acs{orbit});
        else
            acs_lengths(orbit) = 0;
        end
    end
    
    % 检查是否有有效可建链
    if all(acs_lengths == 0)
        error('无有效可建链组合，请检查全局公共可建链数据');
    end
    
    % 计算所有可能的组合总数
    total_combinations = 1;
    for orbit = 1:P
        if acs_lengths(orbit) > 0
            total_combinations = total_combinations * acs_lengths(orbit);
        end
    end
    
    if total_combinations == 0
        fprintf('      无有效组合\n');
        return;
    end
    
    fprintf('      生成全局offset组合，共%d个组合...\n', total_combinations);
    
    % 遍历所有组合
    for comb_idx = 1:total_combinations
        temp_idx = comb_idx - 1; 
        current_offset = zeros(1, P);
        
        % 分解索引，提取当前组合的offset
        for orbit = P:-1:1
            if acs_lengths(orbit) > 0
                acs_len = acs_lengths(orbit);
                orbit_idx = mod(temp_idx, acs_len) + 1;
                current_offset(orbit) = global_orbit_public_acs{orbit}(orbit_idx);
                temp_idx = floor(temp_idx / acs_len);
            else
                current_offset(orbit) = 0; % 无公共可建链的轨道设为0
            end
        end
        
        % 计算sum(mod S)，范围为0到S-1
        sum_mod = mod(sum(current_offset), S);
        
        % 存储到对应的行中（MATLAB索引从1开始，所以行号为sum_mod+1）
        row_idx = sum_mod + 1;
        if isempty(global_offset_combinations_table{row_idx})
            global_offset_combinations_table{row_idx} = current_offset;
        else
            global_offset_combinations_table{row_idx} = [global_offset_combinations_table{row_idx}; current_offset];
        end
    end
    
    % 输出统计信息
    valid_combinations = 0;
    for i = 1:S
        if ~isempty(global_offset_combinations_table{i})
            num_in_row = size(global_offset_combinations_table{i}, 1);
            valid_combinations = valid_combinations + num_in_row;
            fprintf('      sum_mod = %d: %d个组合\n', i-1, num_in_row);
        end
    end
    fprintf('      共找到%d个有效组合\n', valid_combinations);
end