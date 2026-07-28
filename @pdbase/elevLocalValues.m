function vals = elevLocalValues(vals, fromDeg, toDeg, grid, plan, validationMode)
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
    if nargin < 5 || isempty(plan)
        plan = pdbase.elevationPlan(fromDeg, toDeg, nPar);
    end
    if nargin < 6 || isempty(validationMode)
        validationMode = "fast";
    end
    nCell = cellfun(@numel, grid) - 1;
    nFrom = (fromDeg + 1) ^ nPar;
    nTo = (toDeg + 1) ^ nPar;
    firstCell = true;
    sourceVals = vals;
    vals = helper.mkNest(nCell, @elevateAt);

    function out = elevateAt(subs)
        % The representative leaf includes every coefficient and rate row;
        % strict mode repeats that complete validation for each later cell.
        validateInstance = validationMode == "strict" || firstCell;
        out = elevLeaf(helper.cellGet(sourceVals, subs), fromDeg, toDeg, ...
            nFrom, nTo, nPar, plan, validateInstance);
        firstCell = false;
    end
end

function out = elevLeaf(leaf, fromDeg, toDeg, nFrom, nTo, nPar, ...
        plan, validateInstance)
    % Rate vertices occupy rows and must not be mixed by degree elevation.
    if validateInstance
        validateElevationLeaf(leaf, nFrom, nTo, nPar, plan);
    end

    out = cell(size(leaf, 1), nTo);
    for row = 1:size(leaf, 1)
        out(row, :) = pdbase.bernElev( ...
            leaf(row, :), fromDeg, toDeg, nPar, plan, ...
            false);
    end
end

function validateElevationLeaf(leaf, nFrom, nTo, nPar, plan)
    %VALIDATEELEVATIONLEAF Check one complete cell and operator application.
    if ~iscell(leaf) || size(leaf, 2) ~= nFrom || ...
            ~any(size(leaf, 1) == [1, 2 ^ nPar])
        error("pdbase:InvalidCoefficientCell", ...
            "Each elevation leaf must match the source tensor and rate-row shape.");
    end
    if ~isnumeric(plan.Operator) || ...
            ~isequal(size(plan.Operator), [nTo, nFrom]) || ...
            any(~isfinite(nonzeros(plan.Operator)))
        error("pdbase:InvalidDegreeElevation", ...
            "The elevation operator does not match the planned application shape.");
    end

    matrixSize = [];
    for k = 1:numel(leaf)
        value = leaf{k};
        if isa(value, "sdpvar")
            valid = ismatrix(value) && isreal(value) && islinear(value);
        else
            valid = isnumeric(value) && ismatrix(value) && ...
                ~isempty(value) && isreal(value) && ...
                all(isfinite(value), "all");
        end
        if ~valid
            error("pdbase:InvalidCoefficientPayload", ...
                "Elevation coefficients must be finite real numeric or affine real sdpvar matrices.");
        end
        if isempty(matrixSize)
            matrixSize = size(value);
        elseif ~isequal(size(value), matrixSize)
            error("pdbase:InvalidCoefficientPayload", ...
                "Every coefficient in one elevation leaf must have the same matrix size.");
        end
    end

    packedColumns = matrixSize(2) * nFrom;
    operatorRows = size(kron(plan.Operator', ...
        speye(matrixSize(2))), 1);
    if packedColumns ~= operatorRows
        error("pdbase:InvalidDegreeElevation", ...
            "The elevation operator is incompatible with the packed coefficient shape.");
    end
end
