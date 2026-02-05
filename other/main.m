clc; clear; close all;

%% ================== 全局参数 ==================
T   = 48;        % 总卫星数
h   = 550;       % 轨道高度 km
inc = 53;        % 倾角 deg
eta = 0.6;       % 评价函数权重
time = 0;        % 单时刻分析

% 搜索空间
P_set    = 4:2:12;
F_set    = 0:5;
dmax_set = 800:200:2000;

%% ================== 初始化 ==================
bestScore = -inf;

bestConfig = struct( ...
    'P', NaN, ...
    'F', NaN, ...
    'dmax', NaN, ...
    'performance', [] );

validCount = 0;
totalCount = length(P_set) * length(F_set) * length(dmax_set);

%% ================== 参数遍历 ==================
for P = P_set
    for F = F_set
        for dmax = dmax_set

            % Walker 星座
            sats = generateWalkerConstellation(T, P, F, h, inc);
            pos  = computeSatellitePosition(sats, time);

            N = length(sats);

            % ===== 正确的结构体预分配（关键修复点）=====
            env = repmat(struct( ...
                'p_node',   0, ...
                'linkLoss', 1 ), N, 1);

            % ===== 空间环境建模 =====
            for i = 1:N
                lat = asind(pos(i,3) / norm(pos(i,:)));
                env(i) = spaceEnvironmentModel(lat, h);
            end

            % 异轨建链
            A = buildLinks_ISL(pos, env, dmax);

            % 网络性能
            perf = evaluateNetworkPerformance(A);

            if perf.isConnected
                validCount = validCount + 1;
            end

            % 评价函数
            score = eta * perf.efficiency ...
                  - (1-eta) * perf.avgPath;

            % 更新最优解
            if score > bestScore
                bestScore = score;
                bestConfig.P = P;
                bestConfig.F = F;
                bestConfig.dmax = dmax;
                bestConfig.performance = perf;
            end
        end
    end
end

%% ================== 输出结果 ==================
disp('========== 最优星座构型 ==========');
disp(bestConfig);

fprintf('可连通构型比例：%.2f%%\n', ...
        100 * validCount / totalCount);
