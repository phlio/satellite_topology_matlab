function perf = evaluateNetworkPerformance(A)
G = graph(A);

bins = conncomp(G);
perf.isConnected = all(bins == bins(1));

D = distances(G);

if perf.isConnected
    perf.avgPath = mean(D(D > 0 & ~isinf(D)), 'all');
else
    perf.avgPath = inf;
end

perf.efficiency = mean(1 ./ D(D > 0 & ~isinf(D)), 'all');
end
