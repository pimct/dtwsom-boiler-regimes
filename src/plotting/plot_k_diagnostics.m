function fh = plot_k_diagnostics(Ktab, K)
%PLOT_K_DIAGNOSTICS  Supplementary Fig. S2: cluster-count diagnostics versus cut K.
    fh = figure('Color','w'); tiledlayout(1,2);
    nexttile; plot(Ktab.K_cut, Ktab.Sil_nodes, '-o', Ktab.K_cut, Ktab.Sil_segments, '-s'); grid on;
    xlabel('K (hierarchical cut, before merging)'); ylabel('Mean silhouette (DTW)');
    legend('SOM nodes','Segments','Location','best');
    nexttile; yyaxis left; plot(Ktab.K_cut, Ktab.DB_segments, '-o'); ylabel('Davies-Bouldin (segments)');
    yyaxis right; plot(Ktab.K_cut, Ktab.MaxEpisodesPerCluster, '-s'); ylabel('Max episodes per regime'); grid on;
    xlabel('K (hierarchical cut, before merging)');
    sgtitle(sprintf('Cluster-count diagnostics (reported K = %d)', K));
end
