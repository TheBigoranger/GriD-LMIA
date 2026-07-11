classdef dpbase
    %DPBASE Shared cell-local Bernstein storage for gridded DP-LMI objects.
    %
    %   Syntax:
    %     obj = dpbase(gridVectors, matrixSize, degree)
    %     obj = dpbase(gridVectors, matrixSize, degree, localValues, Name=Value)
    %
    %   Example:
    %     obj = dpbase({[0 1 2]}, [2 2], 1);
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
        function obj = dpbase(gridVectors, matrixSize, degree, localValues, options)
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

            % Normalize once at the parent layer so dpmat/dpvar/dplmi can
            % share the same tensor-grid contract and label ordering.
            info = helper.mkGrid(gridVectors, "dpbase");
            sz = double(helper.chk(matrixSize, "dpbase:InvalidMatrixSize", ...
                "matrixSize must be a 1x2 positive integer vector.", ...
                "numeric", "real", "finite", "integer", "positive", "Size", [1, 2]));

            deg = double(helper.chk(degree, "dpbase:InvalidDegree", ...
                "degree must be a nonnegative integer scalar.", ...
                "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
            nPar = numel(info.Vectors);
            rb = options.RateBounds;
            if isempty(rb)
                rb = [];
            else
                rb = double(helper.chk(rb, "dpbase:InvalidRateBounds", ...
                    "RateBounds must be empty or a finite ell-by-2 matrix with lower <= upper.", ...
                    "numeric", "real", "finite", "rowbounds", "Size", [nPar, 2]));
            end
            if options.HasRateDependence && isempty(rb)
                error("dpbase:InvalidRateBounds", ...
                    "Rate-dependent objects must provide nonempty RateBounds.");
            end

            nCell = info.NumNodes - 1;
            nCoeff = (deg + 1) ^ nPar;
            if isempty(localValues)
                % Default construction represents a coefficient-backed zero
                % object on every physical cell, not sampled node data.
                vals = helper.mkVals(nCell, nCoeff, sz);
                hasRate = false;
            else
                vals = localValues;
                hasRate = helper.chkVals(vals, nCell, nCoeff, sz, nPar);
            end
            if hasRate && isempty(rb)
                error("dpbase:InvalidRateBounds", ...
                    "Rate-affine coefficient payloads require nonempty RateBounds.");
            end

            obj.GridInfo = info;
            obj.MatrixSize = sz;
            obj.Degree = deg;
            obj.LocalValues = vals;
            % Continuity is metadata at dpbase level; subclasses own any
            % boundary coefficient sharing needed to make it true.
            obj.IsContinuous = options.IsContinuous;
            obj.ContainsDecision = options.ContainsDecision;
            % rho_dot metadata is intentionally separate from LocalValues;
            % dplmi is the layer that will enumerate finite rate vertices.
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
