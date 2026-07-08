classdef (InferiorClasses = {?dpmat, ?sdpvar}) dpvar < dpbase
    %DPVAR Continuous Bernstein decision variable on a grid.
    %
    %   Syntax:
    %     P = dpvar(n, gridVectors)
    %     P = dpvar(n, n, gridVectors)
    %     P = dpvar(n, m, gridVectors)
    %     P = dpvar(..., "full")
    %     P = dpvar(..., "symmetric", Degree=0, RateBounds=rb)
    %
    %   Example:
    %     P = dpvar(2, [0 1 2], "symmetric");
    %     c = P.coeffs(1);
    %
    %   dpvar is method-superior to dpmat and sdpvar so mixed known,
    %   decision, and affine symbolic algebra dispatches through dpvar.

    methods
        function obj = dpvar(varargin)
            if nargin == 1 && isstruct(varargin{1}) && isfield(varargin{1}, "DpvarInternal")
                % Private algebra helpers pass prepared coefficient trees through the
                % constructor so dpbase private state is initialized exactly once.
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

            obj@dpbase(grid, sz, deg, vals, ...
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
        % A degree-zero dpvar is parameter-independent; every physical cell
        % stores the same symbolic coefficient while keeping grid metadata.
        val = sdpvar(sz(1), sz(2), char(typ));
        vals = helper.mkNest(nCell, @(~) {val});
    else
        nodes = helper.mkNest(info.NumNodes, @(~) sdpvar(sz(1), sz(2), char(typ)));
        lbls = helper.combRows(repmat({0:1}, 1, numel(info.Vectors)));

        % The global node tree is reused by every adjacent physical cell, which
        % makes continuity a shared-handle property rather than an equality LMI.
        vals = helper.mkNest(nCell, @(subs) cellVals(nodes, subs, lbls));
    end
    hasRate = ~isempty(rb);
end

function [sz, grid, info, typ, deg, rb] = parseArgs(varargin)
    if nargin < 2
        error("dpvar:InvalidInput", ...
            "dpvar requires a matrix size and gridVectors.");
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
            error("dpvar:InvalidInput", ...
                "gridVectors must follow the matrix size arguments.");
        end
        third = varargin{3};
        thirdIsGrid = iscell(third) || ...
            (isnumeric(third) && isvector(third) && numel(third) >= 2);
        if ~thirdIsGrid
            error("dpvar:InvalidInput", ...
                "gridVectors must follow the matrix size arguments.");
        end
        dims = [first second];
        grid = third;
        rest = varargin(4:end);
    end
    if isnumeric(grid)
        % Normalize scalar-parameter shorthand before calling dpbase, whose
        % internal grid contract remains one cell vector per parameter.
        grid = {grid};
    end

    sz = double(helper.chk(dims, "dpvar:InvalidMatrixSize", ...
        "dpvar matrix dimensions must be positive integer scalars.", ...
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
            error("dpvar:InvalidOptions", ...
                "dpvar options must be structure flags or Name=Value pairs.");
        end

        if any(name == ["full", "symmetric"])
            if name == "symmetric" && sz(1) ~= sz(2)
                error("dpvar:InvalidStructure", ...
                    "symmetric dpvar variables must be square.");
            end
            typ = name;
            k = k + 1;
            continue
        end

        if k == numel(rest)
            error("dpvar:InvalidOptions", ...
                "dpvar option %s requires a value.", name);
        end
        val = rest{k + 1};
        switch name
            case "RateBounds"
                rb = val;
            case "Degree"
                deg = double(helper.chk(val, "dpvar:InvalidDegree", ...
                    "Degree must be 0 or 1 for constructor-created dpvar variables.", ...
                    "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
                if ~any(deg == [0 1])
                    error("dpvar:InvalidDegree", ...
                        "Degree must be 0 or 1 for constructor-created dpvar variables.");
                end
            case {"IsContinuous", "ContainsDecision", "HasRateDependence"}
                error("dpvar:UnsupportedOption", ...
                    "%s is fixed internally for dpvar and is not a constructor option.", name);
            otherwise
                error("dpvar:UnknownOption", ...
                    "Unsupported dpvar option: %s.", name);
        end
        k = k + 2;
    end

    if typ == "symmetric" && sz(1) ~= sz(2)
        error("dpvar:InvalidStructure", ...
            "symmetric dpvar variables must be square.");
    end
    info = helper.mkGrid(grid, "dpvar");
end

function coeffs = cellVals(nodes, subs, lbls)
    nCoeff = size(lbls, 1);
    coeffs = cell(1, nCoeff);
    for k = 1:nCoeff
        coeffs{k} = helper.cellGet(nodes, subs + lbls(k, :));
    end
end
