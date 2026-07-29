function coeffs = prodRateRows(obj, lhs, lhsDeg, rhs, rhsDeg, errId, plan, validateInstance)
    %PRODRATEROWS Multiply Bernstein rows with at most one rate-row operand.
    %
    %   Matrix multiplication order is preserved. Ordinary rows broadcast to
    %   every active rate vertex before the shared Bernstein convolution.

    if nargin < 7 || isempty(plan)
        plan = obj.productPlan(lhsDeg, rhsDeg);
    end
    if nargin < 8
        validateInstance = true;
    end
    if validateInstance
        validateProductLeaf(obj, lhs, lhsDeg, rhs, rhsDeg, ...
            plan, errId);
    end
    lhsRate = size(lhs, 1) > 1;
    rhsRate = size(rhs, 1) > 1;
    if lhsRate && rhsRate
        error(errId, ...
            "Products may contain actual rate-vertex rows on at most one side.");
    end

    if ~lhsRate && ~rhsRate
        coeffs = obj.bernProd(lhs, lhsDeg, rhs, rhsDeg, ...
            plan, false);
        return
    end

    nRows = max(size(lhs, 1), size(rhs, 1));
    nCoeff = prod(lhsDeg + rhsDeg + 1);
    coeffs = cell(nRows, nCoeff);
    for row = 1:nRows
        lhsRow = min(row, size(lhs, 1));
        rhsRow = min(row, size(rhs, 1));
        coeffs(row, :) = obj.bernProd(lhs(lhsRow, :), lhsDeg, ...
            rhs(rhsRow, :), rhsDeg, plan, false);
    end
end

function validateProductLeaf(obj, lhs, lhsDeg, rhs, rhsDeg, plan, errId)
    %VALIDATEPRODUCTLEAF Check one complete cell against its product plan.
    if ~isequal(lhsDeg, plan.LhsDegree) || ...
            ~isequal(rhsDeg, plan.RhsDegree)
        error(errId, ...
            "Product-plan degrees do not match the operand coefficient rows.");
    end
    validateRows(lhs, plan.LhsCount, obj.npar(), errId);
    validateRows(rhs, plan.RhsCount, obj.npar(), errId);

    lhsSize = uniformPayloadSize(lhs, errId);
    rhsSize = uniformPayloadSize(rhs, errId);
    lhsScalar = isequal(lhsSize, [1 1]);
    rhsScalar = isequal(rhsSize, [1 1]);
    if ~lhsScalar && ~rhsScalar && lhsSize(2) ~= rhsSize(1)
        error(errId, ...
            "Product coefficient payloads have incompatible matrix dimensions.");
    end
end

function validateRows(rows, expectedColumns, nPar, errId)
    %VALIDATEROWS Check coefficient count and ordinary/rate row shape.
    if ~iscell(rows) || size(rows, 2) ~= expectedColumns || ...
            ~any(size(rows, 1) == [1, 2 ^ nPar])
        error(errId, ...
            "Product coefficient rows do not match the planned tensor or rate shape.");
    end
end

function matrixSize = uniformPayloadSize(rows, errId)
    %UNIFORMPAYLOADSIZE Validate supported payloads and one matrix size.
    matrixSize = [];
    for k = 1:numel(rows)
        value = rows{k};
        if isa(value, "sdpvar")
            valid = ismatrix(value) && isreal(value) && islinear(value);
        else
            valid = isnumeric(value) && ismatrix(value) && ...
                ~isempty(value) && isreal(value) && ...
                all(isfinite(value), "all");
        end
        if ~valid
            error(errId, ...
                "Product coefficients must be finite real numeric or affine real sdpvar matrices.");
        end
        if isempty(matrixSize)
            matrixSize = size(value);
        elseif ~isequal(size(value), matrixSize)
            error(errId, ...
                "Every coefficient on one product side must have the same matrix size.");
        end
    end
end
