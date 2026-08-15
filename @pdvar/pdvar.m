classdef (InferiorClasses = {?pdmat, ?sdpvar}) pdvar < pdbase
    %PDVAR Continuous Bernstein decision variable on a grid.
    %
    %   Syntax:
    %     P = pdvar(n, gridVectors)
    %     P = pdvar(n, n, gridVectors)
    %     P = pdvar(n, m, gridVectors)
    %     P = pdvar(..., "full")
    %     P = pdvar(..., "symmetric", Degree=0, RateBounds=rb)
    %
    %   Arguments:
    %     n, m        - Positive matrix dimensions; one n creates n-by-n.
    %     gridVectors - Parameter grid cell array or one-vector shorthand.
    %     structure   - Optional "symmetric" or "full" YALMIP structure.
    %     Degree      - Nonnegative scalar shorthand or ell-element degree; default 1.
    %     RateBounds  - Optional parameter-rate box with one row per parameter.
    %
    %   Output:
    %     P - Continuous cell-local YALMIP decision variable.
    %
    %   Degree is stored as a 1-by-ell row vector and defaults to ones(1,ell).
    %   An explicit multidimensional scalar expands uniformly and warns once.
    %   An all-zero Degree creates one shared decision matrix; otherwise
    %   adjacent cells share complete control faces, including zero-degree axes.
    %
    %   Example:
    %     P = pdvar(2, [0 1 2], "symmetric", Degree=2);
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
                if isfield(init, "IsContinuous")
                    isCont = init.IsContinuous;
                else
                    isCont = true;
                end
                if isfield(init, "ValidationMode")
                    validationMode = helper.normMode( ...
                        init.ValidationMode, "pdvar");
                else
                    validationMode = "fast";
                end
            else
                [grid, sz, deg, vals, rb, validationMode] = ...
                    ctorArgs(varargin{:});
                hasDec = true;
                numRateRows = 0;
                summary = "decision";
                isCont = true;
            end

            obj@pdbase(grid, sz, deg, vals, ...
                IsContinuous=isCont, ...
                ContainsDecision=hasDec, ...
                NumRateRows=numRateRows, ...
                RateBounds=rb, ...
                SourceSummary=summary, ...
                ValidationMode=validationMode);
        end
    end

    methods (Access = protected)
        out = mkUnOp(obj, vals, sz)
        out = mkRhodiff(obj, deg, vals, rb, hasDec, numRateRows)
    end

    methods (Static, Hidden, Access = ?pdmat)
        out = fromKnownProduct(lhs, rhs)
    end

end

function [grid, sz, deg, vals, rb, validationMode] = ctorArgs(varargin)
    %CTORARGS Parse public inputs and allocate shared continuous coefficients.
    [sz, grid, info, typ, deg, rb, validationMode] = ...
        parseArgs(varargin{:});
    nCell = info.NumNodes - 1;
    if all(deg == 0)
        % A degree-zero pdvar is parameter-independent; every physical cell
        % stores the same symbolic coefficient while keeping grid metadata.
        val = sdpvar(sz(1), sz(2), char(typ));
        vals = helper.mkNest(nCell, @(~) {val});
    else
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
    end
end

function [sz, grid, info, typ, deg, rb, validationMode] = parseArgs(varargin)
    %PARSEARGS Normalize matrix size, grid, structure, degree, and rate box.
    if nargin < 2
        error("pdvar:InvalidInput", ...
            "pdvar requires a matrix size and gridVectors.");
    end

    deg = 1;
    degreeSpecified = false;
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
