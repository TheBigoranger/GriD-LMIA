function out = bernProd(obj, lhs, lhsDeg, rhs, rhsDeg, plan, validateInstance)
    %BERNPROD Cell-local Bernstein coefficient product.
    %
    %   Syntax:
    %     out = bernProd(obj, lhs, lhsDeg, rhs, rhsDeg)
    %
    %   Arguments:
    %     lhs, rhs      - Flat coefficient rows for one physical cell.
    %     lhsDeg, rhsDeg - Scalar Bernstein degrees of the operands.
    %
    %   Output:
    %     out - Product coefficients at degree lhsDeg + rhsDeg.
    %
    %   Example (through public pdmat multiplication):
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     B = pdmat({[0 1]}, {3, 4}, Degree=1);
    %     C = A * B;

    if nargin < 6 || isempty(plan)
        plan = obj.productPlan(lhsDeg, rhsDeg);
    end
    if nargin < 7
        validateInstance = true;
    end
    if validateInstance
        sanChk(lhsDeg, rhsDeg, lhs, rhs, plan);
    end

    lhsNumeric = all(cellfun(@isnumeric, lhs));
    rhsNumeric = all(cellfun(@isnumeric, rhs));
    if lhsNumeric && rhsNumeric
        out = numericProduct(lhs, rhs, plan);
        return
    end

    lhsAffine = any(cellfun(@(val) isa(val, "sdpvar"), lhs));
    rhsAffine = any(cellfun(@(val) isa(val, "sdpvar"), rhs));
    lhsScalar = isequal(size(lhs{1}), [1 1]);
    rhsScalar = isequal(size(rhs{1}), [1 1]);
    if lhsNumeric && rhsAffine && ~lhsScalar && ~rhsScalar
        out = blockProduct(lhs, rhs, plan, true);
    elseif lhsAffine && rhsNumeric && ~lhsScalar && ~rhsScalar
        out = blockProduct(lhs, rhs, plan, false);
    else
        out = genericProduct(lhs, rhs, plan);
    end
end

function sanChk(lhsDeg, rhsDeg, lhs, rhs, plan)
    %SANCHK Validate both degrees and their flat tensor coefficient counts.
    lhsDeg = double(helper.chk(lhsDeg, "pdbase:InvalidDegree", ...
        "lhsDeg must be a nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));
    rhsDeg = double(helper.chk(rhsDeg, "pdbase:InvalidDegree", ...
        "rhsDeg must be a nonnegative integer scalar.", ...
        "numeric", "real", "scalar", "finite", "integer", "nonnegative"));

    if lhsDeg ~= plan.LhsDegree || rhsDeg ~= plan.RhsDegree
        error("pdbase:InvalidDegree", ...
            "The product plan degrees must match the coefficient rows.");
    end
    helper.chk(lhs, "pdbase:InvalidCoefficientCell", ...
        "Coefficient cell counts must match operand degrees and parameter dimension.", ...
        "cell", "Size", [1, plan.LhsCount]);
    helper.chk(rhs, "pdbase:InvalidCoefficientCell", ...
        "Coefficient cell counts must match operand degrees and parameter dimension.", ...
        "cell", "Size", [1, plan.RhsCount]);
end

function out = numericProduct(lhs, rhs, plan)
    %NUMERICPRODUCT Apply binomial-weighted tensor convolution entry-wise.
    lhsSize = size(lhs{1});
    rhsSize = size(rhs{1});
    lhsScalar = isequal(lhsSize, [1 1]);
    rhsScalar = isequal(rhsSize, [1 1]);
    if lhsScalar
        outSize = rhsSize;
        innerCount = 1;
    elseif rhsScalar
        outSize = lhsSize;
        innerCount = 1;
    else
        outSize = [lhsSize(1), rhsSize(2)];
        innerCount = lhsSize(2);
    end
    leftTensors = packTensors(lhs, lhsSize, plan.LhsShape, ...
        plan.LhsTensorIndices, plan.LhsWeights);
    rightTensors = packTensors(rhs, rhsSize, plan.RhsShape, ...
        plan.RhsTensorIndices, plan.RhsWeights);
    out = repmat({zeros(outSize)}, 1, plan.OutputCount);

    for row = 1:outSize(1)
        for col = 1:outSize(2)
            tensor = zeros(plan.OutputShape);
            for inner = 1:innerCount
                % Matrix multiplication is the sum, over the physical inner
                % dimension, of independent parameter-tensor convolutions.
                if lhsScalar
                    lhsRow = 1;
                    lhsCol = 1;
                    rhsRow = row;
                    rhsCol = col;
                elseif rhsScalar
                    lhsRow = row;
                    lhsCol = col;
                    rhsRow = 1;
                    rhsCol = 1;
                else
                    lhsRow = row;
                    lhsCol = inner;
                    rhsRow = inner;
                    rhsCol = col;
                end
                left = leftTensors{lhsRow, lhsCol};
                right = rightTensors{rhsRow, rhsCol};
                if plan.NumParameters == 1
                    tensor = tensor + conv(left(:), right(:));
                else
                    tensor = tensor + convn(left, right);
                end
            end
            values = tensor(plan.OutputTensorIndices) ./ ...
                plan.OutputWeights;
            for k = 1:plan.OutputCount
                out{k}(row, col) = values(k);
            end
        end
    end
end

function tensors = packTensors(coeffs, matrixSize, shape, indices, weights)
    %PACKTENSORS Pack every matrix entry into a weighted coefficient tensor.
    tensors = cell(matrixSize);
    for row = 1:matrixSize(1)
        for col = 1:matrixSize(2)
            tensor = zeros(shape);
            values = cellfun(@(mat) mat(row, col), coeffs);
            tensor(indices) = values(:) .* weights;
            tensors{row, col} = tensor;
        end
    end
end

function out = blockProduct(lhs, rhs, plan, knownLeft)
    %BLOCKPRODUCT Contract all contributing known-affine pairs at once.
    out = cell(1, plan.OutputCount);
    for outIdx = 1:plan.OutputCount
        pairs = plan.Pairs{outIdx};
        scales = plan.Scales{outIdx};
        leftBlocks = cell(1, size(pairs, 1));
        rightBlocks = cell(size(pairs, 1), 1);
        for k = 1:size(pairs, 1)
            if knownLeft
                % Horizontal known blocks times vertical affine blocks sums
                % scaled Ai*Bi contributions without reversing their order.
                leftBlocks{k} = lhs{pairs(k, 1)} .* scales(k);
                rightBlocks{k} = rhs{pairs(k, 2)};
            else
                % Keep affine Ai on the left; scale the known Bi block before
                % the same horizontal-by-vertical contraction.
                leftBlocks{k} = lhs{pairs(k, 1)};
                rightBlocks{k} = rhs{pairs(k, 2)} .* scales(k);
            end
        end
        out{outIdx} = horzcat(leftBlocks{:}) * vertcat(rightBlocks{:});
    end
end

function out = genericProduct(lhs, rhs, plan)
    %GENERICPRODUCT Accumulate the precomputed coefficient-pair map.
    out = cell(1, plan.OutputCount);
    for outIdx = 1:plan.OutputCount
        pairs = plan.Pairs{outIdx};
        scales = plan.Scales{outIdx};
        acc = [];
        for k = 1:size(pairs, 1)
            term = (lhs{pairs(k, 1)} * rhs{pairs(k, 2)}) .* scales(k);
            if isempty(acc)
                acc = term;
            else
                acc = acc + term;
            end
        end
        out{outIdx} = acc;
    end
end
