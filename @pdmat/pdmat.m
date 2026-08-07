classdef pdmat < pdbase
    %PDMAT Known matrix data on a parameter grid.
    %
    %   Syntax:
    %     A = pdmat(gridVectors, source)
    %     A = pdmat(gridVectors, source, Degree=m, RateBounds=rb)
    %
    %   Arguments:
    %     gridVectors - Parameter grid cell array or one-vector shorthand.
    %     source      - Function handle, global coefficient grid, or LocalValues.
    %     Degree      - Optional scalar shorthand or ell-element Bernstein degree.
    %     RateBounds  - Optional ell-by-2 parameter-rate box.
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
    %   Public Degree is a 1-by-ell row vector. Explicit multidimensional
    %   scalar Degree expands uniformly and warns once; omitted inference and
    %   one-dimensional construction remain warning-free.
    %   RateBounds alone is metadata. Explicit nested leaves may instead use
    %   one row per distinct vertex, ordered by combRows(RateBounds); fixed
    %   directions contribute one value instead of duplicate endpoints.
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
                if isfield(init, "NumRateRows")
                    numRateRows = init.NumRateRows;
                else
                    numRateRows = 0;
                end
                if isfield(init, "RateBounds")
                    rb = init.RateBounds;
                else
                    rb = [];
                end
                if isfield(init, "ValidationMode")
                    validationMode = helper.normMode( ...
                        init.ValidationMode, "pdmat");
                else
                    validationMode = "fast";
                end
                warnCont = false;
            else
                [degOpt, degreeSpecified, rbOpt, validationMode] = ...
                    parseOpts(varargin{:});
                if isnumeric(gridVectors) && isvector(gridVectors) && numel(gridVectors) >= 2
                    % Accept scalar-parameter shorthand at the public entry;
                    % pdbase still receives its strict cell-vector grid contract.
                    gridVectors = {gridVectors};
                end

                grid = gridVectors;
                [sz, deg, vals, isCont, summary, fh, rb] = ...
                    normSource(grid, source, degOpt, degreeSpecified, rbOpt);
                numRateRows = 0;
                warnCont = ~isCont;
            end

            % pdmat remains known numeric data; RateBounds is independent
            % metadata unless explicit LocalValues contain rate-vertex rows.
            obj@pdbase(grid, sz, deg, vals, ...
                IsContinuous=isCont, ...
                ContainsDecision= false, ...
                NumRateRows=numRateRows, ...
                RateBounds=rb, ...
                SourceSummary=summary, ...
                ValidationMode=validationMode);

            obj.FunctionHandle = fh;
            if warnCont
                warning("pdmat:DiscontinuousLocalValues", ...
                    "Nested LocalValues have mismatched shared Bernstein faces; IsContinuous is false.");
            end
        end
    end

    methods (Access = protected)
        out = mkUnOp(obj, vals, sz)
        out = mkRhodiff(obj, deg, vals, rb, hasDec, numRateRows)
    end

end

function [degOpt, degreeSpecified, rbOpt, validationMode] = parseOpts(varargin)
    %PARSEOPTS Parse optional Bernstein degree and rate metadata.
    degOpt = [];
    degreeSpecified = false;
    rbOpt = [];
    validationMode = "fast";
    seenDegree = false;
    seenRate = false;
    seenValidation = false;
    if mod(numel(varargin), 2) ~= 0
        if ~isempty(varargin) && ...
                ((ischar(varargin{end}) && strcmp(varargin{end}, "ValidationMode")) || ...
                (isstring(varargin{end}) && isscalar(varargin{end}) && ...
                ~ismissing(varargin{end}) && varargin{end} == "ValidationMode"))
            error("pdmat:InvalidValidationMode", ...
                "ValidationMode requires the scalar text 'fast' or 'strict'.");
        end
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
                if seenDegree
                    error("pdmat:DuplicateOption", ...
                        "Degree may be supplied only once.");
                end
                degOpt = varargin{k + 1};
                seenDegree = true;
                degreeSpecified = true;
            case "RateBounds"
                if seenRate
                    error("pdmat:DuplicateOption", ...
                        "RateBounds may be supplied only once.");
                end
                rbOpt = varargin{k + 1};
                seenRate = true;
            case "ValidationMode"
                if seenValidation
                    error("pdmat:InvalidValidationMode", ...
                        "ValidationMode may be supplied only once.");
                end
                validationMode = helper.normMode(varargin{k + 1}, "pdmat");
                seenValidation = true;
            case {"IsContinuous", "ContainsDecision"}
                error("pdmat:UnsupportedOption", ...
                    "%s is fixed internally for pdmat and is not a constructor option.", name);
            otherwise
                error("pdmat:UnknownOption", "Unsupported pdmat option: %s.", name);
        end
    end
end
