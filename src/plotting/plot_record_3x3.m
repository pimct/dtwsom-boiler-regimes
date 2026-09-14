function fh = plot_record_3x3(dataset, segTbl, phase, usedChannels, ptitle, cfg, catList)
%PLOT_RECORD_3X3  3 x 3 grid of the nine signals shaded by a per-run label.
%   Channels used to train the classifier are marked with *** in the y-label.
    if nargin < 7 || isempty(catList), catList = categories(categorical(string(phase))); end
    S = segTbl;  S.Phase = categorical(string(phase), catList);
    labels = cfg.baseLabels;
    for i = 1:numel(labels)
        if ismember(i, usedChannels), labels{i} = [labels{i} ' ***']; end
    end
    C = parula(max(numel(catList),1));
    tmin = (0:height(dataset)-1)*cfg.sample_period_s/60;
    fh = figure('Color','w','Position',[100 100 1200 900]);
    tl = tiledlayout(3,3,'TileSpacing','compact','Padding','compact');
    title(tl, ptitle, 'FontWeight','bold');
    for i = 1:9
        nexttile; hold on;
        y = dataset.(cfg.baseNames{i});
        yl = [min(y) max(y)] + [-0.05 0.05]*range(y);
        for e = 1:height(S)
            k = find(strcmp(catList, char(S.Phase(e))), 1);
            patch([tmin(S.SegStart(e)) tmin(S.SegEnd(e)) tmin(S.SegEnd(e)) tmin(S.SegStart(e))], ...
                  [yl(1) yl(1) yl(2) yl(2)], C(k,:), 'FaceAlpha', 0.25, 'EdgeColor','none');
        end
        plot(tmin, y, 'Color', [0 0.25 0.5], 'LineWidth', 0.8);
        hold off; box on; set(gca,'Layer','top');
        xlim([0 tmin(end)]); ylim(yl);
        ylabel(labels{i}); if i > 6, xlabel('Time (min)'); end
    end
end
