%% Classifier baselines (Supplementary Table S3)
%  k-NN, random forest and a 1-D CNN trained on exactly the windows and
%  partition used by the LSTM (same build_windows call), reporting the same
%  metrics. Run after Stage A; the LSTM row is added from run_stage_b_lstm.

setup_paths(); clc; close all;
cfgL = lstm_config();
if ~exist(cfgL.outDir,'dir'), mkdir(cfgL.outDir); end
if cfgL.useReduced, tag = 'reduced'; else, tag = 'full'; end

%% 1. Identical windows and partition
R = load(cfgL.reportFile,'report');  cfg = R.report.cfg;
dataset = load_record(cfgL.rawFile, cfg);
Tlab = readtable(cfgL.labelFile);
win = build_windows(dataset, Tlab, cfg, cfgL);
K = win.K; classes = win.classes; w = win.w;
fprintf('Windows: %d train | %d val | %d test | %d channels, window %d samples\n', ...
    numel(win.idxTr), numel(win.idxVa), numel(win.idxTe), numel(win.cols), w);

xtrS = win.seq(win.idxTr);  xvaS = win.seq(win.idxVa);  xteS = win.seq(win.idxTe);
xtrF = win.flat(win.idxTr);                             xteF = win.flat(win.idxTe);
ytr  = win.label(win.idxTr); yva = win.label(win.idxVa); yte = win.label(win.idxTe);

evalRow = @(yp) class_metrics(confusionmat(yte, yp, 'Order', categorical(classes)));

%% 2. k-nearest neighbours
fprintf('\n--- k-NN (k = %d) ---\n', cfgL.knnK);
mdl = fitcknn(xtrF, ytr, 'NumNeighbors', cfgL.knnK, 'Distance', 'euclidean');
[a, ~, ~, ~, f, b, c] = evalRow(predict(mdl, xteF));
res_knn = summarise_metrics(sprintf('k-NN (k=%d)', cfgL.knnK), a, f, b, c);

%% 3. Random forest
fprintf('\n--- Random forest (%d trees) ---\n', cfgL.rfTrees);
acc = []; mf = []; ba = []; mc = [];
for m = 1:numel(cfgL.seeds)
    rng(cfgL.seeds(m));
    mdl = TreeBagger(cfgL.rfTrees, xtrF, ytr, 'Method','classification');
    yp  = categorical(string(predict(mdl, xteF)), classes);
    [a, ~, ~, ~, f, b, c] = evalRow(yp);
    acc(end+1)=a; mf(end+1)=f; ba(end+1)=b; mc(end+1)=c; %#ok<SAGROW>
    fprintf('  seed %d: acc %.4f | macro-F1 %.4f\n', cfgL.seeds(m), a, f);
end
res_rf = summarise_metrics(sprintf('Random forest (%d trees)', cfgL.rfTrees), acc, mf, ba, mc);

%% 4. One-dimensional CNN
fprintf('\n--- 1-D CNN ---\n');
acc = []; mf = []; ba = []; mc = [];
for m = 1:numel(cfgL.seeds)
    rng(cfgL.seeds(m));
    layers = [
        sequenceInputLayer(numel(win.cols), 'MinLength', w)
        convolution1dLayer(5, cfgL.cnnFilters(1), 'Padding','same')
        batchNormalizationLayer
        reluLayer
        maxPooling1dLayer(2, 'Stride', 2)
        convolution1dLayer(3, cfgL.cnnFilters(2), 'Padding','same')
        batchNormalizationLayer
        reluLayer
        globalAveragePooling1dLayer
        dropoutLayer(0.2)
        fullyConnectedLayer(K)
        softmaxLayer];
    opts = trainingOptions('adam', 'InitialLearnRate', cfgL.learnRate, 'L2Regularization', cfgL.l2, ...
        'MaxEpochs', cfgL.cnnMaxEpochs, 'MiniBatchSize', cfgL.miniBatch, 'Shuffle','every-epoch', ...
        'ValidationData', {xvaS, yva}, 'ValidationPatience', cfgL.patience, 'OutputNetwork','best-validation', ...
        'ExecutionEnvironment','auto', 'Verbose', false, 'Plots','none');
    net = trainnet(xtrS, ytr, layers, 'crossentropy', opts);
    yp  = predict_labels(net, xteS, classes, cfgL.miniBatch);
    [a, ~, ~, ~, f, b, c] = evalRow(yp);
    acc(end+1)=a; mf(end+1)=f; ba(end+1)=b; mc(end+1)=c; %#ok<SAGROW>
    fprintf('  seed %d: acc %.4f | macro-F1 %.4f\n', cfgL.seeds(m), a, f);
end
res_cnn = summarise_metrics('1-D CNN', acc, mf, ba, mc);

%% 5. Table S3
S3 = [struct2table(res_knn); struct2table(res_rf); struct2table(res_cnn)];
disp(' '); disp('Supplementary Table S3 (test set, same partition as the LSTM):'); disp(S3)
writetable(S3, fullfile(cfgL.outDir, sprintf('tableS3_classifier_baselines_%s_w%d.xlsx', tag, w)), ...
    'WriteMode','overwritesheet');
save(fullfile(cfgL.outDir, sprintf('baselines_%s_w%d.mat', tag, w)), 'S3', 'cfgL');
fprintf('\nAdd the LSTM row from run_stage_b_lstm to complete Supplementary Table S3.\n');
