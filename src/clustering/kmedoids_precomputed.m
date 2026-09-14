function [lab, med] = kmedoids_precomputed(Dm, K, nRestart)
%KMEDOIDS_PRECOMPUTED  PAM-style k-medoids on a precomputed distance matrix.
    n = size(Dm,1); bestCost = inf; lab = []; med = [];
    for r = 1:nRestart
        m = randperm(n, K); l = [];
        for it = 1:100
            [~, l] = min(Dm(:, m), [], 2);
            mNew = m;
            for k = 1:K
                idx = find(l == k); if isempty(idx), continue; end
                [~, a] = min(sum(Dm(idx, idx), 2)); mNew(k) = idx(a);
            end
            if isequal(mNew, m), break; end
            m = mNew;
        end
        cost = sum(min(Dm(:, m), [], 2));
        if cost < bestCost, bestCost = cost; lab = l; med = m; end
    end
end
