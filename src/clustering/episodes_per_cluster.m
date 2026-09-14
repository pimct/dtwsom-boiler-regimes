function e = episodes_per_cluster(lab)
%EPISODES_PER_CLUSTER  Number of contiguous runs of each label value.
    u = unique(lab); e = zeros(numel(u),1);
    for i = 1:numel(u), e(i) = sum(diff([0; lab(:) == u(i)]) == 1); end
end
