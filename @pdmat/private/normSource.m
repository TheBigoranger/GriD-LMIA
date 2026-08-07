function [sz, deg, vals, isCont, summary, fh, rb] = normSource( ...
        grid, src, optDeg, degreeSpecified, rb)
    %NORMSOURCE Normalize pdmat sources into pdbase constructor inputs.
    %
    %   Syntax:
    %     [sz, deg, vals, isCont, summary, fh, rb] = ...
    %         normSource(grid, src, optDeg, degreeSpecified, rb)
    %
    %   Arguments:
    %     grid   - Physical parameter grid vectors.
    %     src    - Function, global coefficient grid, or nested LocalValues.
    %     optDeg - Requested scalar or per-parameter degree payload.
    %     degreeSpecified - True only when the public Degree option appeared.
    %     rb      - Optional parameter-rate bounds.
    %
    %   Output:
    %     sz, deg - Inferred matrix size and Bernstein degree.
    %     vals    - Nested local coefficient tree.
    %     isCont  - Shared-face continuity classification.
    %     summary - Source-mode label; fh is the optional exact evaluator.
    %     rb      - Empty or validated parameter-rate bounds.
    %
    %   Example (via the public constructor):
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %
    %   SRC may be a function handle, a global numeric cell grid, or nested
    %   LocalValues. The outputs contain the inferred matrix size, degree,
    %   local coefficient tree, inferred continuity, source summary, optional
    %   exact evaluator, and normalized rate-bound state. Only explicit nested
    %   LocalValues need face checks; global Bernstein grids and function sources
    %   are continuous by construction.
    %   Function-only sources are intentionally kept outside coefficient
    %   algebra unless an explicit degree certifies Bernstein data.

    info = helper.mkGrid(grid, "pdmat");
    vecs = info.Vectors;
    if nargin < 5 || isempty(rb)
        rb = [];
    else
        rb = double(helper.chk(rb, "pdmat:InvalidRateBounds", ...
            "RateBounds", ...
            "numeric", "real", "finite", "rowbounds", ...
            "Size", [numel(vecs), 2]));
    end
    if degreeSpecified
        scalarDegree = isnumeric(optDeg) && isscalar(optDeg);
        optDeg = helper.normDeg(optDeg, numel(vecs), ...
            "pdmat:InvalidDegree", "Degree");
        if scalarDegree && numel(vecs) > 1
            warning("pdmat:ScalarDegreeExpansion", ...
                "Scalar Degree expands uniformly across all parameter directions.");
        end
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
    nPar = numel(vecs);
    if isempty(optDeg)
        deg = ones(1, nPar);
    else
        deg = optDeg;
    end
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
    nRateRows = size(helper.rateVerts(rb), 1);
    [sz, nCoeff, rowKind] = scanNest(src, nCell, nPar, nRateRows);
    if rowKind == "rate" && isempty(rb)
        error("pdmat:InvalidRateBounds", ...
            "Explicit rate-vertex LocalValues require nonempty RateBounds.");
    end

    if isempty(optDeg)
        uniformDeg = round(nCoeff ^ (1 / nPar) - 1);
        if uniformDeg < 0 || (uniformDeg + 1) ^ nPar ~= nCoeff
            error("pdmat:InvalidDegree", ...
                "Coefficient count must equal (Degree + 1)^numParameters.");
        end
        deg = repmat(uniformDeg, 1, nPar);
    else
        deg = optDeg;
        if nCoeff ~= prod(deg + 1)
            error("pdmat:InvalidDegree", ...
                "Local coefficient count does not match the requested Degree.");
        end
    end

    vals = src;
    % Explicit local leaves may represent discontinuous known data, unlike a
    % global coefficient grid whose shared nodes already enforce continuity.
    isCont = helper.chkCont(vals, nCell, deg);
end

function [sz, nCoeff, rowKind] = scanNest(vals, nCell, nPar, nRateRows)
    %SCANNEST Inspect a nested LocalValues tree without changing its layout.
    %
    %   Syntax:
    %     [sz, nCoeff] = scanNest(vals, nCell)
    %   The returned size and coefficient count are shared contracts for all
    %   cells; recursive calls handle tensor-product grids with more than one
    %   parameter dimension.
    helper.chk(vals, "pdmat:InvalidLocalValues", ...
        "LocalValues", ...
        "cell", "Numel", nCell(1));

    sz = [];
    nCoeff = [];
    rowKind = "";
    for k = 1:nCell(1)
        if isscalar(nCell)
            coeffs = vals{k};
            helper.chk(coeffs, "pdmat:InvalidCoefficientCell", ...
                "physical-cell coefficient table", ...
                "cell", "nonempty");
            if size(coeffs, 1) == 1
                oneKind = "ordinary";
            elseif nRateRows > 1 && size(coeffs, 1) == nRateRows
                oneKind = "rate";
            else
                error("pdmat:InvalidCoefficientCell", ...
                    "A coefficient table must have one row or one row per distinct RateBounds vertex.");
            end
            oneN = size(coeffs, 2);
            oneSz = scanMats(coeffs(:), "pdmat:InvalidCoefficientPayload", ...
                "Each pdmat payload must be a nonempty finite real numeric matrix.");
        else
            [oneSz, oneN, oneKind] = scanNest(vals{k}, ...
                nCell(2:end), nPar, nRateRows);
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
