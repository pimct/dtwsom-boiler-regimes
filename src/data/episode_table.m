function epi = episode_table(segLabel, seg, nSeg, sample_period_s)
%EPISODE_TABLE  Contiguous runs of identical regime label, with row and time bounds.
    chg = [1; find(segLabel(1:end-1) ~= segLabel(2:end)) + 1];
    epi = table();
    epi.Cluster   = segLabel(chg);
    epi.SegFirst  = chg;
    epi.SegLast   = [chg(2:end)-1; nSeg];
    epi.RowFirst  = seg.SegStart(epi.SegFirst);
    epi.RowLast   = seg.SegEnd(epi.SegLast);
    epi.Start_min = (epi.RowFirst-1)*sample_period_s/60;
    epi.End_min   = epi.RowLast*sample_period_s/60;
    epi.nSegments = epi.SegLast - epi.SegFirst + 1;
end
