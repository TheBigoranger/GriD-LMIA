function coeffs = applyGramPlan(gram, plan, validateInstance)
    %APPLYGRAMPLAN Realize one precomputed Bernstein-Gram coefficient map.

    if nargin < 3
        validateInstance = true;
    end
    if validateInstance
        validatePlanAndGram(gram, plan);
    end

    n = size(gram, 1) / plan.BasisCount;
    coeffs = repmat({zeros(n)}, 1, plan.TargetCount);
    for out = 1:plan.TargetCount
        value = zeros(n);
        diagonal = plan.Diagonal{out};
        for k = 1:size(diagonal, 1)
            basis = diagonal(k, 1);
            block = blockIndices(basis, n);
            value = value + diagonal(k, 2) * gram(block, block);
        end

        offDiagonal = plan.OffDiagonal{out};
        for k = 1:size(offDiagonal, 1)
            left = blockIndices(offDiagonal(k, 1), n);
            right = blockIndices(offDiagonal(k, 2), n);
            % Keep both ordered matrix blocks: for block-valued certificates
            % the paired contribution is Qij+Qji, not a scalar factor alone.
            value = value + offDiagonal(k, 3) * ...
                (gram(left, right) + gram(right, left));
        end
        coeffs{out} = value;
    end
end

function indices = blockIndices(basis, matrixSize)
    %BLOCKINDICES Return one basis-major matrix block.
    indices = (basis - 1) * matrixSize + (1:matrixSize);
end

function validatePlanAndGram(gram, plan)
    %VALIDATEPLANANDGRAM Check one distinct plan and compatible Gram block.
    required = ["BasisCount", "TargetCount", "TargetDegree", ...
        "OutputMultipliers", "Diagonal", "OffDiagonal"];
    if ~isstruct(plan) || ~all(isfield(plan, required)) || ...
            ~isscalar(plan.BasisCount) || plan.BasisCount < 1 || ...
            ~isscalar(plan.TargetCount) || plan.TargetCount < 1 || ...
            numel(plan.Diagonal) ~= plan.TargetCount || ...
            numel(plan.OffDiagonal) ~= plan.TargetCount
        error("pdlmi:InvalidGramPowers", ...
            "The Gram mapping plan is incomplete or incompatible.");
    end
    if size(gram, 1) ~= size(gram, 2) || ...
            mod(size(gram, 1), plan.BasisCount) ~= 0
        error("pdlmi:InvalidGramShape", ...
            "Gram matrix size must be a square multiple of the tensor basis size.");
    end
end
