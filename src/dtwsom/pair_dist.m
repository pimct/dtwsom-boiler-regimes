function Dm = pair_dist(A, distMode, band)
%PAIR_DIST  Symmetric pairwise distance matrix within a cell array of segments.
    if nargin < 3, band = 0; end
    Am = cell2mat(reshape(cellfun(@(a) reshape(a,[1 size(a)]), A, 'UniformOutput', false), [], 1));
    n = numel(A); Dm = zeros(n);
    for i = 1:n
        Dm(i,:) = seq_dist_all(A{i}, Am, distMode, band)';
    end
    Dm = (Dm + Dm')/2; Dm(1:n+1:end) = 0;
end
