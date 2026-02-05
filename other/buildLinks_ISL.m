function A = buildLinks_ISL(pos, env, dmax)
N = size(pos,1);
A = zeros(N);

for i = 1:N
    for j = i+1:N
        d = norm(pos(i,:) - pos(j,:));

        if d < dmax
            if rand > env(i).p_node && rand > env(j).p_node
                w = 1 / (d * env(i).linkLoss * env(j).linkLoss);
                A(i,j) = w;
                A(j,i) = w;
            end
        end
    end
end
end
