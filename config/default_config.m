function cfg = default_config()
%DEFAULT_CONFIG  Configuration of the DTW-SOM regime-discovery stage (Stage A).
%   Values are those of the reported run. Change them here, not in the scripts.

% ---- data -----------------------------------------------------------------
cfg.seed            = 0;
cfg.dataFile        = fullfile('data', 'rawdata.csv');   % see data/README.md
cfg.sample_period_s = 5;        % sampling interval of the DCS export
cfg.segment_size    = 60;       % 60 x 5 s = 5-min segment
cfg.stride          = 60;       % non-overlapping segments

% Standard column names given to the nine process variables (in the order of
% the CSV columns) and the axis labels used in the figures
cfg.baseNames  = {'InletGasPressurebar','InletGasTempC','InletGasFlowkgh','FeedWaterTempC', ...
                  'SteamPressurebar','SteamTempC','SteamFlowkgh','ExhaustGasOxygen','ExhaustGasTempC'};
cfg.baseLabels = {'Inlet gas pressure (bar)','Inlet gas temperature (°C)','Inlet gas flow (kg/h)', ...
                  'Feed water temperature (°C)','Steam pressure (bar)','Steam temperature (°C)', ...
                  'Steam flow (kg/h)','Exhaust gas O_2 (%)','Exhaust gas temperature (°C)'};
cfg.select_sensors = cfg.baseNames;   % variables used by the DTW-SOM (all nine)

% ---- normalisation --------------------------------------------------------
% 'range' with cfg.ranges = [min max] per selected sensor uses fixed instrument
% ranges (no data leakage). Leave cfg.ranges empty to fall back to full-record
% min-max, which is what the descriptive regime-discovery stage uses.
cfg.norm.mode = 'range';
cfg.ranges    = [];

% ---- SOM ------------------------------------------------------------------
cfg.somSize        = [10 10];
cfg.numEpochs      = 2000;      % upper bound; training stops on the QE plateau
cfg.scheduleEpochs = 800;       % alpha/sigma decay over this horizon, then constant
cfg.schedule       = 'exp';     % 'exp' | 'linear'
cfg.alpha0 = 0.5;   cfg.alphaEnd = 0.005;
cfg.sigma0 = max(cfg.somSize)/2;  cfg.sigmaEnd = 0.5;
cfg.stop.window = 100;          % QE plateau test: mean over the last 'window'
cfg.stop.relTol = 0.01;         % epochs changes < relTol vs the window before
cfg.loadModel   = false;        % true = reuse results/dtwsom_model.mat

% ---- DTW ------------------------------------------------------------------
cfg.dtw.band     = 0;           % 0 = unconstrained; e.g. 0.10 for a Sakoe-Chiba band
cfg.dtw.variant  = 'classic DTW, unconstrained, |.| local cost, symmetric steps';
cfg.dtw.multivar = 'independent: per-channel DTW summed over channels';

% ---- regime-count selection (see select_clusters) -------------------------
cfg.linkage               = 'average';   % Ward is invalid for non-Euclidean distances
cfg.Krange                = 2:15;
cfg.Kselect               = 'silhouette_constrained';  % | 'silhouette' | 'contiguity' | 'twolevel' | 'fixed'
cfg.Kmin                  = 5;
cfg.minSegPerCluster      = 3;   % clusters with fewer segments are merged into the nearest regime
cfg.maxEpisodesPerCluster = 3;   % a regime may recur at most this many times
cfg.K_level1  = 2;  cfg.subKmax = 5;  cfg.subSilMin = 0.25;   % 'twolevel' only
cfg.K_fixed   = 7;                                            % 'fixed' only

% ---- partition exported for Stage B ----------------------------------------
cfg.lstm.window         = 12;            % rows; only used for the window-count table
cfg.lstm.frac           = [0.6 0.2 0.2]; % train / val / test, in time order within each episode
cfg.lstm.purge          = 12;            % rows removed at each internal boundary
cfg.lstm.minEpisodeRows = 3*cfg.lstm.window;   % shorter episodes go entirely to train

% ---- robustness -------------------------------------------------------------
cfg.runBaselines    = true;
cfg.runStability    = true;
cfg.stabilitySeeds  = 1:5;
cfg.stabilityEpochs = cfg.numEpochs;

% ---- output ------------------------------------------------------------------
cfg.outDir = 'results';
end
