classdef (InferiorClasses = {?pdmat, ?sdpvar}) pdvar < pdbase
    %PDVAR Bernstein decision variable with direction-wise seam orders.
    %
    %   Syntax:
    %     P = pdvar(n, gridVectors)
    %     P = pdvar(n, n, gridVectors)
    %     P = pdvar(n, m, gridVectors)
    %     P = pdvar(..., "full")
    %     P = pdvar(..., "symmetric", Degree=2, Continuity=1, RateBounds=rb)
    %
    %   Arguments:
    %     n, m        - Positive matrix dimensions; one n creates n-by-n.
    %     gridVectors - Parameter grid cell array or one-vector shorthand.
    %     structure   - Optional "symmetric" or "full" YALMIP structure.
    %     Degree      - Nonnegative scalar shorthand or ell-element degree; default 1.
    %     Continuity  - Nonnegative integer or Inf lower bound per direction.
    %     RateBounds  - Optional parameter-rate box with one row per parameter.
    %
    %   Output:
    %     P - Cell-wise YALMIP decision variable with the requested continuity.
    %
    %   Degree is stored as a 1-by-ell row vector and defaults to ones(1,ell).
    %   Explicit multidimensional scalar Degree or Continuity values expand
    %   uniformly and warn once. Continuity defaults to C0; a single-cell axis
    %   or a request at least Degree normalizes to Inf. An all-zero Degree
    %   creates one shared decision matrix. The C0 path preserves shared face
    %   identities; C1-plus paths extract cell-wise Bernstein coefficients
    %   from spline controls and allocate no YALMIP continuity equalities.
    %
    %   Example:
    %     P = pdvar(2, [0 1 2], "symmetric", Degree=2, Continuity=1);
    %     c = P.coeffs(1);
    %
    %   pdvar is method-superior to pdmat and sdpvar so mixed known,
    %   decision, and affine symbolic algebra dispatches through pdvar.

    methods
        function obj = pdvar(varargin)
            if nargin == 1 && isstruct(varargin{1}) && isfield(varargin{1}, "PdvarInternal")
                % Private algebra helpers pass prepared coefficient trees through the
                % constructor so pdbase private state is initialized exactly once.
                init = varargin{1};
                grid = init.Grid;
                sz = init.MatrixSize;
                deg = init.Degree;
                vals = init.LocalValues;
                hasDec = init.ContainsDecision;
                if isfield(init, "NumRateRows")
                    numRateRows = init.NumRateRows;
                else
                    numRateRows = 0;
                end
                rb = init.RateBounds;
                summary = init.SourceSummary;
                if isfield(init, "Continuity")
                    continuity = init.Continuity;
                elseif isfield(init, "IsContinuous")
                    continuity = double(init.IsContinuous) - 1;
                else
                    continuity = zeros(1, numel(grid));
                end
                if isfield(init, "ValidationMode")
                    validationMode = helper.normMode( ...
                        init.ValidationMode, "pdvar");
                else
                    validationMode = "fast";
                end
            else
                [grid, sz, deg, vals, continuity, rb, validationMode] = ...
                    ctorArgs(varargin{:});
                hasDec = true;
                numRateRows = 0;
                summary = "decision";
            end

            obj@pdbase(grid, sz, deg, vals, ...
                Continuity=continuity, ...
                ContainsDecision=hasDec, ...
                NumRateRows=numRateRows, ...
                RateBounds=rb, ...
                SourceSummary=summary, ...
                ValidationMode=validationMode);
        end
    end

    methods (Access = protected)
        out = mkUnOp(obj, vals, sz)
        out = mkRhodiff(obj, deg, vals, rb, hasDec, numRateRows, continuity)
    end

    methods (Static, Hidden, Access = ?pdmat)
        out = fromKnownProduct(lhs, rhs)
    end

end

function [grid, sz, deg, vals, continuity, rb, validationMode] = ctorArgs(varargin)
    %CTORARGS Parse public inputs and allocate continuity-coupled coefficients.
    [sz, grid, info, typ, deg, continuity, rb, validationMode] = ...
        parseArgs(varargin{:});
    nCell = info.NumNodes - 1;
    if all(deg == 0)
        % A degree-zero pdvar is parameter-independent; every physical cell
        % stores the same symbolic coefficient while keeping grid metadata.
        val = sdpvar(sz(1), sz(2), char(typ));
        vals = helper.mkNest(nCell, @(~) {val});
    elseif ~hasHigherContinuity(continuity, deg, nCell)
        % Axis s contributes Degree_s new control positions per physical cell.
        % Reusing the tensor lattice shares complete faces, edges, and corners
        % without adding continuity equality constraints.
        nCtrl = nCell .* deg + 1;
        nodes = helper.mkNest(nCtrl, @(~) sdpvar(sz(1), sz(2), char(typ)));
        lbls = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, deg, ...
            "UniformOutput", false));

        % The global node tree is reused by every adjacent physical cell, which
        % makes continuity a shared-handle property rather than an equality LMI.
        vals = helper.mkNest(nCell, @(subs) cellVals(nodes, subs, lbls, deg));
    else
        % Spline controls span the requested space, but generally are not
        % function values at grid nodes. Only their cell-wise Bernstein
        % extraction is retained by the object.
        plans = cell(1, numel(deg));
        nIndependent = zeros(1, numel(deg));
        for dim = 1:numel(deg)
            plans{dim} = splinePlan(info.Vectors{dim}, deg(dim), continuity(dim));
            nIndependent(dim) = plans{dim}.NumControls;
        end
        controls = cell(1, prod(nIndependent));
        for k = 1:numel(controls)
            controls{k} = sdpvar(sz(1), sz(2), char(typ));
        end
        % Matrix entries occupy rows; tensor controls occupy columns in
        % combRows order (the last parameter varies fastest).
        packed = reshape(horzcat(controls{:}), prod(sz), []);
        lbls = helper.combRows(arrayfun(@(oneDeg) 0:oneDeg, deg, ...
            "UniformOutput", false));
        strides = fliplr(cumprod([1, fliplr(nIndependent(2:end))]));
        permutations = cell(1, numel(deg));
        inverses = cell(1, numel(deg));
        for dim = 1:numel(deg)
            % Move this axis to the fastest position without changing the
            % order of other axes or mixing matrix entries into the tensor.
            axes = [1:dim-1, dim+1:numel(deg), dim];
            [~, permutations{dim}] = sortrows(lbls, axes);
            [~, inverses{dim}] = sort(permutations{dim});
        end
        vals = helper.mkNest(nCell, ...
            @(subs) splineCellVals(packed, plans, subs, lbls, strides, ...
                permutations, inverses, sz));
    end
end

function [sz, grid, info, typ, deg, continuity, rb, validationMode] = parseArgs(varargin)
    %PARSEARGS Normalize matrix size, grid, structure, degree, and rate box.
    if nargin < 2
        error("pdvar:InvalidInput", ...
            "pdvar requires a matrix size and gridVectors.");
    end

    deg = 1;
    degreeSpecified = false;
    continuity = 0;
    continuitySpecified = false;
    seenContinuity = false;
    rb = [];
    validationMode = "fast";
    seenValidation = false;
    first = varargin{1};
    second = varargin{2};
    secondIsGrid = iscell(second) || ...
        (isnumeric(second) && isvector(second) && numel(second) >= 2);
    if secondIsGrid
        dims = [first first];
        grid = second;
        rest = varargin(3:end);
    else
        if nargin < 3
            error("pdvar:InvalidInput", ...
                "gridVectors must follow the matrix size arguments.");
        end
        third = varargin{3};
        thirdIsGrid = iscell(third) || ...
            (isnumeric(third) && isvector(third) && numel(third) >= 2);
        if ~thirdIsGrid
            error("pdvar:InvalidInput", ...
                "gridVectors must follow the matrix size arguments.");
        end
        dims = [first second];
        grid = third;
        rest = varargin(4:end);
    end
    if isnumeric(grid)
        % Normalize scalar-parameter shorthand before calling pdbase, whose
        % internal grid contract remains one cell vector per parameter.
        grid = {grid};
    end

    sz = double(helper.chk(dims, "pdvar:InvalidMatrixSize", ...
        "pdvar matrix dimensions", ...
        "numeric", "real", "finite", "integer", "positive", "Size", [1, 2]));
    if sz(1) == sz(2)
        typ = "symmetric";
    else
        typ = "full";
    end

    k = 1;
    while k <= numel(rest)
        item = rest{k};
        if ischar(item) || (isstring(item) && isscalar(item))
            name = string(item);
        else
            error("pdvar:InvalidOptions", ...
                "pdvar options must be structure flags or Name=Value pairs.");
        end

        if any(name == ["full", "symmetric"])
            if name == "symmetric" && sz(1) ~= sz(2)
                error("pdvar:InvalidStructure", ...
                    "symmetric pdvar variables must be square.");
            end
            typ = name;
            k = k + 1;
            continue
        end

        if k == numel(rest)
            if (ischar(item) && strcmp(item, "ValidationMode")) || ...
                    (isstring(item) && isscalar(item) && ...
                    ~ismissing(item) && item == "ValidationMode")
                error("pdvar:InvalidValidationMode", ...
                    "ValidationMode requires the scalar text 'fast' or 'strict'.");
            end
            error("pdvar:InvalidOptions", ...
                "pdvar option %s requires a value.", name);
        end
        val = rest{k + 1};
        switch name
            case "RateBounds"
                rb = val;
            case "Degree"
                deg = val;
                degreeSpecified = true;
            case "Continuity"
                if seenContinuity
                    error("pdvar:DuplicateOption", ...
                        "Continuity may be supplied only once.");
                end
                continuity = val;
                continuitySpecified = true;
                seenContinuity = true;
            case "ValidationMode"
                if seenValidation
                    error("pdvar:InvalidValidationMode", ...
                        "ValidationMode may be supplied only once.");
                end
                validationMode = helper.normMode(val, "pdvar");
                seenValidation = true;
            case {"IsContinuous", "ContainsDecision"}
                error("pdvar:UnsupportedOption", ...
                    "%s is fixed internally for pdvar and is not a constructor option.", name);
            otherwise
                error("pdvar:UnknownOption", ...
                    "Unsupported pdvar option: %s.", name);
        end
        k = k + 2;
    end

    if typ == "symmetric" && sz(1) ~= sz(2)
        error("pdvar:InvalidStructure", ...
            "symmetric pdvar variables must be square.");
    end
    info = helper.mkGrid(grid, "pdvar");
    scalarDegree = isnumeric(deg) && isscalar(deg);
    deg = helper.normDeg(deg, numel(info.Vectors), ...
        "pdvar:InvalidDegree", "Degree");
    if degreeSpecified && scalarDegree && numel(info.Vectors) > 1
        warning("pdvar:ScalarDegreeExpansion", ...
            "Scalar Degree expands uniformly across all parameter directions.");
    end
    scalarContinuity = isnumeric(continuity) && isscalar(continuity);
    continuity = normPublicContinuity(continuity, numel(info.Vectors), ...
        info.NumNodes - 1, deg);
    if continuitySpecified && scalarContinuity && numel(info.Vectors) > 1
        warning("pdvar:ScalarContinuityExpansion", ...
            "Scalar Continuity expands uniformly across all parameter directions.");
    end
end

function coeffs = cellVals(nodes, subs, lbls, deg)
    %CELLVALS Select one cell's flat coefficients from the global handle lattice.
    nCoeff = size(lbls, 1);
    coeffs = cell(1, nCoeff);
    for k = 1:nCoeff
        idx = (subs - 1) .* deg + lbls(k, :) + 1;
        coeffs{k} = helper.cellGet(nodes, idx);
    end
end

function tf = hasHigherContinuity(continuity, degree, nCell)
    %HASHIGHERCONTINUITY Keep the historical C0 allocation path unchanged.
    tf = any(nCell > 1 & degree > 0 & ...
        (isinf(continuity) | continuity >= 1));
end

function continuity = normPublicContinuity(value, nPar, nCell, degree)
    %NORMPUBLICCONTINUITY Validate and normalize requested seam orders.
    if ~(isnumeric(value) && isreal(value) && isvector(value) && ...
            ~isempty(value) && all(~isnan(value), "all") && ...
            all(value == inf | ...
            (isfinite(value) & value >= 0 & value == fix(value)), "all"))
        error("pdvar:InvalidContinuity", ...
            "Continuity must contain nonnegative integers or Inf.");
    end
    if isscalar(value)
        continuity = repmat(double(value), 1, nPar);
    elseif numel(value) == nPar
        continuity = reshape(double(value), 1, []);
    else
        error("pdvar:InvalidContinuity", ...
            "Continuity must be scalar or have one entry per parameter.");
    end
    continuity(nCell == 1 | continuity >= degree) = inf;
end

function coeffs = splineCellVals(packed, plans, subs, lbls, strides, ...
        permutations, inverses, sz)
    %SPLINECELLVALS Extract one Cartesian control window axis by axis.
    starts = zeros(1, numel(plans));
    for dim = 1:numel(plans)
        starts(dim) = plans{dim}.ControlIndices{subs(dim)}(1) - 1;
    end
    local = packed(:, 1 + (lbls + starts) * strides');
    nCoeff = size(lbls, 1);
    for dim = 1:numel(plans)
        extraction = plans{dim}.Extraction{subs(dim)};
        if isequal(extraction, speye(size(extraction, 1)))
            continue
        end
        if numel(plans) == 1
            % A single axis already occupies the packed columns. Apply its
            % control map directly, avoiding symbolic tensor rearrangements.
            local = local * extraction.';
            continue
        end
        % Each column of work is one axis fiber for one matrix entry.
        % This contracts only a (degree+1)-square numeric map, never a
        % global tensor Kronecker operator or symbolic seam recurrence.
        work = reshape(local(:, permutations{dim}).', size(extraction, 1), []);
        work = extraction * work;
        local = reshape(work, nCoeff, prod(sz)).';
        local = local(:, inverses{dim});
    end
    coeffs = cell(1, nCoeff);
    for k = 1:nCoeff
        coeffs{k} = reshape(local(:, k), sz);
    end
end
