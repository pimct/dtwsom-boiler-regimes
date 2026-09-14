function splitRow = make_partition(epi, nRows, lstmCfg)
%MAKE_PARTITION  Leakage-resistant train / validation / test split for Stage B.
%   Within every regime episode, rows are assigned in time order
%   train -> val -> test with the fractions lstmCfg.frac, and lstmCfg.purge rows
%   are removed ("gap") at each internal boundary. Episodes shorter than
%   lstmCfg.minEpisodeRows go entirely to train. Windows are later formed only
%   inside one partition (see build_windows), so no window straddles two
%   partitions regardless of its length.
    splitRow = repmat("gap", nRows, 1);
    for e = 1:height(epi)
        r0 = epi.RowFirst(e); r1 = min(epi.RowLast(e), nRows); n = r1 - r0 + 1;
        if n < lstmCfg.minEpisodeRows
            splitRow(r0:r1) = "train"; continue;
        end
        b1 = r0 + floor(lstmCfg.frac(1)*n) - 1;
        b2 = b1 + floor(lstmCfg.frac(2)*n);
        splitRow(r0:b1) = "train";
        splitRow(b1+1:min(b1+lstmCfg.purge,r1)) = "gap";
        splitRow(min(b1+lstmCfg.purge+1,r1):b2) = "val";
        splitRow(b2+1:min(b2+lstmCfg.purge,r1)) = "gap";
        splitRow(min(b2+lstmCfg.purge+1,r1):r1) = "test";
    end
end
