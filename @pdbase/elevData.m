function data = elevData(data, targetDeg, grid, validationMode)
    %ELEVDATA Align complete cell-local trees with one plan per source degree.
    %
    %   Syntax:
    %     data = obj.elevData(data, targetDeg, grid, validationMode)
    %
    %   Arguments:
    %     data           - Struct array with Degree, LocalValues, and
    %                      NumRateRows fields.
    %     targetDeg      - Scalar or 1-by-ell target Bernstein degree.
    %     grid           - Cell array of parameter grid vectors.
    %     validationMode - "fast" checks one representative leaf per source
    %                      degree; "strict" checks every leaf before applying
    %                      the cached elevation plan.
    %
    %   Output:
    %     data - The same struct array with each LocalValues tree elevated to
    %            targetDeg. Entries already at targetDeg are left unchanged.
    %
    %   Example:
    %     data(1).Degree = [1 1];
    %     data(1).LocalValues = helper.mkNest([1 1], ...
    %         @(~) {eye(2), 2*eye(2), 3*eye(2), 4*eye(2)});
    %     data(1).NumRateRows = 0;
    %     data = obj.elevData(data, [2 2], {[0 1], [0 1]}, "strict");
    %
    %   This protected kernel is used after operands have already been moved
    %   to a common grid. It groups sources by degree so the sparse tensor
    %   elevation map is built once, then reused across all physical cells and
    %   rate rows. That keeps coefficient alignment deterministic and avoids
    %   rebuilding identical Bernstein operators during binary algebra.

    if nargin < 4
        validationMode = "fast";
    end
    validationMode = helper.normMode(validationMode, "pdbase");
    nPar = numel(grid);
    targetDeg = helper.normDeg(targetDeg, nPar, ...
        "pdbase:InvalidDegree", "targetDeg");
    sourceDeg = vertcat(data.Degree);
    if any(sourceDeg > targetDeg, "all")
        error("pdbase:InvalidDegreeElevation", ...
            "Cannot degree-elevate to a lower degree in any parameter direction.");
    end

    planned = unique(sourceDeg(any(sourceDeg < targetDeg, 2), :), ...
        "rows", "stable");
    plans = cell(size(planned, 1), 1);
    for k = 1:size(planned, 1)
        [~, plans{k}] = pdbase.elevRow({}, planned(k, :), targetDeg);
    end

    for k = 1:numel(data)
        fromDeg = data(k).Degree;
        if isequal(fromDeg, targetDeg)
            continue
        end
        plan = plans{find(all(planned == fromDeg, 2), 1)};
        data(k).LocalValues = elevTree(data(k).LocalValues, fromDeg, ...
            targetDeg, grid, plan, validationMode, data(k).NumRateRows);
    end
end

function vals = elevTree(source, fromDeg, targetDeg, grid, plan, mode, ...
        nRateRows)
    %ELEVTREE Apply one plan across a complete physical-cell tree.
    firstCell = true;
    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @elevAt);

    function leaf = elevAt(subs)
        in = helper.cellGet(source, subs);
        doChk = mode == "strict" || firstCell;
        if doChk
            chkLeaf(in, fromDeg, nRateRows, plan);
        end
        leaf = cell(size(in, 1), plan.TargetCount);
        for row = 1:size(in, 1)
            leaf(row, :) = pdbase.elevRow( ...
                in(row, :), fromDeg, targetDeg, plan);
        end
        firstCell = false;
    end
end

function chkLeaf(leaf, fromDeg, nRateRows, plan)
    %CHKLEAF Validate one complete local leaf before reusing the plan.
    if ~iscell(leaf) || size(leaf, 2) ~= prod(fromDeg + 1) || ...
            ~any(size(leaf, 1) == unique([1, nRateRows]))
        error("pdbase:InvalidCoefficientCell", ...
            "Each elevation leaf must match the source tensor and rate-row shape.");
    end
    if ~isnumeric(plan.Operator) || ...
            ~isequal(size(plan.Operator), ...
            [plan.TargetCount, plan.SourceCount]) || ...
            any(~isfinite(nonzeros(plan.Operator)))
        error("pdbase:InvalidDegreeElevation", ...
            "The elevation operator does not match the planned application shape.");
    end
    sz = [];
    for k = 1:numel(leaf)
        val = leaf{k};
        if isa(val, "sdpvar")
            valid = ismatrix(val) && isreal(val) && islinear(val);
        else
            valid = isnumeric(val) && ismatrix(val) && ~isempty(val) && ...
                isreal(val) && all(isfinite(val), "all");
        end
        if ~valid
            error("pdbase:InvalidCoefficientPayload", ...
                "Elevation coefficients must be finite real numeric or affine real sdpvar matrices.");
        end
        if isempty(sz)
            sz = size(val);
        elseif ~isequal(size(val), sz)
            error("pdbase:InvalidCoefficientPayload", ...
                "Every coefficient in one elevation leaf must have the same matrix size.");
        end
    end
end
