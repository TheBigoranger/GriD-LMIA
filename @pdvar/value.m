function out = value(obj)
    %VALUE Convert assigned pdvar coefficients to known pdmat data.
    %
    %   Syntax:
    %     A = value(P)
    %     rows = value(rhodiff(P))
    %
    %   Arguments:
    %     P - pdvar expression whose YALMIP coefficients have assigned values.
    %
    %   Output:
    %     A    - Coefficient-backed pdmat for an ordinary expression.
    %     rows - One pdmat per derivative rate vertex, in combRows order.
    %
    %   An ordinary pdvar returns one coefficient-backed pdmat.  A pdvar
    %   with derivative rate rows returns a 1-by-2^ell cell array of pdmat
    %   objects in helper.combRows(RateBounds) vertex order.  Outputs preserve
    %   the grid, matrix size, degree, local coefficient order, and continuity
    %   metadata; rate bounds are not stored on the returned pdmat objects.
    %
    %   Every symbolic coefficient must have an assigned finite numeric
    %   YALMIP value.  Otherwise value throws pdvar:UnassignedValue.
    %
    %   Example:
    %     P = pdvar(1, [0 1], Degree=2);
    %     c = P.coeffs(1);
    %     assign([c{:}], 1:3);
    %     A = value(P);

    grid = obj.GridInfo.Vectors;
    vals = pdbase.mapVals(obj.LocalValues, @evalCoeff, grid);
    if ~obj.hasRateRows()
        out = mkPdmat(obj, vals);
        return
    end

    % rhodiff stores rows in the same lower/upper Cartesian order used by
    % helper.combRows; retain that order while removing rate metadata.
    nVert = 2 ^ obj.npar();
    nCell = obj.GridInfo.NumNodes - 1;
    out = cell(1, nVert);
    for row = 1:nVert
        rowVals = helper.mkNest(nCell, @(subs) pickRow(vals, subs, row));
        out{row} = mkPdmat(obj, rowVals);
    end
end

function val = evalCoeff(val)
    %EVALCOEFF Convert one assigned coefficient to a finite real numeric matrix.
    if isnumeric(val)
        raw = val;
    elseif isa(val, "sdpvar")
        try
            raw = value(val);
        catch
            error("pdvar:UnassignedValue", ...
                "Every pdvar coefficient must have an assigned finite numeric value.");
        end
    else
        raw = [];
    end

    if ~isnumeric(raw) || ~isreal(raw) || any(~isfinite(raw), "all")
        error("pdvar:UnassignedValue", ...
            "Every pdvar coefficient must have an assigned finite numeric value.");
    end
    val = raw;
end

function rowVals = pickRow(vals, subs, row)
    %PICKROW Extract one rate-vertex row from a physical-cell leaf.
    coeffs = helper.cellGet(vals, subs);
    rowVals = coeffs(row, :);
end

function out = mkPdmat(obj, vals)
    % Prepared construction preserves deliberate derivative discontinuities
    % without presenting them as invalid user-supplied local data.
    init = struct;
    init.PdmatInternal = true;
    init.Grid = obj.GridInfo.Vectors;
    init.MatrixSize = obj.MatrixSize;
    init.Degree = obj.Degree;
    init.LocalValues = vals;
    if obj.hasRateRows()
        % Each exported derivative vertex retains the source's deliberate
        % cell-local semantics after rate metadata is removed.
        init.IsContinuous = false;
    else
        init.IsContinuous = assignedContinuity(vals, ...
            obj.GridInfo.NumNodes - 1, obj.Degree);
    end
    init.SourceSummary = "coefficient-backed";
    init.FunctionHandle = [];
    out = pdmat(init);
end

function tf = assignedContinuity(vals, nCell, degree)
    %ASSIGNEDCONTINUITY Reclassify faces after symbolic values are assigned.
    nPar = numel(nCell);
    cells = helper.combRows(arrayfun(@(n) 1:n, nCell, ...
        "UniformOutput", false));
    labels = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, degree, ...
        "UniformOutput", false));
    tf = true;
    for dim = 1:nPar
        upper = find(labels(:, dim) == degree(dim));
        lower = find(labels(:, dim) == 0);
        step = zeros(1, nPar);
        step(dim) = 1;
        for k = 1:size(cells, 1)
            subs = cells(k, :);
            if subs(dim) == nCell(dim)
                continue
            end
            lhs = helper.cellGet(vals, subs);
            rhs = helper.cellGet(vals, subs + step);
            for row = 1:size(lhs, 1)
                for q = 1:numel(upper)
                    left = lhs{row, upper(q)};
                    right = rhs{row, lower(q)};
                    tolerance = 1e-9 * max([1, norm(left, "fro"), ...
                        norm(right, "fro")]);
                    if norm(left - right, "fro") > tolerance
                        tf = false;
                        return
                    end
                end
            end
        end
    end
end
