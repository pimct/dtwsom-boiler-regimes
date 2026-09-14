function P = grid_positions(somSize)
%GRID_POSITIONS  [row col] coordinates of every node of a rectangular SOM grid.
    [c, r] = meshgrid(1:somSize(2), 1:somSize(1)); P = [r(:) c(:)];
end
