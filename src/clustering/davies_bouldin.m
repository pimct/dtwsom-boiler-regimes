function db = davies_bouldin(Dm, lab)
%DAVIES_BOULDIN  Davies-Bouldin index on a precomputed distance matrix (medoid centres).
    ks = unique(lab); K = numel(ks); S = zeros(K,1); med = zeros(K,1);
    for i = 1:K
        m = find(lab == ks(i));
        [~, a] = min(sum(Dm(m,m), 2)); med(i) = m(a);
        S(i) = mean(Dm(m, med(i)));
    end
    R = zeros(K);
    for i = 1:K
        for j = 1:K
            if i ~= j, R(i,j) = (S(i)+S(j)) / max(Dm(med(i),med(j)), eps); end
        end
    end
    db = mean(max(R, [], 2));
end
