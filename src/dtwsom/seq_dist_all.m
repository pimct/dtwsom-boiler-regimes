function d = seq_dist_all(x, Wm, distMode, band)
%SEQ_DIST_ALL  Distance from one [D x L] segment to every row of Wm [nN x D x L].
    if nargin < 4, band = 0; end
    if strcmp(distMode,'dtw')
        d = sum(dtw_batch(x, Wm, band), 2);
    else
        d = sqrt(sum((Wm - reshape(x,[1 size(x)])).^2, [2 3]));
    end
end
