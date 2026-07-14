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
    %   Degree accepts any finite nonnegative integer scalar and defaults to
    %   1.  Degree 0 creates one parameter-independent decision matrix shared
    %   across the grid.  Degree d >= 1 creates continuous piecewise Bernstein
    %   data whose adjacent cells share complete faces of control matrices.
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
                hasRate = init.HasRateDependence;
                rb = init.RateBounds;
                summary = init.SourceSummary;
                if isfield(init, "IsContinuous")
                    isCont = init.IsContinuous;
                else
                    isCont = true;
                end
            else
                [grid, sz, deg, vals, hasRate, rb] = ctorArgs(varargin{:});
                hasDec = true;
                summary = "decision";
                isCont = true;
            end

            obj@pdbase(grid, sz, deg, vals, ...
                IsContinuous=isCont, ...
                ContainsDecision=hasDec, ...
                HasRateDependence=hasRate, ...
                RateBounds=rb, ...
                SourceSummary=summary);
        end
    end

end

function [grid, sz, deg, vals, hasRate, rb] = ctorArgs(varargin)
    [sz, grid, info, typ, deg, rb] = parseArgs(varargin{:});
    nCell = info.NumNodes - 1;
    if deg == 0
        % A degree-zero pdvar is parameter-independent; every physical cell
        % stores the same symbolic coefficient while keeping grid metadata.
        val = sdpvar(sz(1), sz(2), char(typ));
        vals = helper.mkNest(nCell, @(~) {val});
    else
        % A degree-d piecewise polynomial has d new control positions per
        % physical cell.  Reusing this global lattice shares complete faces,
        % edges, and corners without adding continuity equality constraints.
        nCtrl = nCell .* deg + 1;
        nodes = helper.mkNest(nCtrl, @(~) sdpvar(sz(1), sz(2), char(typ)));
        lbls = helper.combRows(repmat({0:deg}, 1, numel(info.Vectors)));

        % The global node tree is reused by every adjacent physical cell, which
        % makes continuity a shared-handle property rather than an equality LMI.
        vals = helper.mkNest(nCell, @(subs) cellVals(nodes, subs, lbls, deg));
    end
    hasRate = ~isempty(rb);
end

function [sz, grid, info, typ, deg, rb] = parseArgs(varargin)
    if nargin < 2
        error("pdvar:InvalidInput", ...
            "pdvar requires a matrix size and gridVectors.");
    end

    typ = "";
    deg = 1;
    rb = [];
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
        "pdvar matrix dimensions must be positive integer scalars.", ...
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
            error("pdvar:InvalidOptions", ...
                "pdvar option %s requires a value.", name);
        end
        val = rest{k + 1};
        switch name
            case "RateBounds"
                rb = val;
            case "Degree"
                deg = double(helper.chk(val, "pdvar:InvalidDegree", ...
                    "Degree must be a nonnegative integer scalar.", ...
                    "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
            case {"IsContinuous", "ContainsDecision", "HasRateDependence"}
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
end

function coeffs = cellVals(nodes, subs, lbls, deg)
    nCoeff = size(lbls, 1);
    coeffs = cell(1, nCoeff);
    for k = 1:nCoeff
        idx = (subs - 1) .* deg + lbls(k, :) + 1;
        coeffs{k} = helper.cellGet(nodes, idx);
    end
end
