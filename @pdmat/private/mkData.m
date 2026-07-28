function [sz, deg, vals, isCont, summary, fh, rb] = ...
        mkData(grid, src, optDeg, rb)
    %MKDATA Route pdmat constructor sources into pdbase constructor inputs.
    %
    %   Syntax:
    %     [sz, deg, vals, isCont, summary, fh] = mkData(grid, src, optDeg)
    %
    %   Arguments:
    %     grid   - Physical parameter grid vectors.
    %     src    - Function, global coefficient grid, or nested LocalValues.
    %     optDeg - Optional requested scalar degree.
    %
    %   Output:
    %     sz, deg - Inferred matrix size and Bernstein degree.
    %     vals    - Nested local coefficient tree.
    %     isCont  - Shared-face continuity classification.
    %     summary - Source-mode label; fh is the optional exact evaluator.
    %
    %   Example (via the public constructor):
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %
    %   SRC may be a function handle, a global numeric cell grid, or nested
    %   LocalValues. The outputs contain the inferred matrix size, degree,
    %   local coefficient tree, inferred continuity, source summary, and optional
    %   exact evaluator. Only explicit nested LocalValues need face checks;
    %   global Bernstein grids and function sources are continuous by construction.
    %   Function-only sources are intentionally kept outside coefficient
    %   algebra unless an explicit degree certifies Bernstein data.

    info = helper.mkGrid(grid, "pdmat");
    vecs = info.Vectors;
    if nargin < 4 || isempty(rb)
        rb = [];
    else
        rb = double(helper.chk(rb, "pdmat:InvalidRateBounds", ...
            "RateBounds must be empty or a finite ell-by-2 matrix with lower <= upper.", ...
            "numeric", "real", "finite", "rowbounds", ...
            "Size", [numel(vecs), 2]));
    end
    if ~isempty(optDeg)
        optDeg = double(helper.chk(optDeg, "pdmat:InvalidDegree", ...
            "Degree must be a nonnegative integer scalar.", ...
            "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
    end
    if isa(src, "function_handle")
        [sz, deg, vals, summary, fh] = fcnData(src, info, optDeg);
        isCont = true;
        return
    end

    if ~iscell(src)
        error("pdmat:InvalidSource", ...
            "source must be a function handle, a numeric cell grid, or nested LocalValues.");
    end

    fh = [];
    summary = "coefficient-backed";
    if ~isempty(src) && all(cellfun(@isnumeric, src(:)))
        [sz, deg, vals] = gridToLocal(src, vecs, optDeg, "pdmat");
        isCont = true;
    else
        [sz, deg, vals, isCont] = localData(src, vecs, optDeg, rb);
    end
end

function [sz, deg, vals, summary, fh] = fcnData(fh, info, optDeg)
    %FCNDATA Probe a function source and optionally certify Bernstein data.
    %
    %   Syntax:
    %     [sz, deg, vals, summary, fh] = fcnData(fh, info, optDeg)
    %
    %   Example (via the public constructor):
    %     A = pdmat({[0 1]}, @(rho) rho, Degree=1);
    %   Without an explicit degree this function only records the exact
    %   evaluator and lower-bound size probe; with one, chkBernstein must
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
        error("pdmat:InvalidFunctionHandle", ...
            "Function handle must accept one input per parameter dimension.");
    end

    args = cell(1, nPar);
    for k = 1:nPar
        args{k} = vecs{k}(1);
    end
    try
        val = fh(args{:});
    catch err
        error("pdmat:InvalidFunctionHandle", ...
            "Function handle failed at the grid lower bound: %s", err.message);
    end

    sz = scanMats({val}, "pdmat:InvalidFunctionOutput", ...
        "Each pdmat payload must be a nonempty finite real numeric matrix.");
    if isempty(optDeg)
        % pdbase allocates placeholder zeros for inherited inspection. The exact
        % evaluator stays on pdmat until a future certified conversion exists.
        vals = [];
        summary = "function";
        return
    end

    vals = chkBernstein(fh, info, deg, sz);
    summary = "function-bernstein";
end

function [sz, deg, vals, isCont] = localData(src, vecs, optDeg, rb)
    %LOCALDATA Validate nested LocalValues while inferring its degree.
    %
    %   Syntax:
    %     [sz, deg, vals, isCont] = localData(src, gridVectors, optDeg)
    %   SCAN NEST also enforces one matrix size and one coefficient count for
    %   every physical cell. Invalid nesting or inconsistent leaves are
    %   reported with pdmat-specific errors rather than silently reshaped.

    nPar = numel(vecs);
    nCell = cellfun(@numel, vecs) - 1;
    [sz, nCoeff, rowKind] = scanNest(src, nCell, nPar);
    if rowKind == "rate" && isempty(rb)
        error("pdmat:InvalidRateBounds", ...
            "Explicit rate-vertex LocalValues require nonempty RateBounds.");
    end

    if isempty(optDeg)
        deg = round(nCoeff ^ (1 / nPar) - 1);
        if deg < 0 || (deg + 1) ^ nPar ~= nCoeff
            error("pdmat:InvalidDegree", ...
                "Coefficient count must equal (Degree + 1)^numParameters.");
        end
    else
        deg = optDeg;
        if nCoeff ~= (deg + 1) ^ nPar
            error("pdmat:InvalidDegree", ...
                "Local coefficient count does not match the requested Degree.");
        end
    end

    vals = src;
    % Explicit local leaves may represent discontinuous known data, unlike a
    % global coefficient grid whose shared nodes already enforce continuity.
    isCont = chkCont(vals, nCell, deg);
end

function [sz, nCoeff, rowKind] = scanNest(vals, nCell, nPar)
    %SCANNEST Inspect a nested LocalValues tree without changing its layout.
    %
    %   Syntax:
    %     [sz, nCoeff] = scanNest(vals, nCell)
    %   The returned size and coefficient count are shared contracts for all
    %   cells; recursive calls handle tensor-product grids with more than one
    %   parameter dimension.
    helper.chk(vals, "pdmat:InvalidLocalValues", ...
        "LocalValues must match the physical nested-cell grid shape.", ...
        "cell", "Numel", nCell(1));

    sz = [];
    nCoeff = [];
    rowKind = "";
    for k = 1:nCell(1)
        if isscalar(nCell)
            coeffs = vals{k};
            helper.chk(coeffs, "pdmat:InvalidCoefficientCell", ...
                "Each physical cell must store a nonempty coefficient table.", ...
                "cell", "nonempty");
            if size(coeffs, 1) == 1
                oneKind = "ordinary";
            elseif size(coeffs, 1) == 2 ^ nPar
                oneKind = "rate";
            else
                error("pdmat:InvalidCoefficientCell", ...
                    "A coefficient table must have one row or one row per RateBounds vertex.");
            end
            oneN = size(coeffs, 2);
            oneSz = scanMats(coeffs(:), "pdmat:InvalidCoefficientPayload", ...
                "Each pdmat payload must be a nonempty finite real numeric matrix.");
        else
            [oneSz, oneN, oneKind] = scanNest(vals{k}, ...
                nCell(2:end), nPar);
        end

        if isempty(sz)
            sz = oneSz;
            nCoeff = oneN;
            rowKind = oneKind;
        elseif ~isequal(sz, oneSz) || nCoeff ~= oneN || rowKind ~= oneKind
            error("pdmat:InvalidLocalValues", ...
                "All local coefficient cells must use one matrix size, coefficient count, and row kind.");
        end
    end
end
