function [dist, S] = dtw_batch(x, Wm, band)
%DTW_BATCH  Vectorised classic DTW of one segment against all prototypes and channels.
%   [dist, S] = DTW_BATCH(x, Wm, band)
%   x    : [D x L]          Wm : [nN x D x L]
%   dist : [nN x D], dist(j,c) = DTW(x(c,:), Wm(j,c,:)) with |.| local cost and
%          symmetric steps {(i-1,k-1),(i-1,k),(i,k-1)} (identical to dtw.m for 1-D)
%   S    : [nN x D x L x L] uint8 step choice for back-tracking (1 diag, 2 up, 3 left)
%   band : optional Sakoe-Chiba band as a fraction of L (0 or [] = unconstrained)
    [nN, D, L] = size(Wm);
    C = abs(reshape(x,[1 D L 1]) - reshape(Wm,[nN D 1 L]));   % C(j,c,i,k)
    if nargin > 2 && ~isempty(band) && band > 0
        w = max(1, round(band*L)); [ii, kk] = ndgrid(1:L, 1:L);
        C(:,:,abs(ii-kk) > w) = inf;
    end
    G = inf(nN, D, L, L, 'like', C);  S = zeros(nN, D, L, L, 'uint8');
    G(:,:,1,1) = C(:,:,1,1);
    for i = 2:L, G(:,:,i,1) = G(:,:,i-1,1) + C(:,:,i,1); S(:,:,i,1) = 2; end
    for k = 2:L, G(:,:,1,k) = G(:,:,1,k-1) + C(:,:,1,k); S(:,:,1,k) = 3; end
    for i = 2:L
        for k = 2:L
            [m, s] = min(cat(5, G(:,:,i-1,k-1), G(:,:,i-1,k), G(:,:,i,k-1)), [], 5);
            G(:,:,i,k) = m + C(:,:,i,k);  S(:,:,i,k) = uint8(s);
        end
    end
    dist = G(:,:,L,L);
end
