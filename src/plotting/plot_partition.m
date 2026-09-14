function fh = plot_partition(dataset, split, cfg, channels)
%PLOT_PARTITION  Train / validation / test partition with purge gaps over the record.
    if nargin < 4, channels = [9 8]; end
    segTVT = runs2seg(split);
    segTVT.Phase = categorical(segTVT.Phase, {'train','val','test','gap'}, {'Train','Validation','Test','Gap'});
    splitMap = struct('Train',[0.00 0.45 0.74], 'Validation',[0.85 0.33 0.10], ...
                      'Test',[0.49 0.18 0.56], 'Gap',[0.80 0.80 0.80]);
    N = height(dataset); tmin = (0:N-1)*cfg.sample_period_s/60;
    fh = figure('Color','w','Position',[120 120 1100 700]);
    tiledlayout(numel(channels),1,'TileSpacing','compact','Padding','compact');
    for p = 1:numel(channels)
        nexttile; hold on;
        y = dataset.(cfg.baseNames{channels(p)});
        yl = [min(y) max(y)] + [-0.05 0.05]*range(y);
        for e = 1:height(segTVT)
            nm = char(segTVT.Phase(e));
            patch([tmin(segTVT.SegStart(e)) tmin(segTVT.SegEnd(e)) tmin(segTVT.SegEnd(e)) tmin(segTVT.SegStart(e))], ...
                  [yl(1) yl(1) yl(2) yl(2)], splitMap.(nm), 'FaceAlpha',0.25, 'EdgeColor','none');
        end
        plot(tmin, y, 'k-', 'LineWidth', 0.8);
        hold off; box on; grid on; ylim(yl); xlim([0 tmin(end)]);
        ylabel(cfg.baseLabels{channels(p)}); if p==numel(channels), xlabel('Time (min)'); end
        if p==1, title('Partition of the record: train / validation / test, with purge gaps'); end
    end
end
