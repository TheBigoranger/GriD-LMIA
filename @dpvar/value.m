function out = value(obj)
    %VALUE Convert assigned dpvar coefficients to known dpmat data.
    %
    %   Syntax:
    %     A = value(P)
    %     rows = value(rhodiff(P))
    %
    %   An ordinary dpvar returns one coefficient-backed dpmat.  A dpvar
    %   with derivative rate rows returns a 1-by-2^ell cell array of dpmat
    %   objects in helper.combRows(RateBounds) vertex order.  Outputs preserve
    %   the grid, matrix size, degree, local coefficient order, and continuity
    %   metadata; rate bounds are not stored on the returned dpmat objects.
    %
    %   Every symbolic coefficient must have an assigned finite numeric
    %   YALMIP value.  Otherwise value throws dpvar:UnassignedValue.
    %
    %   Example:
    %     P = dpvar(1, [0 1], Degree=2);
    %     c = P.coeffs(1);
    %     assign([c{:}], 1:3);
    %     A = value(P);

    grid = obj.GridInfo.Vectors;
    vals = helper.mapVals(obj.LocalValues, @evalCoeff, grid);
    nCoeff = (obj.Degree + 1) ^ obj.npar();
    if ~isRateRows(vals, grid, nCoeff)
        out = makeDpmat(obj, vals);
        return
    end

    % rhodiff stores rows in the same lower/upper Cartesian order used by
    % helper.combRows; retain that order while removing rate metadata.
    nVert = 2 ^ obj.npar();
    nCell = obj.GridInfo.NumNodes - 1;
    out = cell(1, nVert);
    for row = 1:nVert
        rowVals = helper.mkNest(nCell, @(subs) pickRow(vals, subs, row));
        out{row} = makeDpmat(obj, rowVals);
    end
end

function val = evalCoeff(val)
    if isnumeric(val)
        raw = val;
    elseif isa(val, "sdpvar")
        try
            raw = value(val);
        catch
            error("dpvar:UnassignedValue", ...
                "Every dpvar coefficient must have an assigned finite numeric value.");
        end
    else
        raw = [];
    end

    if ~isnumeric(raw) || ~isreal(raw) || any(~isfinite(raw), "all")
        error("dpvar:UnassignedValue", ...
            "Every dpvar coefficient must have an assigned finite numeric value.");
    end
    val = raw;
end

function rowVals = pickRow(vals, subs, row)
    coeffs = helper.cellGet(vals, subs);
    rowVals = coeffs(row, :);
end

function out = makeDpmat(obj, vals)
    % Prepared construction preserves deliberate derivative discontinuities
    % without presenting them as invalid user-supplied local data.
    init = struct;
    init.DpmatInternal = true;
    init.Grid = obj.GridInfo.Vectors;
    init.MatrixSize = obj.MatrixSize;
    init.Degree = obj.Degree;
    init.LocalValues = vals;
    init.IsContinuous = obj.IsContinuous;
    init.SourceSummary = "coefficient-backed";
    init.FunctionHandle = [];
    out = dpmat(init);
end
