function ari = adjusted_rand(a, b)
%ADJUSTED_RAND  Adjusted Rand index between two labellings (Hubert & Arabie, 1985).
    C = crosstab(a(:), b(:)); n = sum(C(:));
    comb = @(v) sum(v.*(v-1)/2);
    sij = comb(C(:)); si = comb(sum(C,2)); sj = comb(sum(C,1)); tot = n*(n-1)/2;
    expct = si*sj/tot; mx = (si+sj)/2;
    ari = (sij - expct) / max(mx - expct, eps);
end
