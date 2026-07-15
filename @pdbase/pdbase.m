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
        function obj = pdbase(gridVectors, matrixSize, degree, localValues, options)
            arguments
                gridVectors
                matrixSize
                degree
                localValues = []
                options.IsContinuous (1, 1) logical = false
                options.ContainsDecision (1, 1) logical = false
                options.HasRateDependence (1, 1) logical = false
                options.RateBounds = []
                options.SourceSummary = "coefficient-backed"
            end

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
                hasRate = chkVals(vals, nCell, nCoeff, sz, nPar);
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

        vals = elevVals(obj, degreeIncrement)
    end

    methods (Access = protected)
        out = bernElev(obj, coeffs, fromDeg, toDeg)
        vals = elevLocalValues(obj, vals, fromDeg, toDeg, grid)
        out = bernProd(obj, lhs, lhsDeg, rhs, rhsDeg)
        grid = mergeGrid(obj, errId, varargin)
    end

end
