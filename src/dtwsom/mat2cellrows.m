function C = mat2cellrows(Wm)
%MAT2CELLROWS  [nN x D x L] numeric array -> nN x 1 cell of [D x L] matrices.
    C = arrayfun(@(j) reshape(Wm(j,:,:), size(Wm,2), size(Wm,3)), (1:size(Wm,1))', ...
                 'UniformOutput', false);
end
