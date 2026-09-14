%% Stage B - LSTM regime classifier trained on the DTW-SOM labels
%  Builds trailing windows inside the per-episode temporal partition exported
%  by Stage A, trains one LSTM per seed, and reports overall and class-wise
%  test metrics (Tables 4-6) and the confusion charts (Fig. 6).
%
%  Set cfgL.useReduced = true in config/lstm_config.m for the four-sensor model
%  and cfgL.window = 12 for the 1-min comparison.

setup_paths(); clc; close all;
cfgL = lstm_config();
if ~exist(cfgL.outDir,'dir'), mkdir(cfgL.outDir); end
if cfgL.useReduced, tag = 'reduced'; else, tag = 'full'; end
cfgL.modelFile = fullfile(cfgL.outDir, sprintf('lstm_models_%s_w%d.mat', tag, cfgL.window));

%% 1. Load the Stage-A outputs and build the windows
R = load(cfgL.reportFile,'report');  cfg = R.report.cfg;
dataset = load_record(cfgL.rawFile, cfg);
Tlab = readtable(cfgL.labelFile);

win = build_windows(dataset, Tlab, cfg, cfgL);
K = win.K; classes = win.classes; w = win.w;
fprintf('Loaded %d samples, %d regimes, window %d samples (%d s)\n', win.N, K, w, w*cfg.sample_period_s);
fprintf('Windows: %d train | %d val | %d test (%d rows purged)\n', ...
    numel(win.idxTr), numel(win.idxVa), numel(win.idxTe), sum(win.rowSplit=="gap"));
disp('Windows per regime and partition (Table 4):'); disp(win.counts)
writetable(win.counts, fullfile(cfgL.outDir, sprintf('lstm_window_counts_w%d.xlsx', w)), ...
    'WriteRowNames', true, 'WriteMode','overwritesheet');

xtrain = win.seq(win.idxTr); ytrain = win.label(win.idxTr);
xval   = win.seq(win.idxVa); yval   = win.label(win.idxVa);
xtest  = win.seq(win.idxTe); ytest  = win.label(win.idxTe);
nCh = numel(win.cols);

%% 2. Partition figure
plot_partition(dataset, win.rowSplit, cfg);
exportgraphics(gcf, fullfile(cfgL.outDir,'figS4_partition.png'), 'Resolution', 300);

%% 3. Train (or load from the cache)
M = numel(cfgL.seeds); cacheValid = false;
if ~cfgL.retrain && isfile(cfgL.modelFile)
    S = load(cfgL.modelFile);
    cacheValid = isequal(S.meta.classes, classes) && isequal(S.meta.seeds, cfgL.seeds) && ...
                 S.meta.nChannels == nCh && S.meta.window == w && ...
                 isequal(S.meta.counts, [numel(win.idxTr) numel(win.idxVa) numel(win.idxTe)]);
    if cacheValid
        nets = S.nets; tTrainAll = S.tTrainAll;
        fprintf('Loaded %d networks from %s; training skipped.\n', numel(nets), cfgL.modelFile);
    else
        warning('Cached models in %s do not match the current data or settings; retraining.', cfgL.modelFile);
    end
end
if ~cacheValid
    nets = cell(M,1); tTrainAll = zeros(M,1);
    for m = 1:M
        rng(cfgL.seeds(m));
        [nets{m}, tTrainAll(m)] = train_lstm(xtrain, ytrain, xval, yval, nCh, classes, cfgL);
        fprintf('seed %d trained in %.0f s\n', cfgL.seeds(m), tTrainAll(m));
    end
    meta = struct('classes', {classes}, 'seeds', cfgL.seeds, 'nChannels', nCh, 'window', w, ...
                  'counts', [numel(win.idxTr) numel(win.idxVa) numel(win.idxTe)], 'cfgL', cfgL, 'saved', datetime('now'));
    save(cfgL.modelFile, 'nets', 'tTrainAll', 'meta', '-v7.3');
end

%% 4. Evaluate on the test partition
acc = zeros(M,1); macroF1 = zeros(M,1); balAcc = zeros(M,1); mcc = zeros(M,1);
P = zeros(M,K); Rc = zeros(M,K); F1 = zeros(M,K); inferMs = zeros(M,1);
CMte = zeros(K); bestF1 = -inf; netBest = []; seedBest = NaN;
for m = 1:M
    predict_labels(nets{m}, xtest(1), classes, cfgL.miniBatch);           % warm-up, not timed
    tI = tic; yp_te = predict_labels(nets{m}, xtest, classes, cfgL.miniBatch);
    inferMs(m) = 1000*toc(tI)/numel(xtest);
    cm = confusionmat(ytest, yp_te, 'Order', categorical(classes)); CMte = CMte + cm;
    [acc(m), P(m,:), Rc(m,:), F1(m,:), macroF1(m), balAcc(m), mcc(m)] = class_metrics(cm);
    fprintf('seed %d: acc %.4f | macro-F1 %.4f | bal.acc %.4f | MCC %.4f\n', ...
        cfgL.seeds(m), acc(m), macroF1(m), balAcc(m), mcc(m));
    if macroF1(m) > bestF1, bestF1 = macroF1(m); netBest = nets{m}; seedBest = cfgL.seeds(m); end
end
ms = @(v) sprintf('%.4f +/- %.4f', mean(v), std(v));
fprintf('\n%s model (%d sensors, %d-row windows): accuracy %s | macro-F1 %s | balanced accuracy %s | MCC %s\n', ...
    tag, nCh, w, ms(acc), ms(macroF1), ms(balAcc), ms(mcc));
fprintf('training %.0f +/- %.0f s per seed | inference %.4f +/- %.4f ms per window\n', ...
    mean(tTrainAll), std(tTrainAll), mean(inferMs), std(inferMs));
nParams = sum(cellfun(@numel, netBest.Learnables.Value));
fprintf('trainable parameters: %d\n', nParams);

perClass = table(classes, win.counts.Test, mean(P,1,'omitnan')', mean(Rc,1)', mean(F1,1)', std(F1,0,1)', ...
    'VariableNames', {'Regime','TestWindows','Precision','Recall','F1','F1_SD'});
disp('Class-wise test metrics, mean over seeds (Table 4):'); disp(perClass)
writetable(perClass, fullfile(cfgL.outDir, sprintf('lstm_classwise_%s_w%d.xlsx', tag, w)), 'WriteMode','overwritesheet');

%% 5. Confusion charts (Fig. 6) for the best seed and the seed-averaged test matrix
yp_tr = predict_labels(netBest, xtrain, classes, cfgL.miniBatch);
yp_va = predict_labels(netBest, xval,   classes, cfgL.miniBatch);
yp_te = predict_labels(netBest, xtest,  classes, cfgL.miniBatch);
figure('Color','w','Position',[100 100 700 1000]);
subplot(3,1,1); confusionchart(ytrain, yp_tr); title(sprintf('Training (%s model, seed %d)', tag, seedBest));
subplot(3,1,2); confusionchart(yval,   yp_va); title('Validation');
subplot(3,1,3); confusionchart(ytest,  yp_te); title('Test');
exportgraphics(gcf, fullfile(cfgL.outDir, sprintf('fig06_confusion_%s_w%d.png', tag, w)), 'Resolution', 300);
fprintf('Best seed %d: train %.2f%% | val %.2f%% | test %.2f%%\n', seedBest, ...
    100*mean(yp_tr==ytrain), 100*mean(yp_va==yval), 100*mean(yp_te==ytest));

figure('Color','w'); confusionchart(round(CMte/M), classes, 'RowSummary','row-normalized');
title(sprintf('Test set, mean of %d seeds', M));
exportgraphics(gcf, fullfile(cfgL.outDir, sprintf('fig06_confusion_mean_%s_w%d.png', tag, w)), 'Resolution', 300);

%% 6. Supervised classification over the whole record
% Every window labels its last row; rows without a window (leading rows and
% purge gaps) inherit the previous prediction.
ypAll = predict_labels(netBest, win.seq(1:numel(win.ends)), classes, cfgL.miniBatch);
predRow = strings(win.N,1); predRow(win.ends) = string(ypAll); last = "";
for r = 1:win.N
    if predRow(r) == "", predRow(r) = last; else, last = predRow(r); end
end
predRow(predRow=="") = string(win.rowLabel(predRow==""));
segPRED = runs2seg(predRow);
plot_record_3x3(dataset, segPRED, segPRED.Phase, win.cols, ...
    'Supervised LSTM classification using DTW-SOM regime labels', cfg, classes);
exportgraphics(gcf, fullfile(cfgL.outDir, sprintf('figS5_supervised_record_%s_w%d.png', tag, w)), 'Resolution', 300);
fprintf('Sample-level agreement with the DTW-SOM labels: %.2f%%\n', 100*mean(categorical(predRow) == win.rowLabel));

save(fullfile(cfgL.outDir, sprintf('lstm_results_%s_w%d.mat', tag, w)), 'cfgL', 'acc', 'macroF1', 'balAcc', ...
     'mcc', 'perClass', 'CMte', 'tTrainAll', 'inferMs', 'nParams', 'seedBest');
