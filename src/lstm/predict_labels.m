function yp = predict_labels(net, x, classes, miniBatch)
%PREDICT_LABELS  Class predictions of a trained network for a cell array of sequences.
    sc = minibatchpredict(net, x, 'MiniBatchSize', miniBatch, 'UniformOutput', true);
    [~, j] = max(sc, [], 2);
    yp = categorical(classes(j), classes);
end
