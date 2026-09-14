function [x, seg] = prep_segments(dataset, select_sensors, segment_size, stride)
%PREP_SEGMENTS  Cut the record into [D x L] segments.
%   x   : n x 1 cell of [D x segment_size] raw segments
%   seg : table with SegStart and SegEnd row indices
    data = dataset(:, select_sensors);
    starts = 1:stride:(height(data) - segment_size + 1);
    n = numel(starts); x = cell(n,1); SegStart = starts(:); SegEnd = SegStart + segment_size - 1;
    for i = 1:n, x{i} = data{SegStart(i):SegEnd(i), :}'; end
    seg = table(SegStart, SegEnd);
end
