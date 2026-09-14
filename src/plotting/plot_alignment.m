function fh = plot_alignment(X, W, W_snap, clusterIdx, bmuIdx, trainLog, cfg, ClusterMap, g, k, n, sensor)
%PLOT_ALIGNMENT  Fig. 2: DTW alignment between a prototype and one of its segments.
%   g = regime, k = k-th segment of that regime, n = n-th node of that regime,
%   sensor = channel index.
    L = size(X{1},2);
    nodeList = find(clusterIdx == g); idx_g = find(ismember(bmuIdx, nodeList));
    k = min(k, numel(idx_g)); n = min(n, numel(nodeList));
    nodeSel = nodeList(n);
    segment = X{idx_g(k)}(sensor,:); w0 = W_snap{nodeSel}(sensor,:); w1 = W{nodeSel}(sensor,:);
    if cfg.dtw.band > 0, [~, ix, iy] = dtw(w1, segment, round(cfg.dtw.band*L));
    else,                [~, ix, iy] = dtw(w1, segment); end
    fh = figure('Color','w'); hold on;
    plot(w0, ':', 'Color', [0 0.7 1], 'LineWidth', 1.4);
    plot(w1,      'Color', [0 0.7 1], 'LineWidth', 1.4);
    plot(segment, 'Color', [0 0.7 0.4], 'LineWidth', 1.4);
    for q = 1:numel(ix), plot([ix(q) iy(q)], [w1(ix(q)) segment(iy(q))], 'Color', [0.5 0.5 0.5 0.4]); end
    legend(sprintf('w_j, epoch %d', trainLog.snapEpoch), sprintf('w_j, epoch %d', trainLog.epochsRun), ...
           'x_i', 'Location','best');
    xlabel('Sample (5 s)'); ylabel(sprintf('%s, normalised', cfg.baseLabels{sensor})); grid on; hold off;
    title(sprintf('DTW alignment between prototype and segment (%s)', ClusterMap(g)));
end
