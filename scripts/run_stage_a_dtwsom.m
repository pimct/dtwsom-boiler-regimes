%% Stage A - DTW-SOM regime discovery
%  Trains the DTW-SOM on non-overlapping 5-min segments, clusters the active
%  prototypes into operating regimes, exports the regime labels and the
%  leakage-resistant partition for Stage B, and produces Figs 2-5 and
%  Supplementary Tables S1-S2.
%
%  Inputs : data/rawdata.csv (see data/README.md)
%  Outputs: results/dtwsom_model.mat, results/results_report.mat,
%           results/episodes.xlsx, results/segments.xlsx,
%           results/labeldataset.xlsx, results/tableS1_k_diagnostics.xlsx,
%           results/tableS2_clustering_baselines.xlsx, figures in results/

setup_paths(); clc; close all;
cfg = default_config();
if ~exist(cfg.outDir,'dir'), mkdir(cfg.outDir); end
rng(cfg.seed);
dataset = load_record(cfg.dataFile, cfg);

%% 1. Segmentation and normalisation
[Xraw, seg] = prep_segments(dataset, cfg.select_sensors, cfg.segment_size, cfg.stride);
nSeg = numel(Xraw);  L = size(Xraw{1},2);  D = size(Xraw{1},1);
fprintf('Data: %d rows @ %d s (%.1f h) -> %d non-overlapping segments of %d samples (%d min)\n', ...
    height(dataset), cfg.sample_period_s, height(dataset)*cfg.sample_period_s/3600, ...
    nSeg, L, L*cfg.sample_period_s/60);
[X, normInfo] = normalise_segments(Xraw, dataset, cfg);
cfg.norm = normInfo;
fprintf('Normalisation: min-max to [0,1], %s\n', normInfo.fitted_on);

%% 2. Train the DTW-SOM (or load a saved model)
modelFile = fullfile(cfg.outDir, 'dtwsom_model.mat');
if cfg.loadModel && isfile(modelFile)
    S = load(modelFile, 'W', 'W_snap', 'trainLog');
    W = S.W; W_snap = S.W_snap; trainLog = S.trainLog; timing.train_s = NaN;
    fprintf('Loaded saved prototypes (%d neurons); training skipped\n', numel(W));
else
    tTrain = tic;
    [W, W_snap, trainLog] = train_som(X, cfg, 'dtw');
    timing.train_s = toc(tTrain);
    save(modelFile, 'W', 'W_snap', 'cfg', 'trainLog', 'seg');
end
plot_training_curve(trainLog);
exportgraphics(gcf, fullfile(cfg.outDir,'figS1_training_curve.png'), 'Resolution', 300);

%% 3. BMU assignment and regime-count selection
numNeurons = numel(W);
[bmuIdx, bmu2Idx, qErr] = predict_bmu(X, W, 'dtw', cfg.dtw.band);
positions = grid_positions(cfg.somSize);
Dseg = pair_dist(X, 'dtw', cfg.dtw.band);                  % segment-level DTW matrix

[clusterIdx, K, Ktab, cinfo] = select_clusters(W, X, bmuIdx, Dseg, cfg);
fprintf('Active nodes: %d of %d (dead nodes inherit the nearest active label)\n', numel(cinfo.active), numNeurons);
disp('Candidate partitions (Supplementary Table S1):'); disp(Ktab)
[~, bAll] = max(Ktab.Sil_segments);
fprintf('Global segment-silhouette optimum: %d regimes\n', Ktab.K_after_merge(bAll));
fprintf('Selected K = %d by rule ''%s''', K, cfg.Kselect);
if isfield(cinfo,'K_cut'), fprintf(' (cut at %d clusters', cinfo.K_cut);
    if isfield(cinfo,'cut_height'), fprintf(', height %.1f in [%.1f, %.1f]', cinfo.cut_height, cinfo.cut_interval); end
    fprintf(')');
end
fprintf('; clusters with < %d segments merged into the nearest regime\n', cfg.minSegPerCluster);
writetable(Ktab, fullfile(cfg.outDir,'tableS1_k_diagnostics.xlsx'), 'WriteMode','overwritesheet');

lab0 = clusterIdx(bmuIdx);
quality.K_table      = Ktab;
quality.sil_segments = mean(silhouette([], lab0, squareform(Dseg)));
quality.DB_segments  = davies_bouldin(Dseg, lab0);
quality.QE = mean(qErr);
quality.TE = mean(max(abs(positions(bmuIdx,:) - positions(bmu2Idx,:)), [], 2) > 1);

%% 4. Labels and episodes
yp = clusterIdx(bmuIdx);
[oldIDs, ia, newIdx] = unique(yp, 'stable');               % regimes numbered in order of first appearance
clusterNames = categorical(arrayfun(@(c) sprintf('Cluster%d', c), newIdx, 'UniformOutput', false));
ClusterMap = containers.Map(oldIDs, cellstr(clusterNames(ia)));
seg.BMU_Index = bmuIdx; seg.ClusterLabel = yp; seg.ClusterName = clusterNames; seg.QuantError = qErr;

epi = episode_table(clusterNames, seg, nSeg, cfg.sample_period_s);
disp('Regime episodes in time order (Table 3 / Fig. 4):'); disp(epi)
writetable(epi, fullfile(cfg.outDir,'episodes.xlsx'), 'WriteMode','overwritesheet');

pp = repelem(clusterNames, L);                              % sample-level labels
n_tail = height(dataset) - numel(pp);
if n_tail > 0, pp = [pp; repmat(pp(end),n_tail,1)]; else, pp = pp(1:height(dataset)); end
dataset.ClusterLabeled = pp;

%% 5. Leakage-resistant partition for Stage B
dataset.Split = categorical(make_partition(epi, height(dataset), cfg.lstm));
writetable(dataset, fullfile(cfg.outDir,'labeldataset.xlsx'), 'WriteMode','overwritesheet');
writetable(seg,     fullfile(cfg.outDir,'segments.xlsx'),     'WriteMode','overwritesheet');
[cntNonOverlap, cntStride1] = window_counts(dataset, cfg.lstm.window);
fprintf('%d-row windows per regime and partition: non-overlapping\n', cfg.lstm.window); disp(cntNonOverlap)
disp('... and with stride 1 inside each partition:'); disp(cntStride1)
writetable(cntStride1, fullfile(cfg.outDir,'window_counts_stageA.xlsx'), 'WriteMode','overwritesheet');

%% 6. Clustering baselines (Supplementary Table S2)
if cfg.runBaselines
    base = run_baselines(X, Dseg, W, newIdx, K, cfg);
    disp('Clustering baselines (same segments, same K):'); disp(base)
    writetable(base, fullfile(cfg.outDir,'tableS2_clustering_baselines.xlsx'), 'WriteMode','overwritesheet');
end

%% 7. Stability across seeds
if cfg.runStability
    stability = run_stability(X, Dseg, cfg, newIdx);
    fprintf('Stability: K per seed = [%s] | mean pairwise ARI = %.3f | ARI vs reported = [%s]\n', ...
        num2str(stability.K_per_seed), stability.ARI_mean, num2str(stability.ARI_vs_main, '%.2f '));
    stabTab = table(stability.seeds(:), stability.K_per_seed(:), stability.ARI_vs_main(:), ...
        'VariableNames', {'Seed','K','ARI_vs_reported'});
    writetable(stabTab, fullfile(cfg.outDir,'tableS2_seed_stability.xlsx'), 'WriteMode','overwritesheet');
end

%% 8. Report
tInf = tic; predict_bmu(X, W, 'dtw', cfg.dtw.band); timing.infer_per_segment_ms = 1000*toc(tInf)/nSeg;
report.cfg = cfg; report.timing = timing; report.quality = quality; report.K = K; report.episodes = epi;
report.cluster_info = cinfo; report.trainLog = trainLog;
report.timing.window_s = L*cfg.sample_period_s;
report.timing.realtime_margin = report.timing.window_s/(timing.infer_per_segment_ms/1000);
report.env.matlab = version; report.env.computer = computer;
try, report.env.cpu = feature('GetCPU'); catch, end
try, report.env.cores = feature('numcores'); catch, end
if cfg.runBaselines, report.baselines = base; end
if cfg.runStability, report.stability = stability; end
save(fullfile(cfg.outDir,'results_report.mat'), 'report');
fprintf('K = %d | QE = %.3f | TE = %.3f | %d epochs, training %.0f s | inference %.2f ms per %d-s segment\n', ...
    K, quality.QE, quality.TE, trainLog.epochsRun, timing.train_s, timing.infer_per_segment_ms, report.timing.window_s);

%% 9. Figures
plot_dendrogram(cinfo, clusterIdx, ClusterMap, K, cfg);
exportgraphics(gcf, fullfile(cfg.outDir,'fig03_dendrogram.svg'), 'ContentType','vector');
exportgraphics(gcf, fullfile(cfg.outDir,'fig03_dendrogram.png'), 'Resolution', 300);

plot_k_diagnostics(Ktab, K);
exportgraphics(gcf, fullfile(cfg.outDir,'figS2_k_diagnostics.png'), 'Resolution', 300);

figure('Color','w'); imagesc(reshape(clusterIdx, cfg.somSize)); axis equal tight; colorbar;
title('SOM grid coloured by regime'); xlabel('column'); ylabel('row');
exportgraphics(gcf, fullfile(cfg.outDir,'figS3_som_grid.png'), 'Resolution', 300);

plot_record_regimes(dataset, epi, cfg);
exportgraphics(gcf, fullfile(cfg.outDir,'fig04_record_regimes.svg'), 'ContentType','vector');
exportgraphics(gcf, fullfile(cfg.outDir,'fig04_record_regimes.png'), 'Resolution', 300);

files = plot_regime_prototypes(X, W, clusterIdx, bmuIdx, K, ClusterMap, normInfo, cfg, cfg.outDir);
fprintf('Wrote %d regime figures (Fig. 5)\n', numel(files));

plot_alignment(X, W, W_snap, clusterIdx, bmuIdx, trainLog, cfg, ClusterMap, 5, 1, 3, 9);   % Fig. 2
exportgraphics(gcf, fullfile(cfg.outDir,'fig02_dtw_alignment.png'), 'Resolution', 300);
