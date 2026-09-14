function [W, W_snap, log] = train_som(X, cfg, distMode)
%TRAIN_SOM  Train a DTW-SOM (or Euclidean SOM) on a cell array of segments.
%   [W, W_snap, log] = TRAIN_SOM(X, cfg, distMode)
%   X        : nS x 1 cell of [D x L] normalised segments
%   cfg      : configuration struct (see config/default_config.m)
%   distMode : 'dtw' | 'euclidean'
%   W        : nN x 1 cell of [D x L] prototypes
%   W_snap   : prototypes ~50 epochs before the stop (for the alignment figure)
%   log      : QE and mean prototype change per epoch, epochsRun, final alpha/sigma
%
% Per epoch, for every sample x in shuffled order:
%   1. d_j = sum_c DTW(x_c, w_jc)  (or Euclidean)          -> BMU = argmin_j d_j
%   2. h_j = exp(-||r_j - r_BMU||^2 / (2 sigma^2))          (Gaussian on the grid)
%   3. x~_j = x warped onto w_j's time axis along the optimal DTW path
%      (mean of the x values mapped to each prototype index), then
%      w_j <- w_j + alpha h_j (x~_j - w_j)
% alpha and sigma decay (exponentially or linearly) over cfg.scheduleEpochs and
% then stay at their end values. Training stops when the mean quantisation
% error over the last cfg.stop.window epochs changes by less than
% cfg.stop.relTol relative to the preceding window, checked only after the
% schedule horizon. All DTW work is done in dtw_batch (one vectorised DP
% against every neuron and channel).

    nS = numel(X); L = size(X{1},2); D = size(X{1},1);
    positions = grid_positions(cfg.somSize); nN = size(positions,1);
    Wm = cell2mat(reshape(cellfun(@(a) reshape(a,[1 D L]), X(randi(nS,nN,1)), ...
                  'UniformOutput', false), [nN 1]));          % [nN x D x L]
    hist = cell(51,1);                                         % rolling buffer -> snapshot
    log.QE = nan(cfg.numEpochs,1); log.dW = nan(cfg.numEpochs,1);
    hTol = 1e-3; isDTW = strcmp(distMode,'dtw'); band = cfg.dtw.band;
    fprintf('%s-SOM: %d neurons, D=%d, L=%d, %d train segments, up to %d epochs\n', ...
        upper(distMode), nN, D, L, nS, cfg.numEpochs);
    epochsRun = cfg.numEpochs; alpha = cfg.alpha0; sigma = cfg.sigma0;
    for epoch = 1:cfg.numEpochs
        t = min((epoch-1)/max(cfg.scheduleEpochs-1,1), 1);
        if strcmp(cfg.schedule,'exp')
            alpha = cfg.alpha0*(cfg.alphaEnd/cfg.alpha0)^t;
            sigma = cfg.sigma0*(cfg.sigmaEnd/cfg.sigma0)^t;
        else
            alpha = cfg.alpha0 + t*(cfg.alphaEnd-cfg.alpha0);
            sigma = cfg.sigma0 + t*(cfg.sigmaEnd-cfg.sigma0);
        end
        Wprev = Wm; qeSum = 0;
        for s = randperm(nS)
            x = X{s};
            if isDTW
                [dist, S] = dtw_batch(x, Wm, band);       % dist [nN x D]
                d = sum(dist, 2);
            else
                d = sqrt(sum((Wm - reshape(x,[1 D L])).^2, [2 3]));
            end
            [dmin, bmu] = min(d); qeSum = qeSum + dmin;
            h = exp(-sum((positions - positions(bmu,:)).^2, 2) / (2*sigma^2));
            upd = find(h >= hTol);
            if isDTW
                XA = align_batch(x, S(upd,:,:,:));         % [numel(upd) x D x L]
            else
                XA = repmat(reshape(x,[1 D L]), numel(upd), 1, 1);
            end
            Wm(upd,:,:) = Wm(upd,:,:) + alpha*h(upd).*(XA - Wm(upd,:,:));
        end
        log.QE(epoch) = qeSum/nS;                          % BMU distance before update
        log.dW(epoch) = mean(sqrt(sum((Wm-Wprev).^2,[2 3])));
        hist = [hist(2:end); {Wm}];
        if mod(epoch, 10) == 0 || epoch == cfg.numEpochs || epoch == 1
            fprintf('  epoch %4d/%d  alpha=%.4f sigma=%.3f  QE=%.4f  dW=%.5f\n', ...
                epoch, cfg.numEpochs, alpha, sigma, log.QE(epoch), log.dW(epoch));
        end
        w = cfg.stop.window;
        if epoch >= cfg.scheduleEpochs + 2*w
            q1 = mean(log.QE(epoch-2*w+1:epoch-w)); q2 = mean(log.QE(epoch-w+1:epoch));
            if abs(q1-q2)/max(q1,eps) < cfg.stop.relTol
                fprintf('  QE plateau reached at epoch %d (%.2f%% change over %d epochs) - stopping\n', ...
                    epoch, 100*abs(q1-q2)/q1, w);
                epochsRun = epoch; break;
            end
        end
    end
    log.QE = log.QE(1:epochsRun); log.dW = log.dW(1:epochsRun); log.epochsRun = epochsRun;
    log.finalAlpha = alpha; log.finalSigma = sigma; log.snapEpoch = max(epochsRun-50, 1);
    Wsnap = hist{1};
    if isempty(Wsnap), Wsnap = hist{find(~cellfun(@isempty,hist),1)}; end
    W = mat2cellrows(Wm); W_snap = mat2cellrows(Wsnap);
end
