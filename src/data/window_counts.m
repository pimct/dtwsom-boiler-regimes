function [cntNonOverlap, cntStride1] = window_counts(dataset, w)
%WINDOW_COUNTS  Windows per regime and partition available to Stage B.
%   cntNonOverlap : non-overlapping windows of w rows
%   cntStride1    : windows with stride 1 inside one partition (no window
%                   crosses a purge gap)
    cnt = groupcounts(dataset, {'ClusterLabeled','Split'});
    cnt.Windows_nonoverlap = floor(cnt.GroupCount / w);
    cnt.Windows_stride1    = max(cnt.GroupCount - w + 1, 0);
    cntNonOverlap = unstack(cnt(:,{'ClusterLabeled','Split','Windows_nonoverlap'}), 'Windows_nonoverlap', 'Split');
    cntNonOverlap{:,2:end}(ismissing(cntNonOverlap{:,2:end})) = 0;
    cntStride1 = unstack(cnt(:,{'ClusterLabeled','Split','Windows_stride1'}), 'Windows_stride1', 'Split');
    cntStride1{:,2:end}(ismissing(cntStride1{:,2:end})) = 0;
end
