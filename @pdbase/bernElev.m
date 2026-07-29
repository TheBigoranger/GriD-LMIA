function out = bernElev(coeffs, fromDeg, toDeg, nPar, plan, validateInstance)
    %BERNELEV Degree-elevate one cell's flat Bernstein coefficients.
    %
    %   Syntax:
    %     out = pdbase.bernElev(coeffs, fromDeg, toDeg, nPar)
    %
    %   Arguments:
    %     coeffs - Flat coefficients for one physical cell.
    %     fromDeg - Current scalar or per-parameter degree.
    %     toDeg   - Target scalar or per-parameter degree.
    %     nPar    - Number of parameter directions.
    %
    %   Output:
    %     out - Equivalent flat coefficients at toDeg.
    %
    %   Example (through the public elevation API):
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     vals = A.elevVals(1);

    if nargin < 5 || isempty(plan)
        plan = pdbase.elevationPlan(fromDeg, toDeg, nPar);
    end
    if nargin < 6
        validateInstance = true;
    end
    if validateInstance
        sanChk(fromDeg, toDeg, coeffs, nPar, plan);
    end

    if isequal(toDeg, fromDeg)
        out = coeffs;
        return
    end

    matrixColumns = size(coeffs{1}, 2);
    % Coefficients are packed as adjacent matrix-column blocks. kron(E',I)
    % elevates those blocks without mixing physical matrix columns or rows.
    packed = horzcat(coeffs{:});
    packed = packed * kron(plan.Operator', speye(matrixColumns));
    if isnumeric(packed)
        packed = full(packed);
    end
    out = cell(1, plan.TargetCount);
    for targetIdx = 1:plan.TargetCount
        columns = (targetIdx - 1) * matrixColumns + (1:matrixColumns);
        out{targetIdx} = packed(:, columns);
    end
end

function sanChk(fromDeg, toDeg, coeffs, nPar, plan)
    %SANCHK Validate degree bounds and the flat tensor coefficient count.
    fromDeg = helper.normalizeDegree(fromDeg, nPar, ...
        "pdbase:InvalidDegree", "fromDeg");
    toDeg = helper.normalizeDegree(toDeg, nPar, ...
        "pdbase:InvalidDegree", "toDeg");
    if any(toDeg < fromDeg)
        error("pdbase:InvalidDegreeElevation", ...
            "Cannot degree-elevate to a lower degree in any parameter direction.");
    end
    if ~isequal(fromDeg, plan.FromDegree) || ...
            ~isequal(toDeg, plan.ToDegree) || ...
            nPar ~= plan.NumParameters
        error("pdbase:InvalidDegreeElevation", ...
            "The elevation plan does not match the requested tensor degrees.");
    end
    expected = prod(fromDeg + 1);
    helper.chk(coeffs, "pdbase:InvalidCoefficientCell", ...
        "Coefficient cell count must match the source degree and parameter dimension.", ...
        "cell", "Size", [1, expected]);
    matrixSize = [];
    for k = 1:numel(coeffs)
        value = coeffs{k};
        if isa(value, "sdpvar")
            valid = ismatrix(value) && isreal(value) && islinear(value);
        else
            valid = isnumeric(value) && ismatrix(value) && ...
                ~isempty(value) && isreal(value) && ...
                all(isfinite(value), "all");
        end
        if ~valid
            error("pdbase:InvalidCoefficientPayload", ...
                "Elevation coefficients must be finite real numeric or affine real sdpvar matrices.");
        end
        if isempty(matrixSize)
            matrixSize = size(value);
        elseif ~isequal(size(value), matrixSize)
            error("pdbase:InvalidCoefficientPayload", ...
                "Every coefficient in one elevation row must have the same matrix size.");
        end
    end
    if ~isnumeric(plan.Operator) || ...
            ~isequal(size(plan.Operator), ...
            [plan.TargetCount, plan.SourceCount])
        error("pdbase:InvalidDegreeElevation", ...
            "The elevation operator does not match its declared tensor shape.");
    end
end
