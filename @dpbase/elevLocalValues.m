function vals = elevLocalValues(obj, vals, fromDeg, toDeg, grid)
    %ELEVLOCALVALUES Elevate temporary cell-local coefficient tables.
    %
    %   This protected engine supports algebra after common-grid remapping.
    %   It applies the same source and target degree in every parameter
    %   direction. Each leaf row is elevated independently because rows
    %   denote rate vertices, while columns denote Bernstein coefficients.

    if nargin < 5
        grid = obj.GridInfo.Vectors;
    end
    if fromDeg == toDeg
        return
    end

    nPar = numel(grid);
    nCell = cellfun(@numel, grid) - 1;
    nFrom = (fromDeg + 1) ^ nPar;
    nTo = (toDeg + 1) ^ nPar;
    vals = helper.mkNest(nCell, @(subs) elevLeaf(obj, ...
        helper.cellGet(vals, subs), fromDeg, toDeg, nFrom, nTo));
end

function out = elevLeaf(obj, leaf, fromDeg, toDeg, nFrom, nTo)
    % Rate vertices occupy rows and must not be mixed by degree elevation.
    if ~iscell(leaf) || size(leaf, 2) ~= nFrom
        error("dpbase:InvalidCoefficientCell", ...
            "Each LocalValues leaf must have one column per source coefficient.");
    end

    out = cell(size(leaf, 1), nTo);
    for row = 1:size(leaf, 1)
        out(row, :) = obj.bernElev(leaf(row, :), fromDeg, toDeg);
    end
end
