function selected_global_offsets = select_initial_global_offsets(global_offset_combinations_table, target_U)
% 选择初始全局offset组合（直接根据target_U选择，不存在则报错）
% 输入:
%   global_offset_combinations_table - S x 1 cell数组，每行存储对应sum_mod的offset组合
%   target_U - 目标U值 (S/2)
% 输出:
%   selected_global_offsets - 选定的全局offset向量 (1 x P)

    S = length(global_offset_combinations_table);
    
    % 目标sum_mod值（范围0到S-1）
    target_sum_mod = target_U;
    
    % 检查目标sum_mod是否在有效范围内
    if target_sum_mod < 0 || target_sum_mod >= S
        error('目标U值 %.0f 超出有效范围 [0, %d]', target_U, S-1);
    end
    
    % MATLAB索引从1开始，所以行号为target_sum_mod + 1
    target_row_idx = target_sum_mod + 1;
    
    % 直接检查目标行是否存在有效组合
    if isempty(global_offset_combinations_table{target_row_idx})
        error('目标U值 %.0f 对应的offset组合不存在，请检查全局公共可建链数据', target_U);
    end
    
    % 选择第一个组合（该行的第一个offset向量）
    selected_global_offsets = global_offset_combinations_table{target_row_idx}(1, :);
    fprintf('      全局: 选择U=%.0f的offset: [%s]\n', target_U, num2str(selected_global_offsets));
end