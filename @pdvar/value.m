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
    nCoeff = (obj.Degree + 1) ^ obj.npar();
    if ~isRateRows(vals, grid, nCoeff)
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
    init.IsContinuous = obj.IsContinuous;
    init.SourceSummary = "coefficient-backed";
    init.FunctionHandle = [];
    out = pdmat(init);
end
