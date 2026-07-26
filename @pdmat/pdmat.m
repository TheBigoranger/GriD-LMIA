classdef pdmat < pdbase
    %PDMAT Known matrix data on a parameter grid.
    %
    %   Syntax:
    %     A = pdmat(gridVectors, source)
    %     A = pdmat(gridVectors, source, Degree=m)
    %
    %   Arguments:
    %     gridVectors - Parameter grid cell array or one-vector shorthand.
    %     source      - Function handle, global coefficient grid, or LocalValues.
    %     Degree      - Optional nonnegative scalar Bernstein degree.
    %
    %   Output:
    %     A - Known parameter-dependent matrix data.
    %
    %   source may be a function handle, a global cell grid of numeric
    %   Bernstein coefficients, or nested LocalValues in the pdbase contract.
    %   Nested LocalValues with mismatched shared faces produce a
    %   pdmat:DiscontinuousLocalValues warning and IsContinuous=false;
    %   their cell-local coefficient data is left unchanged.
    %   Function-backed objects without Degree only probe the lower grid
    %   point for size; inherited LocalValues are placeholder zeros, not
    %   coefficient evidence. Function handles with explicit Degree are
    %   validated as local Bernstein data while retaining FunctionHandle.
    %
    %   Example:
    %     data = {1, 2, 3};
    %     A = pdmat([0 1 2], data, Degree=1);
    %     c = A.coeffs(2);

    properties (SetAccess = private)
        FunctionHandle
    end

    methods
        function obj = pdmat(gridVectors, source, varargin)
            if nargin == 1 && isstruct(gridVectors) && isfield(gridVectors, "PdmatInternal")
                % Private algebra helpers supply validated metadata so an
                % internal rewrap never repeats a user-facing warning.
                init = gridVectors;
                grid = init.Grid;
                sz = init.MatrixSize;
                deg = init.Degree;
                vals = init.LocalValues;
                isCont = init.IsContinuous;
                summary = init.SourceSummary;
                fh = init.FunctionHandle;
                warnCont = false;
            else
                degOpt = parseOpts(varargin{:});
                if isnumeric(gridVectors) && isvector(gridVectors) && numel(gridVectors) >= 2
                    % Accept scalar-parameter shorthand at the public entry;
                    % pdbase still receives its strict cell-vector grid contract.
                    gridVectors = {gridVectors};
                end

                grid = gridVectors;
                [sz, deg, vals, isCont, summary, fh] = mkData(grid, source, degOpt);
                warnCont = ~isCont;
            end

            % All pdmat sources are known numeric data in this first pass:
            % no YALMIP decisions and no rho_dot dependence enter the parent.
            obj@pdbase(grid, sz, deg, vals, ...
                IsContinuous=isCont, ...
                ContainsDecision= false, ...
                HasRateDependence=false, ...
                RateBounds=[], ...
                SourceSummary=summary);

            obj.FunctionHandle = fh;
            if warnCont
                warning("pdmat:DiscontinuousLocalValues", ...
                    "Nested LocalValues have mismatched shared Bernstein faces; IsContinuous is false.");
            end
        end
    end

    methods (Access = protected)
        out = mkUnOp(obj, vals, sz)
    end

end

function degOpt = parseOpts(varargin)
    %PARSEOPTS Parse the optional Bernstein representation degree.
    degOpt = [];
    if mod(numel(varargin), 2) ~= 0
        error("pdmat:InvalidOptions", "pdmat options must be Name=Value pairs.");
    end

    for k = 1:2:numel(varargin)
        name = varargin{k};
        if ~(ischar(name) || (isstring(name) && isscalar(name)))
            error("pdmat:InvalidOptions", "pdmat option names must be strings or character vectors.");
        end
        name = string(name);
        switch name
            case "Degree"
                degOpt = varargin{k + 1};
            case {"IsContinuous", "ContainsDecision", "HasRateDependence", "RateBounds"}
                error("pdmat:UnsupportedOption", ...
                    "%s is fixed internally for pdmat and is not a constructor option.", name);
            otherwise
                error("pdmat:UnknownOption", "Unsupported pdmat option: %s.", name);
        end
    end
end
