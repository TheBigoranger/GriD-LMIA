classdef dpmat < dpbase
    %DPMAT Known matrix data on a parameter grid.
    %
    %   Syntax:
    %     A = dpmat(gridVectors, source)
    %     A = dpmat(gridVectors, source, Degree=m)
    %
    %   source may be a function handle, a global cell grid of numeric
    %   Bernstein coefficients, or nested LocalValues in the dpbase contract.
    %   Function-backed objects without Degree only probe the lower grid
    %   point for size; inherited LocalValues are placeholder zeros, not
    %   coefficient evidence. Function handles with explicit Degree are
    %   validated as local Bernstein data while retaining FunctionHandle.
    %
    %   Example:
    %     data = {1, 2, 3};
    %     A = dpmat([0 1 2], data, Degree=1);
    %     c = A.coeffs(2);

    properties (SetAccess = private)
        FunctionHandle
    end

    methods
        function obj = dpmat(gridVectors, source, varargin)
            degOpt = parseOptions(varargin{:});
            if isnumeric(gridVectors) && isvector(gridVectors) && numel(gridVectors) >= 2
                % Accept scalar-parameter shorthand at the public entry;
                % dpbase still receives its strict cell-vector grid contract.
                gridVectors = {gridVectors};
            end

            [sz, deg, vals, summary, fh] = mkData(gridVectors, source, degOpt);

            % All dpmat sources are known numeric data in this first pass:
            % no YALMIP decisions and no rho_dot dependence enter the parent.
            obj@dpbase(gridVectors, sz, deg, vals, ...
                IsContinuous=true, ...
                ContainsDecision= false, ...
                HasRateDependence=false, ...
                RateBounds=[], ...
                SourceSummary=summary);

            obj.FunctionHandle = fh;
        end
    end

end

function degOpt = parseOptions(varargin)
    degOpt = [];
    if mod(numel(varargin), 2) ~= 0
        error("dpmat:InvalidOptions", "dpmat options must be Name=Value pairs.");
    end

    for k = 1:2:numel(varargin)
        name = varargin{k};
        if ~(ischar(name) || (isstring(name) && isscalar(name)))
            error("dpmat:InvalidOptions", "dpmat option names must be strings or character vectors.");
        end
        name = string(name);
        switch name
            case "Degree"
                degOpt = varargin{k + 1};
            case {"IsContinuous", "ContainsDecision", "HasRateDependence", "RateBounds"}
                error("dpmat:UnsupportedOption", ...
                    "%s is fixed internally for dpmat and is not a constructor option.", name);
            otherwise
                error("dpmat:UnknownOption", "Unsupported dpmat option: %s.", name);
        end
    end
end
