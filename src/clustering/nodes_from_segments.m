function idxA = nodes_from_segments(lab, active, bmuIdx)
%NODES_FROM_SEGMENTS  Label each active node by the majority label of its segments.
    idxA = zeros(numel(active),1);
    for a = 1:numel(active)
        idxA(a) = mode(lab(bmuIdx == active(a)));
    end
end
