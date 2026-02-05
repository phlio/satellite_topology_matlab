function env = spaceEnvironmentModel(lat, alt)
% 等效空间环境模型（节点 + 链路）

E = exp(-(lat/35)^2) * (alt/1000);

env.p_node   = min(0.08, 0.02 * E);
env.linkLoss = 1 + 0.6 * E;
end
