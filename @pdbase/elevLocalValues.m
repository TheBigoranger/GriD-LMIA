function vals = elevLocalValues(vals, fromDeg, toDeg, grid)
    %ELEVLOCALVALUES Elevate temporary cell-local coefficient tables.
    %
    %   Syntax:
    %     vals = pdbase.elevLocalValues(vals, fromDeg, toDeg, grid)
    %
    %   Arguments:
    %     vals     - Nested coefficient tree on grid.
    %     fromDeg  - Current scalar degree in every parameter direction.
    %     toDeg    - Target scalar degree.
    %     grid     - Parameter grid owning vals.
    %
    %   Output:
    %     vals - Elevated tree with each rate-vertex row handled separately.

    if fromDeg == toDeg
        return
    end

    nPar = numel(grid);
    nCell = cellfun(@numel, grid) - 1;
    nFrom = (fromDeg + 1) ^ nPar;
    nTo = (toDeg + 1) ^ nPar;
    vals = helper.mkNest(nCell, @(subs) elevLeaf( ...
        helper.cellGet(vals, subs), fromDeg, toDeg, nFrom, nTo, nPar));
end

function out = elevLeaf(leaf, fromDeg, toDeg, nFrom, nTo, nPar)
    % Rate vertices occupy rows and must not be mixed by degree elevation.
    if ~iscell(leaf) || size(leaf, 2) ~= nFrom
        error("pdbase:InvalidCoefficientCell", ...
            "Each LocalValues leaf must have one column per source coefficient.");
    end

    out = cell(size(leaf, 1), nTo);
    for row = 1:size(leaf, 1)
        out(row, :) = pdbase.bernElev( ...
            leaf(row, :), fromDeg, toDeg, nPar);
    end
end
