classdef pdbase
    %PDBASE Shared cell-local Bernstein storage for gridded PD-LMI objects.
    %
    %   Syntax:
    %     obj = pdbase(gridVectors, matrixSize, degree)
    %     obj = pdbase(gridVectors, matrixSize, degree, localValues, Name=Value)
    %
    %   Arguments:
    %     gridVectors - Cell array of strictly increasing parameter grids.
    %     matrixSize  - Positive [rows, columns] coefficient-matrix size.
    %     degree      - Nonnegative scalar Bernstein degree per parameter.
    %     localValues - Optional nested cell-local coefficient tree.
    %     Name=Value  - Continuity, decision, rate, and source metadata.
    %
    %   Output:
    %     obj - Shared grid and coefficient-storage object.
    %
    %   Example:
    %     obj = pdbase({[0 1 2]}, [2 2], 1);
    %     c = obj.coeffs(1);
    %     elevated = obj.elevVals(1);

    properties (SetAccess = private)
        GridInfo
        MatrixSize
        Degree
        LocalValues
        IsContinuous
        ContainsDecision
        HasRateDependence
        RateBounds
        SourceSummary
    end

    methods
        function obj = pdbase(gridVectors, matrixSize, degree, varargin)
            if ~isempty(varargin) && isValidationModeName(varargin{end})
                error("pdbase:InvalidValidationMode", ...
                    "ValidationMode requires the scalar text 'fast' or 'strict'.");
            end
            [localValues, options] = parseConstructorOptions(varargin{:});

            validationMode = normalizeValidationMode( ...
                options.ValidationMode, "pdbase");

            % Normalize once at the parent layer so pdmat/pdvar/pdlmi can
            % share the same tensor-grid contract and label ordering.
            info = helper.mkGrid(gridVectors, "pdbase");
            sz = double(helper.chk(matrixSize, "pdbase:InvalidMatrixSize", ...
                "matrixSize must be a 1x2 positive integer vector.", ...
                "numeric", "real", "finite", "integer", "positive", "Size", [1, 2]));

            deg = double(helper.chk(degree, "pdbase:InvalidDegree", ...
                "degree must be a nonnegative integer scalar.", ...
                "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
            nPar = numel(info.Vectors);
            rb = options.RateBounds;
            if isempty(rb)
                rb = [];
            else
                rb = double(helper.chk(rb, "pdbase:InvalidRateBounds", ...
                    "RateBounds must be empty or a finite ell-by-2 matrix with lower <= upper.", ...
                    "numeric", "real", "finite", "rowbounds", "Size", [nPar, 2]));
            end
            if options.HasRateDependence && isempty(rb)
                error("pdbase:InvalidRateBounds", ...
                    "Rate-dependent objects must provide nonempty RateBounds.");
            end

            nCell = info.NumNodes - 1;
            nCoeff = (deg + 1) ^ nPar;
            if isempty(localValues)
                % Default construction represents a coefficient-backed zero
                % object on every physical cell, not sampled node data.
                vals = helper.mkNest(nCell, ...
                    @(~) repmat({zeros(sz)}, 1, nCoeff));
                hasRate = false;
            else
                vals = localValues;
                hasRate = chkVals(vals, nCell, nCoeff, sz, nPar, ...
                    validationMode);
            end
            if hasRate && isempty(rb)
                error("pdbase:InvalidRateBounds", ...
                    "Rate-affine coefficient payloads require nonempty RateBounds.");
            end

            obj.GridInfo = info;
            obj.MatrixSize = sz;
            obj.Degree = deg;
            obj.LocalValues = vals;
            % Continuity is metadata at pdbase level; subclasses own any
            % boundary coefficient sharing needed to make it true.
            obj.IsContinuous = options.IsContinuous;
            obj.ContainsDecision = options.ContainsDecision;
            % rho_dot metadata is intentionally separate from LocalValues;
            % pdlmi is the layer that will enumerate finite rate vertices.
            obj.HasRateDependence = options.HasRateDependence || ~isempty(rb);
            obj.RateBounds = rb;
            obj.SourceSummary = options.SourceSummary;
        end
    end

    methods
        vals = elevVals(obj, degreeIncrement, validationMode)
        out = elevate(obj, degreeIncrement)
        out = rhodiff(obj, rb)
    end

    methods (Access = protected)
        out = bernProd(obj, lhs, lhsDeg, rhs, rhsDeg, varargin)
        tbl = bernTbl(obj, errId, valFcn, exprFcn, rateVerts, varargin)
        tf = hasRateRows(obj)
        rb = pickRateBounds(obj, errId, varargin)
        coeffs = joinRateRows(obj, leaves, fcn, errId)
        vals = zipRateRows(obj, lhsVals, rhsVals, fcn, grid, errId)
        coeffs = prodRateRows(obj, lhs, lhsDeg, rhs, rhsDeg, errId, varargin)
        vals = prodLocalValues(obj, lhsVals, lhsDeg, rhsVals, rhsDeg, ...
            grid, errId, plan, varargin)
        plan = productPlan(obj, lhsDeg, rhsDeg)
        grid = mergeGrid(obj, errId, varargin)
        out = unOp(obj, fcn, sz)
        out = mkUnOp(obj, vals, sz)
        out = mkRhodiff(obj, deg, vals, rb, hasDec)
    end

    methods (Static, Access = protected)
        out = bernElev(coeffs, fromDeg, toDeg, nPar, varargin)
        plan = elevationPlan(fromDeg, toDeg, nPar)
        data = alignLocalDegrees(data, targetDegree, grid, validationMode)
        vals = elevLocalValues(vals, fromDeg, toDeg, grid, varargin)
        vals = mapVals(vals, fcn, grid)
        [rows, cols] = matSubs(subs, sz, errId)
    end

end

function [localValues, options] = parseConstructorOptions(localValues, options)
            arguments
                localValues = []
                options.IsContinuous (1, 1) logical = false
                options.ContainsDecision (1, 1) logical = false
                options.HasRateDependence (1, 1) logical = false
                options.RateBounds = []
                options.SourceSummary = "coefficient-backed"
                options.ValidationMode = "fast"
            end
end

function tf = isValidationModeName(value)
    %ISVALIDATIONMODENAME Detect a dangling public ValidationMode name.
    tf = (ischar(value) && isrow(value) && strcmp(value, "ValidationMode")) || ...
        (isstring(value) && isscalar(value) && ~ismissing(value) && ...
        value == "ValidationMode");
end

function mode = normalizeValidationMode(value, owner)
    %NORMALIZEVALIDATIONMODE Validate the transient structural-check policy.
    if ~((ischar(value) && isrow(value) && ~isempty(value)) || ...
            (isstring(value) && isscalar(value) && ~ismissing(value)))
        error(owner + ":InvalidValidationMode", ...
            "ValidationMode must be the scalar text 'fast' or 'strict'.");
    end
    mode = lower(string(value));
    if ~any(mode == ["fast", "strict"])
        error(owner + ":InvalidValidationMode", ...
            "ValidationMode must be the scalar text 'fast' or 'strict'.");
    end
end
