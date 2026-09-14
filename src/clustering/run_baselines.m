function base = run_baselines(X, Dseg, W, mainLab, K, cfg)
%RUN_BASELINES  Clustering baselines on the same segments and the same K
%   (Supplementary Table S2): Euclidean SOM + hierarchical clustering,
%   hierarchical clustering of the segment DTW matrix, and DTW k-medoids.
%   Reports the segment silhouette (DTW) and the ARI against the DTW-SOM labelling.
    Dv = squareform(Dseg);
    base = table('Size',[0 4], 'VariableTypes',{'string','double','double','double'}, ...
                 'VariableNames',{'Method','K','Silhouette_DTW','ARI_vs_DTWSOM'});
    addRow = @(T,name,lab) [T; {name, K, mean(silhouette([],lab,Dv)), adjusted_rand(mainLab, lab)}];
    base = addRow(base, "DTW-SOM + HC (proposed)", mainLab);

    rng(cfg.seed);
    We = train_som(X, cfg, 'euclidean');
    Ze = linkage(squareform(pair_dist(We, 'euclidean')), cfg.linkage);
    labE = cluster(Ze, 'maxclust', K);
    base = addRow(base, "Euclidean SOM + HC", labE(predict_bmu(X, We, 'euclidean')));

    if cfg.dtw.band > 0                       % the same map without the band
        rng(cfg.seed);
        cfgU = cfg; cfgU.dtw.band = 0; Wu = train_som(X, cfgU, 'dtw'); bu = predict_bmu(X, Wu, 'dtw', 0);
        [nlu, Ku] = select_clusters(Wu, X, bu, pair_dist(X, 'dtw', 0), cfgU);
        base = [base; {"DTW-SOM unconstrained (no band)", Ku, ...
                       mean(silhouette([],nlu(bu),Dv)), adjusted_rand(mainLab, nlu(bu))}];
    end

    base = addRow(base, "DTW hierarchical (segments)", cluster(linkage(Dv, cfg.linkage), 'maxclust', K));

    rng(cfg.seed);
    base = addRow(base, "DTW k-medoids", kmedoids_precomputed(Dseg, K, 20));
end
