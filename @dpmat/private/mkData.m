function [sz, deg, vals, summary, fh] = mkData(grid, src, optDeg)
    %MKDATA Route dpmat constructor sources into dpbase constructor inputs.
    %
    %   Syntax:
    %     [sz, deg, vals, summary, fh] = mkData(grid, src, optDeg)
    %
    %   Example (via the public constructor):
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %
    %   SRC may be a function handle, a global numeric cell grid, or nested
    %   LocalValues. The outputs contain the inferred matrix size, degree,
    %   local coefficient tree, source summary, and optional exact evaluator.
    %   Function-only sources are intentionally kept outside coefficient
    %   algebra unless an explicit degree certifies Bernstein data.

    info = helper.mkGrid(grid, "dpmat");
    vecs = info.Vectors;
    if ~isempty(optDeg)
        optDeg = double(helper.chk(optDeg, "dpmat:InvalidDegree", ...
            "Degree must be a nonnegative integer scalar.", ...
            "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
    end
    if isa(src, "function_handle")
        [sz, deg, vals, summary, fh] = funData(src, info, optDeg);
        return
    end

    if ~iscell(src)
        error("dpmat:InvalidSource", ...
            "source must be a function handle, a numeric cell grid, or nested LocalValues.");
    end

    fh = [];
    summary = "coefficient-backed";
    if ~isempty(src) && all(cellfun(@isnumeric, src(:)))
        [sz, deg, vals] = helper.gridToLocal(src, vecs, optDeg, "dpmat");
    else
        [sz, deg, vals] = localData(src, vecs, optDeg);
    end
end

function [sz, deg, vals, summary, fh] = funData(fh, info, optDeg)
    %FUNDATA Probe a function source and optionally certify Bernstein data.
    %
    %   Syntax:
    %     [sz, deg, vals, summary, fh] = funData(fh, info, optDeg)
    %
    %   Example (via the public constructor):
    %     A = dpmat({[0 1]}, @(rho) rho, Degree=1);
    %   Without an explicit degree this function only records the exact
    %   evaluator and lower-bound size probe; with one, checkBernstein must
    %   certify the returned function before coefficient algebra can use it.

    vecs = info.Vectors;
    if isempty(optDeg)
        deg = 1;
    else
        deg = optDeg;
    end
    nPar = numel(vecs);
    try
        nArg = nargin(fh);
    catch
        nArg = -1;
    end
    if nArg ~= nPar
        error("dpmat:InvalidFunctionHandle", ...
            "Function handle must accept one input per parameter dimension.");
    end

    args = cell(1, nPar);
    for k = 1:nPar
        args{k} = vecs{k}(1);
    end
    try
        val = fh(args{:});
    catch err
        error("dpmat:InvalidFunctionHandle", ...
            "Function handle failed at the grid lower bound: %s", err.message);
    end

    sz = helper.scanMats({val}, "dpmat:InvalidFunctionOutput", ...
        "Each dpmat payload must be a nonempty finite real numeric matrix.");
    if isempty(optDeg)
        % dpbase allocates placeholder zeros for inherited inspection. The exact
        % evaluator stays on dpmat until a future certified conversion exists.
        vals = [];
        summary = "function";
        return
    end

    vals = checkBernstein(fh, info, deg, sz);
    summary = "function-bernstein";
end

function [sz, deg, vals] = localData(src, vecs, optDeg)
    %LOCALDATA Validate nested LocalValues while inferring its degree.
    %
    %   Syntax:
    %     [sz, deg, vals] = localData(src, gridVectors, optDeg)
    %   SCAN NEST also enforces one matrix size and one coefficient count for
    %   every physical cell. Invalid nesting or inconsistent leaves are
    %   reported with dpmat-specific errors rather than silently reshaped.

    nPar = numel(vecs);
    nCell = cellfun(@numel, vecs) - 1;
    [sz, nCoeff] = scanNest(src, nCell);

    if isempty(optDeg)
        deg = round(nCoeff ^ (1 / nPar) - 1);
        if deg < 0 || (deg + 1) ^ nPar ~= nCoeff
            error("dpmat:InvalidDegree", ...
                "Coefficient count must equal (Degree + 1)^numParameters.");
        end
    else
        deg = optDeg;
        if nCoeff ~= (deg + 1) ^ nPar
            error("dpmat:InvalidDegree", ...
                "Local coefficient count does not match the requested Degree.");
        end
    end

    vals = src;
end

function [sz, nCoeff] = scanNest(vals, nCell)
    %SCANNEST Inspect a nested LocalValues tree without changing its layout.
    %
    %   Syntax:
    %     [sz, nCoeff] = scanNest(vals, nCell)
    %   The returned size and coefficient count are shared contracts for all
    %   cells; recursive calls handle tensor-product grids with more than one
    %   parameter dimension.
    helper.chk(vals, "dpmat:InvalidLocalValues", ...
        "LocalValues must match the physical nested-cell grid shape.", ...
        "cell", "Numel", nCell(1));

    sz = [];
    nCoeff = [];
    for k = 1:nCell(1)
        if isscalar(nCell)
            coeffs = vals{k};
            helper.chk(coeffs, "dpmat:InvalidCoefficientCell", ...
                "Each physical cell must store a nonempty flat coefficient cell.", ...
                "cell", "nonempty");
            oneN = numel(coeffs);
            oneSz = helper.scanMats(coeffs(:), "dpmat:InvalidCoefficientPayload", ...
                "Each dpmat payload must be a nonempty finite real numeric matrix.");
        else
            [oneSz, oneN] = scanNest(vals{k}, nCell(2:end));
        end

        if isempty(sz)
            sz = oneSz;
            nCoeff = oneN;
        elseif ~isequal(sz, oneSz) || nCoeff ~= oneN
            error("dpmat:InvalidLocalValues", ...
                "All local coefficient cells must use the same matrix size and coefficient count.");
        end
    end
end
