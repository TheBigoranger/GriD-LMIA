classdef pdbase
    %PDBASE Shared cell-wise Bernstein storage for gridded PD-LMI objects.
    %
    %   Syntax:
    %     obj = pdbase(gridVectors, matrixSize, degree)
    %     obj = pdbase(gridVectors, matrixSize, degree, localValues, Name=Value)
    %
    %   Arguments:
    %     gridVectors - Cell array of strictly increasing parameter grids.
    %     matrixSize  - Positive [rows, columns] coefficient-matrix size.
    %     degree      - Nonnegative scalar shorthand or ell-element degree.
    %     localValues - Optional nested cell-wise coefficient tree.
    %     Continuity  - Scalar or ell-vector lower bound: -1, an integer
    %                   order, or Inf. pdbase stores but does not infer it.
    %     IsContinuous - Legacy parse-only alias: true maps to C0 and false
    %                    maps to -1; do not combine it with Continuity.
    %     Name=Value  - Decision, rate, source, and validation metadata.
    %
    %   Output:
    %     obj - Shared grid and coefficient-storage object whose Degree is
    %           stored as a 1-by-ell row vector.
    %
    %   Example:
    %     obj = pdbase({[0 1 2]}, [2 2], 1, Continuity=0);
    %     c = obj.coeffs(1);
    %     tf = obj.IsContinuous;
    %     elevated = obj.elevate(1);
    %
    %   IsContinuous is read-only and derived as all(Continuity >= 0); no
    %   separate Boolean continuity state is stored.

    properties (SetAccess = private)
        GridInfo
        MatrixSize
        Degree
        LocalValues
        Continuity
        ContainsDecision
        NumRateRows
        RateBounds
        SourceSummary
    end

    properties (Dependent, SetAccess = private)
        IsContinuous
    end

    methods
        function obj = pdbase(gridVectors, matrixSize, degree, varargin)
            [localValues, options] = argParser(varargin);
            validationMode = options.ValidationMode;

            % Normalize once at the parent layer so pdmat/pdvar/pdlmi can
            % share the same tensor-grid contract and label ordering.
            info = helper.mkGrid(gridVectors, "pdbase");
            sz = double(helper.chk(matrixSize, "pdbase:InvalidMatrixSize", ...
                "matrixSize", ...
                "numeric", "real", "finite", "integer", "positive", "Size", [1, 2]));

            nPar = numel(info.Vectors);
            deg = helper.normDeg(degree, nPar, ...
                "pdbase:InvalidDegree", "degree");
            rb = options.RateBounds;
            if isempty(rb)
                rb = [];
            else
                rb = double(helper.chk(rb, "pdbase:InvalidRateBounds", ...
                    "RateBounds", ...
                    "numeric", "real", "finite", "rowbounds", "Size", [nPar, 2]));
            end
            nRateRows = size(helper.rateVerts(rb), 1);
            if options.NumRateRows ~= 0 && isempty(rb)
                error("pdbase:InvalidRateBounds", ...
                    "Explicit rate rows must provide nonempty RateBounds.");
            end
            if options.NumRateRows ~= 0 && options.NumRateRows ~= nRateRows
                error("pdbase:InvalidRateBounds", ...
                    "NumRateRows must match the distinct RateBounds vertices.");
            end

            nCell = info.NumNodes - 1;
            nCoeff = prod(deg + 1);
            if isempty(localValues)
                % Default construction represents a coefficient-backed zero
                % object on every physical cell, not sampled node data.
                vals = helper.mkNest(nCell, ...
                    @(~) repmat({zeros(sz)}, 1, nCoeff));
                hasRate = false;
            else
                vals = localValues;
                [hasRate, rowKind] = chkVals(vals, nCell, nCoeff, sz, ...
                    nPar, nRateRows, options.NumRateRows ~= 0, validationMode);
            end
            if hasRate && isempty(rb)
                error("pdbase:InvalidRateBounds", ...
                    "Rate-affine coefficient payloads require nonempty RateBounds.");
            end

            obj.GridInfo = info;
            obj.MatrixSize = sz;
            obj.Degree = deg;
            obj.LocalValues = vals;
            % Continuity is a proven direction-wise lower bound. Subclasses
            % own the sharing or coefficient checks that justify it.
            obj.Continuity = normContinuity(options.Continuity, nPar);
            obj.ContainsDecision = options.ContainsDecision;
            % RateBounds stores the rho_dot domain independently of LocalValues.
            if isempty(localValues)
                obj.NumRateRows = 0;
            else
                if rowKind == "rate"
                    obj.NumRateRows = nRateRows;
                else
                    obj.NumRateRows = 0;
                end
            end
            obj.RateBounds = rb;
            obj.SourceSummary = options.SourceSummary;
        end


        function tf = get.IsContinuous(obj)
            tf = all(obj.Continuity >= 0);
        end
    end

    methods
        out = elevate(obj, degreeIncrement, validationMode)
        out = rhodiff(obj, rb)
    end

    methods (Access = protected)
        tbl = bernTbl(obj, errId, valFcn, exprFcn, rateVerts, varargin)
        rb = pickRateBounds(obj, errId, varargin)
        coeffs = joinRateRows(obj, leaves, fcn, errId)
        vals = prodVals(obj, lhsVals, lhsDeg, rhsVals, rhsDeg, ...
            grid, errId, validationMode, lhsNumRateRows, rhsNumRateRows)
        grid = mergeGrid(obj, errId, varargin)
        out = mapUnary(obj, fcn, sz)
        out = mkUnOp(obj, vals, sz)
        out = mkRhodiff(obj, deg, vals, rb, hasDec, numRateRows, continuity)
    end

    methods (Static, Access = protected)
        data = elevData(data, targetDegree, grid, validationMode)
        [out, plan] = elevRow(coeffs, fromDeg, toDeg, plan)
        vals = mapVals(vals, fcn, grid)
        [rows, cols] = matSubs(subs, sz, errId)
    end

end

function [localValues, options] = argParser(args)
    %ARGPARSER Parse optional coefficient storage and pdbase metadata.
    options = struct( ...
        "Continuity", -1, ...
        "ContainsDecision", false, ...
        "NumRateRows", 0, ...
        "RateBounds", [], ...
        "SourceSummary", "coefficient-backed", ...
        "ValidationMode", "fast");
    localValues = [];
    if isempty(args)
        return
    end

    % Report an unpaired ValidationMode before treating the first value as
    % optional LocalValues, so callers retain the dedicated mode error.
    lastArg = args{end};
    if (ischar(lastArg) && isrow(lastArg) && ...
            strcmp(lastArg, "ValidationMode")) || ...
            (isstring(lastArg) && isscalar(lastArg) && ...
            ~ismissing(lastArg) && lastArg == "ValidationMode")
        error("pdbase:InvalidValidationMode", ...
            "ValidationMode requires the scalar text 'fast' or 'strict'.");
    end

    names = ["Continuity", "IsContinuous", "ContainsDecision", "NumRateRows", ...
        "RateBounds", "SourceSummary", "ValidationMode"];
    first = args{1};
    firstName = "";
    if (ischar(first) && isrow(first)) || ...
            (isstring(first) && isscalar(first) && ~ismissing(first))
        firstName = string(first);
    end
    if numel(args) > 1 && any(firstName == names)
        optArgs = args;
    else
        localValues = first;
        optArgs = args(2:end);
    end
    if mod(numel(optArgs), 2) ~= 0
        error("pdbase:InvalidOptions", "pdbase options must be Name=Value pairs.");
    end

    seenContinuity = false;
    seenLegacyContinuity = false;
    for k = 1:2:numel(optArgs)
        name = optArgs{k};
        if ~((ischar(name) && isrow(name)) || ...
                (isstring(name) && isscalar(name) && ~ismissing(name)))
            error("pdbase:InvalidOptions", ...
                "pdbase option names must be strings or character vectors.");
        end
        name = string(name);
        value = optArgs{k + 1};
        switch name
            case "Continuity"
                if seenContinuity || seenLegacyContinuity
                    error("pdbase:ConflictingContinuityOptions", ...
                        "Continuity and IsContinuous may not be supplied together or repeated.");
                end
                options.Continuity = value;
                seenContinuity = true;
            case "IsContinuous"
                if seenContinuity || seenLegacyContinuity
                    error("pdbase:ConflictingContinuityOptions", ...
                        "Continuity and IsContinuous may not be supplied together or repeated.");
                end
                value = logical(value);
                if ~isscalar(value)
                    error("pdbase:InvalidOptions", "%s must be a scalar logical.", name);
                end
                if value
                    options.Continuity = 0;
                else
                    options.Continuity = -1;
                end
                seenLegacyContinuity = true;
            case "ContainsDecision"
                value = logical(value);
                if ~isscalar(value)
                    error("pdbase:InvalidOptions", "%s must be a scalar logical.", name);
                end
                options.ContainsDecision = value;
            case "NumRateRows"
                if ~(isnumeric(value) && isreal(value) && isscalar(value))
                    error("pdbase:InvalidOptions", ...
                        "NumRateRows must be a scalar numeric value.");
                end
                value = double(value);
                mustBeInteger(value)
                mustBeNonnegative(value)
                options.NumRateRows = value;
            case "RateBounds"
                options.RateBounds = value;
            case "SourceSummary"
                options.SourceSummary = value;
            case "ValidationMode"
                options.ValidationMode = helper.normMode(value, "pdbase");
            otherwise
                error("pdbase:UnknownOption", "Unsupported pdbase option: %s.", name);
        end
    end
end

function continuity = normContinuity(value, nPar)
    %NORMCONTINUITY Normalize internal continuity metadata without inference.
    if ~(isnumeric(value) && isreal(value) && isvector(value) && ...
            ~isempty(value) && all(~isnan(value), "all") && ...
            all(value == -1 | value == inf | ...
            (isfinite(value) & value >= 0 & value == fix(value)), "all"))
        error("pdbase:InvalidContinuity", ...
            "Continuity must contain -1, nonnegative integers, or Inf.");
    end
    if isscalar(value)
        continuity = repmat(double(value), 1, nPar);
    elseif numel(value) == nPar
        continuity = reshape(double(value), 1, []);
    else
        error("pdbase:InvalidContinuity", ...
            "Continuity must be scalar or have one entry per parameter.");
    end
end
