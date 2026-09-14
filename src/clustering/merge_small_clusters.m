function lab = merge_small_clusters(lab, Dseg, minSz)
%MERGE_SMALL_CLUSTERS  Merge clusters with fewer than minSz segments into the
%   cluster with the smallest mean DTW distance to their segments. Repeats until
%   no small cluster remains, then relabels 1..K.
    while true
        [u, ~, j] = unique(lab); cnt = accumarray(j, 1);
        small = u(cnt < minSz); if isempty(small), break; end
        i = find(lab == small(1)); best = inf; bestC = [];
        for v = u(:)'
            if v == small(1), continue; end
            d = mean(Dseg(i, lab == v), 'all');
            if d < best, best = d; bestC = v; end
        end
        lab(i) = bestC;
    end
    [~, ~, lab] = unique(lab);
end
