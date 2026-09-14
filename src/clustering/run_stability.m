function stab = run_stability(X, Dseg, cfg, mainLab)
%RUN_STABILITY  Retrain the DTW-SOM with several seeds and compare the partitions.
%   Returns K per seed, the pairwise ARI matrix, its mean, and the ARI of each
%   seed against the reported labelling.
    cfgS = cfg; cfgS.numEpochs = cfg.stabilityEpochs;
    nSd = numel(cfg.stabilitySeeds); nSeg = numel(X);
    labs = zeros(nSeg, nSd); Ksel = zeros(1, nSd);
    for s = 1:nSd
        rng(cfg.stabilitySeeds(s));
        Ws = train_som(X, cfgS, 'dtw');
        bs = predict_bmu(X, Ws, 'dtw', cfg.dtw.band);
        [nl, Ksel(s)] = select_clusters(Ws, X, bs, Dseg, cfg);
        labs(:, s) = nl(bs);
    end
    ari = ones(nSd);
    for a = 1:nSd
        for b = a+1:nSd
            ari(a,b) = adjusted_rand(labs(:,a), labs(:,b)); ari(b,a) = ari(a,b);
        end
    end
    stab.seeds        = cfg.stabilitySeeds;
    stab.K_per_seed   = Ksel;
    stab.ARI_pairwise = ari;
    stab.ARI_mean     = mean(ari(triu(true(nSd),1)));
    stab.ARI_vs_main  = arrayfun(@(s) adjusted_rand(mainLab, labs(:,s)), 1:nSd);
    stab.labels       = labs;
end
