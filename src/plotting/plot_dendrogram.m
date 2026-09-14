function fh = plot_dendrogram(cinfo, clusterIdx, ClusterMap, K, cfg)
%PLOT_DENDROGRAM  Fig. 3: average-linkage tree of the active prototypes.
%   Leaves are labelled "node|regime"; the dashed line is the cut of the
%   selected partition (cinfo.cut_height), placed midway between the two
%   consecutive merges that bracket it.
    fh = figure('Color','w','Position',[100 100 900 450]);
    [~, ~, perm] = dendrogram(cinfo.Z, 0);
    leafLab = arrayfun(@(a) sprintf('%d|%s', cinfo.active(a), ClusterMap(clusterIdx(cinfo.active(a)))), ...
                       perm, 'UniformOutput', false);
    set(gca, 'XTickLabel', leafLab, 'XTickLabelRotation', 90, 'FontSize', 7);
    if isfield(cinfo,'cut_height')
        yline(cinfo.cut_height, '--', 'Color', [0.85 0.1 0.3], 'LineWidth', 1);
    end
    xlabel('SOM node | regime'); ylabel('DTW distance (summed over channels)');
    title(sprintf('Hierarchical clustering of active SOM prototypes (%s linkage, K = %d)', cfg.linkage, K));
end
