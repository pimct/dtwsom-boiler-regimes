function lab = seg_labels(idxA, active, numNeurons, bmuIdx)
%SEG_LABELS  Map a labelling of the active nodes to a label per segment.
    nodeLab = zeros(numNeurons,1); nodeLab(active) = idxA; lab = nodeLab(bmuIdx);
end
