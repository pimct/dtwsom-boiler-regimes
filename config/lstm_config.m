function cfgL = lstm_config()
%LSTM_CONFIG  Configuration shared by the LSTM stage and the classifier baselines.

cfgL.outDir     = 'results';
cfgL.rawFile    = fullfile('data', 'rawdata.csv');
cfgL.labelFile  = fullfile('results', 'labeldataset.xlsx');   % written by Stage A
cfgL.reportFile = fullfile('results', 'results_report.mat');

cfgL.select_sensors  = {'InletGasPressurebar','InletGasTempC','InletGasFlowkgh','FeedWaterTempC', ...
                        'SteamPressurebar','SteamTempC','SteamFlowkgh','ExhaustGasOxygen','ExhaustGasTempC'};
cfgL.reduced_sensors = {'SteamTempC','SteamFlowkgh','ExhaustGasOxygen','ExhaustGasTempC'};   % four-sensor model
cfgL.useReduced      = false;          % true = four-sensor model

cfgL.window = 36;                      % 36 = 3-min windows (reported); 12 = 1-min
cfgL.seeds  = [8 16 25];               % network initialisations

% LSTM
cfgL.numLSTMLayers = 2;
cfgL.hiddenUnits   = 12;
cfgL.maxEpochs     = 1000;
cfgL.miniBatch     = 128;
cfgL.patience      = 15;
cfgL.learnRate     = 1e-3;
cfgL.l2            = 1e-4;
cfgL.classWeights  = true;
cfgL.retrain       = false;            % true = ignore the model cache

% Classifier baselines (Supplementary Table S3)
cfgL.knnK         = 5;
cfgL.rfTrees      = 200;
cfgL.cnnFilters   = [16 32];
cfgL.cnnMaxEpochs = 200;

% optional overrides set by scripts/run_all.m
global LSTM_CONFIG_OVERRIDE %#ok<GVMIS>
if ~isempty(LSTM_CONFIG_OVERRIDE)
    for f = fieldnames(LSTM_CONFIG_OVERRIDE)', cfgL.(f{1}) = LSTM_CONFIG_OVERRIDE.(f{1}); end
end
end
