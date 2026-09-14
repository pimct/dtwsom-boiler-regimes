function [bmu, bmu2, qe] = predict_bmu(X, W, distMode, band)
%PREDICT_BMU  Best- and second-best-matching unit and quantisation error per segment.
    if nargin < 4, band = 0; end
    Wm = cell2mat(reshape(cellfun(@(a) reshape(a,[1 size(a)]), W, 'UniformOutput', false), [], 1));
    nS = numel(X); bmu = zeros(nS,1); bmu2 = zeros(nS,1); qe = zeros(nS,1);
    for i = 1:nS
        d = seq_dist_all(X{i}, Wm, distMode, band);
        [ds, o] = sort(d);
        bmu(i) = o(1); bmu2(i) = o(2); qe(i) = ds(1);
    end
end
