function data = elevData(data, targetDeg, grid, validationMode)
    %ELEVDATA Align complete cell-wise trees with one plan per source degree.
    %
    %   Syntax:
    %     data = obj.elevData(data, targetDeg, grid, validationMode)
    %
    %   Arguments:
    %     data           - Struct array with Degree, LocalValues, and
    %                      NumRateRows fields.
    %     targetDeg      - Scalar or 1-by-ell target Bernstein degree.
    %     grid           - Cell array of parameter grid vectors.
    %     validationMode - "fast" checks the first leaf of each elevated data
    %                      entry; "strict" checks every leaf before applying
    %                      the cached elevation plan.
    %
    %   Output:
    %     data - The same struct array with each LocalValues tree elevated to
    %            targetDeg. Entries already at targetDeg are left unchanged.
    %            Degree retains the source degree; the caller owns the output
    %            object's degree metadata.
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

    % planned lists distinct source degrees needing elevation, not matrices
    % or physical-cell indices. plans{k} holds the map from planned(k,:) to
    % targetDeg. Equal source degrees share it across operands in this call;
    % entries already at targetDeg need no map.
    planned = unique(sourceDeg(any(sourceDeg < targetDeg, 2), :), ...
        "rows", "stable");
    plans = cell(size(planned, 1), 1);
    for k = 1:size(planned, 1)
        % Empty coefficients request only the numeric map and its metadata.
        [~, plans{k}] = pdbase.elevRow({}, planned(k, :), targetDeg);
    end

    % Traverse operands here; elevTree traverses physical cells and rate rows.
    for k = 1:numel(data)
        fromDeg = data(k).Degree;
        if isequal(fromDeg, targetDeg)
            continue
        end
        idx = find(all(planned == fromDeg, 2), 1);
        [data(k).LocalValues, plans{idx}] = elevTree(data(k).LocalValues, ...
            fromDeg, targetDeg, grid, plans{idx}, validationMode, ...
            data(k).NumRateRows);
    end
end

function [vals, plan] = elevTree(source, fromDeg, targetDeg, grid, plan, mode, ...
        nRateRows)
    %ELEVTREE Apply one plan across a complete physical-cell tree.
    firstCell = true;
    nCell = cellfun(@numel, grid) - 1;
    % Walk source and output branches together: each leaf is reached once,
    % without rebuilding subscript vectors or looking it up from the root.
    % For nCell=[2 3], visit (1,1),(1,2),(1,3),(2,1),(2,2),(2,3).
    vals = visit(source, 1);

    function branch = visit(in, dim)
        %VISIT Rebuild one grid axis while retaining the original leaf order.
        branch = cell(1, nCell(dim));
        for k = 1:nCell(dim)
            if dim == numel(nCell)
                branch{k} = elevAt(in{k});
            else
                branch{k} = visit(in{k}, dim + 1);
            end
        end
    end

    function leaf = elevAt(in)
        % firstCell is shared across this tree's callback calls, then resets
        % for the next operand. Fast mode skips checks, never cell elevation.
        doChk = mode == "strict" || firstCell;
        if doChk
            chkLeaf(in, fromDeg, nRateRows, plan);
        end
        % A leaf has one ordinary row or explicit rate rows. Its columns are
        % Bernstein coefficients; each entry is a whole matrix payload.
        leaf = cell(size(in, 1), plan.TargetCount);
        startRow = 1;
        if firstCell
            % Capture the expanded kernel only once per tree. Returning and
            % assigning the whole plan in every row adds avoidable overhead.
            [leaf(1, :), plan] = pdbase.elevRow( ...
                in(1, :), fromDeg, targetDeg, plan);
            startRow = 2;
        end
        for row = startRow:size(in, 1)
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
