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
    %   with derivative rate rows returns one pdmat per distinct RateBounds
    %   vertex in helper.combRows order. Outputs preserve the grid, matrix size,
    %   degree, and local coefficient order. Ordinary numeric outputs recompute
    %   complete-face continuity and may recover continuity after cancellation.
    %   Derivative row exports remain deliberately discontinuous; rate bounds
    %   are not stored on the returned pdmat objects.
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
    if obj.NumRateRows == 0
        out = mkPdmat(obj, vals);
        return
    end

    % rhodiff stores rows in the same lower/upper Cartesian order used by
    % helper.combRows; retain that order while removing rate metadata.
    nCell = obj.GridInfo.NumNodes - 1;
    out = cell(1, obj.NumRateRows);
    for row = 1:obj.NumRateRows
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
    if obj.NumRateRows ~= 0
        % Each exported derivative vertex retains the source's deliberate
        % cell-local semantics after rate metadata is removed.
        init.IsContinuous = false;
    else
        init.IsContinuous = helper.chkCont(vals, ...
            obj.GridInfo.NumNodes - 1, obj.Degree);
    end
    init.SourceSummary = "coefficient-backed";
    init.FunctionHandle = [];
    out = pdmat(init);
end
