function fh = plot_record_regimes(dataset, epi, cfg)
%PLOT_RECORD_REGIMES  Fig. 4: the nine variables over the full record with
%   the regime episodes shaded and labelled.
    shadeA  = [0.898 0.965 0.945]; shadeB = [0.741 0.914 0.878];
    edgeCol = [0.157 0.616 0.518]; lineCol = [0.000 0.447 0.741];
    lw = 0.9; fs = 9;
    tmin = (0:height(dataset)-1)' * cfg.sample_period_s / 60; tEnd = tmin(end);

    fh = figure('Color','w','Position',[100 100 1240 900]);
    tiledlayout(3,3,'TileSpacing','compact','Padding','compact');
    for i = 1:9
        ax = nexttile; hold(ax,'on');
        y = dataset.(cfg.baseNames{i});
        ylo = min(y); yhi = max(y); rng_ = max(yhi-ylo, eps);
        ylo = ylo - 0.04*rng_;
        yhi = yhi + (i <= 3) * 0.28*rng_ + 0.04*rng_;
        for e = 1:height(epi)
            c = shadeA; if mod(e,2)==0, c = shadeB; end
            patch(ax, [epi.Start_min(e) epi.End_min(e) epi.End_min(e) epi.Start_min(e)], ...
                  [ylo ylo yhi yhi], c, 'EdgeColor','none');
        end
        for e = 2:height(epi)
            plot(ax, [epi.Start_min(e) epi.Start_min(e)], [ylo yhi], ':', 'Color', edgeCol, 'LineWidth', 0.7);
        end
        plot(ax, tmin, y, '-', 'Color', lineCol, 'LineWidth', lw);
        if i <= 3
            yLab = yhi - 0.26*rng_;
            for e = 1:height(epi)
                xm = epi.Start_min(e) + 0.35*(epi.End_min(e) - epi.Start_min(e));
                plot(ax, xm, yLab, '^', 'MarkerSize', 4, 'MarkerFaceColor', edgeCol, 'MarkerEdgeColor', edgeCol);
                text(ax, xm, yLab + 0.02*rng_, char(epi.Cluster(e)), 'Rotation', 90, 'FontSize', fs-1, ...
                     'HorizontalAlignment','left', 'VerticalAlignment','middle');
            end
        end
        hold(ax,'off'); box(ax,'on');
        set(ax, 'Layer','top', 'FontSize', fs, 'XColor',[0.15 0.15 0.15], 'YColor',[0.15 0.15 0.15]);
        xlim(ax, [0 tEnd]); ylim(ax, [ylo yhi]);
        ylabel(ax, cfg.baseLabels{i}, 'FontSize', fs);
        if i > 6, xlabel(ax, 'Time (min)', 'FontSize', fs); end
    end
end
