function [net, tTrain] = train_lstm(xtr, ytr, xva, yva, nIn, classes, c)
%TRAIN_LSTM  Stacked LSTM classifier with class-weighted cross-entropy.
    layers = sequenceInputLayer(nIn,'Name','in');
    for i = 1:c.numLSTMLayers-1
        layers = [layers; lstmLayer(c.hiddenUnits,'OutputMode','sequence')]; %#ok<AGROW>
    end
    layers = [layers
              lstmLayer(c.hiddenUnits,'OutputMode','last')
              dropoutLayer(0.2)
              fullyConnectedLayer(numel(classes))
              softmaxLayer];
    if c.classWeights
        n = countcats(ytr);  wgt = sum(n) ./ (numel(n)*max(n,1));  wgt = wgt(:)';
    else
        wgt = ones(1,numel(classes));
    end
    opts = trainingOptions('adam', ...
        'InitialLearnRate', c.learnRate, ...
        'LearnRateSchedule','piecewise','LearnRateDropFactor',0.5,'LearnRateDropPeriod',60, ...
        'L2Regularization', c.l2, 'GradientThreshold', 1, ...
        'MaxEpochs', c.maxEpochs, 'MiniBatchSize', c.miniBatch, 'Shuffle','every-epoch', ...
        'ValidationData', {xva, yva}, ...
        'ValidationFrequency', max(1,floor(numel(xtr)/c.miniBatch)), ...
        'ValidationPatience', c.patience, 'OutputNetwork','best-validation', ...
        'ExecutionEnvironment','auto', 'Verbose', false, 'Plots','none');
    t = tic;
    net = trainnet(xtr, ytr, layers, @(Y,T) crossentropy(Y,T,wgt,'WeightsFormat','C'), opts);
    tTrain = toc(t);
end
