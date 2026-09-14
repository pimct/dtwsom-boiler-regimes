function S = runs2seg(labels)
%RUNS2SEG  Contiguous runs of a string/categorical vector -> table(SegStart, SegEnd, Phase).
    labels = string(labels);
    chg = [1; find(labels(1:end-1) ~= labels(2:end))+1];
    SegStart = chg;  SegEnd = [chg(2:end)-1; numel(labels)];
    Phase = labels(chg);
    S = table(SegStart, SegEnd, Phase);
end
