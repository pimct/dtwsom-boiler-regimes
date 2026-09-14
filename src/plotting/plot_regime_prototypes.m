function files = plot_regime_prototypes(X, W, clusterIdx, bmuIdx, K, ClusterMap, normInfo, cfg, outDir)
%PLOT_REGIME_PROTOTYPES  Fig. 5: one figure per regime with the prototype
%   trajectories (blue) and the raw segments (grey) in engineering units,
%   with y-limits shared across regimes. Only active nodes (BMU of at least
%   one segment) are counted as prototypes.
    D = size(X{1},1); L = size(X{1},2);
    xmin = normInfo.xmin(:); xmax = normInfo.xmax(:);
    denorm = @(A) A .* (xmax - xmin) + xmin;
    tmin = (0:L-1) * cfg.sample_period_s / 60;
    Yall = denorm(cell2mat(reshape(X, 1, [])));
    ylo = min(Yall, [], 2); yhi = max(Yall, [], 2);
    pad = 0.05 * max(yhi - ylo, eps); ylo = ylo - pad; yhi = yhi + pad;
    activeNodes = unique(bmuIdx);
    files = strings(0,1);
    for g = 1:K
        nodeList = intersect(find(clusterIdx == g), activeNodes);
        idx_g = find(ismember(bmuIdx, nodeList));
        if isempty(nodeList), continue; end
        fh = figure('Color','w','Position',[100 100 1400 320]);
        tiledlayout(1, D, 'TileSpacing','compact','Padding','compact');
        for sensor = 1:D
            nexttile; hold on;
            for q = 1:numel(idx_g)
                Y = denorm(X{idx_g(q)}); plot(tmin, Y(sensor,:), ':', 'Color', [0.6 0.6 0.6]);
            end
            for n = 1:numel(nodeList)
                Wn = denorm(W{nodeList(n)}); plot(tmin, Wn(sensor,:), 'Color', [0 0.35 0.70], 'LineWidth', 1);
            end
            hold off; box on; set(gca,'Layer','top','FontSize',8);
            xlim([0 tmin(end)]); ylim([ylo(sensor) yhi(sensor)]);
            xlabel('Time (min)'); ylabel(cfg.baseLabels{sensor});
        end
        sgtitle(sprintf('%s: %d prototypes, %d segments', ClusterMap(g), numel(nodeList), numel(idx_g)));
        name = matlab.lang.makeValidName(string(ClusterMap(g)));
        f = fullfile(outDir, sprintf('fig05_%s.svg', name));
        exportgraphics(fh, f, 'ContentType','vector');
        exportgraphics(fh, strrep(f,'.svg','.png'), 'Resolution', 300);
        files(end+1,1) = f; %#ok<AGROW>
    end
end
