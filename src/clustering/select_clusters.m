function [nodeLab, K, Ktab, info] = select_clusters(W, X, bmuIdx, Dseg, cfg)
%SELECT_CLUSTERS  Cluster SOM prototypes into operating regimes and choose K.
%   [nodeLab, K, Ktab, info] = SELECT_CLUSTERS(W, X, bmuIdx, Dseg, cfg)
%
%   * Only nodes that are the BMU of at least one segment ("active") are
%     clustered; dead nodes inherit the label of their nearest active node
%     (used for plotting only).
%   * For every K in cfg.Krange the hierarchical tree of the active prototypes
%     is cut, segments are labelled through their BMU, clusters with fewer than
%     cfg.minSegPerCluster segments are merged into the nearest regime, and a
%     diagnostics table (Ktab) is built: node- and segment-level silhouette,
%     Davies-Bouldin, number of regimes after merging, largest episode count
%     per regime and smallest regime size.
%   * The reported partition is chosen by cfg.Kselect:
%       'silhouette'              max segment silhouette
%       'silhouette_constrained'  as above, restricted to >= cfg.Kmin regimes
%                                 each with <= cfg.maxEpisodesPerCluster episodes
%       'contiguity'              largest K whose regimes are all temporally compact
%       'twolevel'                macro-states first, then sub-regimes per macro-state
%       'fixed'                   cfg.K_fixed clusters (exploration only)
%
%   info.Z, info.active, info.Dn describe the tree; info.K_cut is the cut of the
%   selected partition (before merging); info.cut_height is the midpoint of the
%   linkage-height interval that produces it.

    band = cfg.dtw.band; numNeurons = numel(W); nSeg = numel(X);
    hits = accumarray(bmuIdx, 1, [numNeurons 1]); active = find(hits > 0);
    DnodeAll = pair_dist(W, 'dtw', band); Dn = DnodeAll(active, active);
    Z = linkage(squareform(Dn), cfg.linkage);
    Ks = cfg.Krange(cfg.Krange <= numel(active) - 1);
    labFrom = @(idxA) seg_labels(idxA, active, numNeurons, bmuIdx);
    n = numel(Ks); Keff = zeros(n,1); silN = Keff; silS = Keff; dbS = Keff; maxEpi = Keff; minSz = Keff;
    labAll = zeros(nSeg, n);
    for t = 1:n
        idxA = cluster(Z, 'maxclust', Ks(t)); lab = labFrom(idxA);
        lab = merge_small_clusters(lab, Dseg, cfg.minSegPerCluster);
        labAll(:,t) = lab;
        u = unique(lab); Keff(t) = numel(u);
        silN(t) = mean(silhouette([], idxA, squareform(Dn)));
        if Keff(t) > 1
            silS(t) = mean(silhouette([], lab, squareform(Dseg))); dbS(t) = davies_bouldin(Dseg, lab);
        else
            silS(t) = NaN; dbS(t) = NaN;
        end
        maxEpi(t) = max(episodes_per_cluster(lab)); minSz(t) = min(histcounts(lab, [u; max(u)+1]));
    end
    Ktab = table(Ks', Keff, silN, silS, dbS, maxEpi, minSz, 'VariableNames', ...
        {'K_cut','K_after_merge','Sil_nodes','Sil_segments','DB_segments','MaxEpisodesPerCluster','MinSegments'});
    info.labAll = labAll; info.active = active; info.hits = hits; info.Z = Z; info.Dn = Dn;

    b = NaN;
    switch cfg.Kselect
        case 'silhouette'
            [~, b] = max(silS); K = Keff(b);
            idxA = nodes_from_segments(labAll(:,b), active, bmuIdx);
        case 'silhouette_constrained'
            ok = Keff >= cfg.Kmin & maxEpi <= cfg.maxEpisodesPerCluster;
            if ~any(ok), ok = true(n,1); end
            sc = silS; sc(~ok) = -inf; [~, b] = max(sc);
            K = Keff(b); idxA = nodes_from_segments(labAll(:,b), active, bmuIdx);
        case 'contiguity'
            ok = maxEpi <= cfg.maxEpisodesPerCluster;
            if ~any(ok), ok(1) = true; end
            b = find(Keff == max(Keff(ok)), 1); K = Keff(b);
            idxA = nodes_from_segments(labAll(:,b), active, bmuIdx);
        case 'twolevel'
            idx1 = cluster(Z, 'maxclust', cfg.K_level1); idxA = zeros(numel(active),1); next = 0;
            info.level2 = table('Size',[0 4],'VariableTypes',{'double','double','double','double'}, ...
                                'VariableNames',{'MacroState','nSegments','SubK','SubSilhouette'});
            for m = 1:cfg.K_level1
                nodes_m = find(idx1 == m); segs_m = find(ismember(bmuIdx, active(nodes_m)));
                km = 1; bestS = cfg.subSilMin; imBest = ones(numel(nodes_m),1);
                if numel(nodes_m) >= 2 && numel(segs_m) >= 2*cfg.minSegPerCluster
                    Zm = linkage(squareform(Dn(nodes_m, nodes_m)), cfg.linkage);
                    for k = 2:min(cfg.subKmax, numel(nodes_m))
                        im = cluster(Zm, 'maxclust', k);
                        nodeLab_m = zeros(numNeurons,1); nodeLab_m(active(nodes_m)) = im;
                        labm = nodeLab_m(bmuIdx(segs_m));
                        cnts = histcounts(labm, 0.5:1:k+0.5);
                        if any(cnts < cfg.minSegPerCluster), continue; end
                        if max(episodes_per_cluster(labm)) > cfg.maxEpisodesPerCluster, continue; end
                        sk = mean(silhouette([], labm, squareform(Dseg(segs_m, segs_m))));
                        if sk > bestS, bestS = sk; km = k; imBest = im; end
                    end
                end
                idxA(nodes_m) = next + imBest; next = next + km;
                info.level2 = [info.level2; {m, numel(segs_m), km, bestS*(km>1)}];
            end
            K = next;
        case 'fixed'
            K = cfg.K_fixed; idxA = cluster(Z, 'maxclust', K);
        otherwise
            error('Unknown cfg.Kselect ''%s''', cfg.Kselect);
    end
    nodeLab = zeros(numNeurons,1); nodeLab(active) = idxA;
    dead = find(hits == 0);
    if ~isempty(dead), [~, j] = min(DnodeAll(dead, active), [], 2); nodeLab(dead) = idxA(j); end
    info.K_by_rule = K; info.K_effective = numel(unique(nodeLab(bmuIdx)));

    % cut height of the selected partition (midpoint between consecutive merges)
    if ~isnan(b)
        info.K_cut = Ks(b);
        h = sort(Z(:,3)); i = numel(active) - info.K_cut;
        if i >= 1 && i < numel(h)
            info.cut_interval = [h(i) h(i+1)]; info.cut_height = mean(info.cut_interval);
        end
    end
end
