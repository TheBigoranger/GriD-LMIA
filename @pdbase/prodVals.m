function vals = prodVals(obj, lhsVals, lhsDeg, rhsVals, rhsDeg, ...
        grid, errId, validationMode, lhsNumRateRows, rhsNumRateRows)
    %PRODVALS Multiply complete cell-local Bernstein coefficient trees.
    %
    %   Syntax:
    %     vals = obj.prodVals(lhsVals, lhsDeg, rhsVals, rhsDeg, grid, errId)
    %     vals = obj.prodVals(lhsVals, lhsDeg, rhsVals, rhsDeg, grid, errId, ...
    %         validationMode, lhsNumRateRows, rhsNumRateRows)
    %
    %   Arguments:
    %     lhsVals        - Nested coefficient tree for the left operand.
    %     lhsDeg         - Bernstein degree of lhsVals.
    %     rhsVals        - Nested coefficient tree for the right operand.
    %     rhsDeg         - Bernstein degree of rhsVals.
    %     grid           - Common tensor grid after operand alignment.
    %     errId          - Error identifier owned by the public caller.
    %     validationMode - "fast" validates one representative cell; "strict"
    %                      validates every cell before multiplication.
    %     lhsNumRateRows - Zero or the left active distinct-vertex row count.
    %     rhsNumRateRows - Zero or the right active distinct-vertex row count.
    %
    %   Output:
    %     vals - Nested coefficient tree for the product at lhsDeg + rhsDeg.
    %
    %   Example:
    %     vals = obj.prodVals(lhs.LocalValues, lhs.Degree, ...
    %         rhs.LocalValues, rhs.Degree, lhs.GridInfo.Vectors, ...
    %         "pdmat:InvalidProduct", "fast");
    %
    %   This protected kernel owns the cell-local Bernstein convolution used
    %   by pdmat and pdvar multiplication. Ordinary rows may broadcast over one
    %   active derivative-rate table, but products with actual rate rows on
    %   both sides are rejected because they would be quadratic in rho_dot.

    if nargin < 8 || isempty(validationMode)
        validationMode = "fast";
    end
    if nargin < 9 || isempty(lhsNumRateRows)
        lhsNumRateRows = 0;
    end
    if nargin < 10 || isempty(rhsNumRateRows)
        rhsNumRateRows = 0;
    end
    lhsNumRateRows = double(helper.chk(lhsNumRateRows, ...
        "pdbase:InvalidRateRows", "numRateRows", ...
        "numeric", "real", "finite", "integer", "nonnegative", ...
        "scalar"));
    rhsNumRateRows = double(helper.chk(rhsNumRateRows, ...
        "pdbase:InvalidRateRows", "numRateRows", ...
        "numeric", "real", "finite", "integer", "nonnegative", ...
        "scalar"));
    nPar = obj.npar();
    plan = mkPlan(nPar, lhsDeg, rhsDeg);
    nCell = cellfun(@numel, grid) - 1;
    firstCell = true;
    vals = helper.mkNest(nCell, @prodAt);

    function coeffs = prodAt(subs)
        lhs = helper.cellGet(lhsVals, subs);
        rhs = helper.cellGet(rhsVals, subs);
        doChk = validationMode == "strict" || firstCell;
        [coeffs, plan] = prodRows(lhs, rhs, plan, ...
            lhsNumRateRows, rhsNumRateRows, errId, doChk);
        firstCell = false;
    end
end

function [coeffs, plan] = prodRows(lhs, rhs, plan, lhsRows, rhsRows, ...
        errId, doChk)
    %PRODROWS Broadcast an ordinary row over at most one rate-row operand.
    if doChk
        chkLeaf(lhs, rhs, plan, lhsRows, rhsRows, errId);
    end
    % Metadata distinguishes an ordinary row from a fixed one-vertex rate row.
    lhsRate = lhsRows ~= 0;
    rhsRate = rhsRows ~= 0;
    if lhsRate && rhsRate
        error(errId, ...
            "Products may contain actual rate-vertex rows on at most one side.");
    end
    if ~lhsRate && ~rhsRate
        [coeffs, plan] = prodRow(lhs, rhs, plan);
        return
    end
    nRows = max(size(lhs, 1), size(rhs, 1));
    coeffs = cell(nRows, plan.OutputCount);
    for row = 1:nRows
        left = lhs(min(row, size(lhs, 1)), :);
        right = rhs(min(row, size(rhs, 1)), :);
        [rowVals, plan] = prodRow(left, right, plan);
        coeffs(row, :) = rowVals;
    end
end

function [out, plan] = prodRow(lhs, rhs, plan)
    %PRODROW Select the numeric, known-affine, or generic local kernel.
    lhsNum = all(cellfun(@isnumeric, lhs));
    rhsNum = all(cellfun(@isnumeric, rhs));
    if lhsNum && rhsNum
        plan = addTenPlan(plan);
        out = numProd(lhs, rhs, plan);
        return
    end
    lhsAff = any(cellfun(@(val) isa(val, "sdpvar"), lhs));
    rhsAff = any(cellfun(@(val) isa(val, "sdpvar"), rhs));
    lhsScalar = isequal(size(lhs{1}), [1 1]);
    rhsScalar = isequal(size(rhs{1}), [1 1]);
    plan = addPairPlan(plan);
    if lhsNum && rhsAff && ~lhsScalar && ~rhsScalar
        out = affProd(lhs, rhs, plan, true);
    elseif lhsAff && rhsNum && ~lhsScalar && ~rhsScalar
        out = affProd(lhs, rhs, plan, false);
    else
        out = genProd(lhs, rhs, plan);
    end
end

function plan = mkPlan(nPar, lhsDeg, rhsDeg)
    %MKPLAN Normalize degrees before adding the required kernel plan lazily.
    lhsDeg = helper.normDeg(lhsDeg, nPar, ...
        "pdbase:InvalidDegree", "lhsDeg");
    rhsDeg = helper.normDeg(rhsDeg, nPar, ...
        "pdbase:InvalidDegree", "rhsDeg");
    outDeg = lhsDeg + rhsDeg;

    plan.NumParameters = nPar;
    plan.LhsDegree = lhsDeg;
    plan.RhsDegree = rhsDeg;
    plan.OutputDegree = outDeg;
    plan.LhsCount = prod(lhsDeg + 1);
    plan.RhsCount = prod(rhsDeg + 1);
    plan.OutputCount = prod(outDeg + 1);
end

function plan = addPairPlan(plan)
    %ADDPAIRPLAN Build coefficient pairs only for affine or generic products.
    if isfield(plan, "Pairs")
        return
    end
    lhsLbl = mkLbls(plan.LhsDegree);
    outLbl = mkLbls(plan.OutputDegree);
    % Map row-major tensor labels to flat repository positions.
    mult = fliplr(cumprod([1, fliplr(plan.RhsDegree(2:end) + 1)]));
    pairs = cell(size(outLbl, 1), 1);
    scales = cell(size(outLbl, 1), 1);
    counts = zeros(size(outLbl, 1), 1);
    pairCount = plan.LhsCount * plan.RhsCount;
    lhsPairLabels = zeros(pairCount, plan.NumParameters);
    rhsPairLabels = zeros(pairCount, plan.NumParameters);
    nextPair = 1;
    for k = 1:size(outLbl, 1)
        candidate = outLbl(k, :) - lhsLbl;
        keep = all(candidate >= 0, 2) & ...
            all(candidate <= plan.RhsDegree, 2);
        lhsIdx = find(keep);
        keptLabels = candidate(keep, :);
        rhsIdx = keptLabels * mult' + 1;
        pairs{k} = [lhsIdx, rhsIdx];
        counts(k) = numel(lhsIdx);
        range = nextPair:(nextPair + counts(k) - 1);
        lhsPairLabels(range, :) = lhsLbl(lhsIdx, :);
        rhsPairLabels(range, :) = keptLabels;
        nextPair = nextPair + counts(k);
    end
    allScales = helper.bernConvRatios(lhsPairLabels, plan.LhsDegree, ...
        rhsPairLabels, plan.RhsDegree);
    nextPair = 1;
    for k = 1:size(outLbl, 1)
        range = nextPair:(nextPair + counts(k) - 1);
        scales{k} = allScales(range);
        nextPair = nextPair + counts(k);
    end
    plan.Pairs = pairs;
    plan.Scales = scales;
end

function plan = addTenPlan(plan)
    %ADDTENPLAN Build tensor metadata only for numeric convolution.
    if isfield(plan, "LhsTensorIndices")
        return
    end
    lhsLbl = mkLbls(plan.LhsDegree);
    rhsLbl = mkLbls(plan.RhsDegree);
    outLbl = mkLbls(plan.OutputDegree);
    lhsW = helper.bernConvWeights(lhsLbl, plan.LhsDegree);
    rhsW = helper.bernConvWeights(rhsLbl, plan.RhsDegree);
    outW = helper.bernConvWeights(outLbl, plan.OutputDegree);
    plan.LhsWeights = lhsW;
    plan.RhsWeights = rhsW;
    plan.OutputWeights = outW;
    plan.LhsTensorIndices = tenIndex(lhsLbl, plan.LhsDegree);
    plan.RhsTensorIndices = tenIndex(rhsLbl, plan.RhsDegree);
    plan.OutputTensorIndices = tenIndex(outLbl, plan.OutputDegree);
    plan.LhsShape = tenShape(plan.LhsDegree, plan.NumParameters);
    plan.RhsShape = tenShape(plan.RhsDegree, plan.NumParameters);
    plan.OutputShape = tenShape(plan.OutputDegree, plan.NumParameters);
end

function chkLeaf(lhs, rhs, plan, lhsRows, rhsRows, errId)
    %CHKLEAF Validate one complete product cell before plan reuse.
    chkRows(lhs, plan.LhsCount, lhsRows, errId);
    chkRows(rhs, plan.RhsCount, rhsRows, errId);
    lhsSize = getSize(lhs, errId);
    rhsSize = getSize(rhs, errId);
    if ~isequal(lhsSize, [1 1]) && ~isequal(rhsSize, [1 1]) && ...
            lhsSize(2) ~= rhsSize(1)
        error(errId, ...
            "Product coefficient payloads have incompatible matrix dimensions.");
    end
end

function chkRows(rows, nCoeff, nRateRows, errId)
    %CHKROWS Check tensor coefficient and rate-row dimensions.
    expectedRows = max(1, nRateRows);
    if ~iscell(rows) || size(rows, 2) ~= nCoeff || ...
            size(rows, 1) ~= expectedRows
        error(errId, ...
            "Product coefficient rows do not match the planned tensor or rate shape.");
    end
end

function sz = getSize(rows, errId)
    %GETSIZE Validate supported payloads and their common matrix size.
    sz = [];
    for k = 1:numel(rows)
        val = rows{k};
        if isa(val, "sdpvar")
            valid = ismatrix(val) && isreal(val) && islinear(val);
        else
            valid = isnumeric(val) && ismatrix(val) && ~isempty(val) && ...
                isreal(val) && all(isfinite(val), "all");
        end
        if ~valid
            error(errId, ...
                "Product coefficients must be finite real numeric or affine real sdpvar matrices.");
        end
        if isempty(sz)
            sz = size(val);
        elseif ~isequal(size(val), sz)
            error(errId, ...
                "Every coefficient on one product side must have the same matrix size.");
        end
    end
end

function out = numProd(lhs, rhs, plan)
    %NUMPROD Apply binomial-weighted tensor convolution entry-wise.
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
    leftTen = packTen(lhs, lhsSize, plan.LhsShape, ...
        plan.LhsTensorIndices, plan.LhsWeights);
    rightTen = packTen(rhs, rhsSize, plan.RhsShape, ...
        plan.RhsTensorIndices, plan.RhsWeights);
    out = repmat({zeros(outSize)}, 1, plan.OutputCount);
    for row = 1:outSize(1)
        for col = 1:outSize(2)
            tensor = zeros(plan.OutputShape);
            for inner = 1:innerCount
                if lhsScalar
                    left = leftTen{1, 1};
                    right = rightTen{row, col};
                elseif rhsScalar
                    left = leftTen{row, col};
                    right = rightTen{1, 1};
                else
                    left = leftTen{row, inner};
                    right = rightTen{inner, col};
                end
                if plan.NumParameters == 1
                    tensor = tensor + conv(left(:), right(:));
                else
                    tensor = tensor + convn(left, right);
                end
            end
            values = tensor(plan.OutputTensorIndices) ./ plan.OutputWeights;
            for k = 1:plan.OutputCount
                out{k}(row, col) = values(k);
            end
        end
    end
end

function tensors = packTen(coeffs, sz, shape, indices, weights)
    %PACKTEN Pack all matrix entries into weighted coefficient tensors.
    nCoeff = numel(coeffs);
    stack = cat(3, coeffs{:});
    values = reshape(permute(stack, [3 1 2]), nCoeff, []);
    values = values .* weights;

    packed = zeros(prod(shape), prod(sz));
    packed(indices, :) = values;
    tensors = cell(sz);
    for entry = 1:prod(sz)
        tensors{entry} = reshape(packed(:, entry), shape);
    end
end

function out = affProd(lhs, rhs, plan, knownLeft)
    %AFFPROD Contract all contributing known-affine pairs at once.
    if knownLeft
        symbolic = vertcat(rhs{:});
        blockSize = size(rhs{1}, 1);
    else
        symbolic = horzcat(lhs{:});
        blockSize = size(lhs{1}, 2);
    end

    out = cell(1, plan.OutputCount);
    for outIdx = 1:plan.OutputCount
        pairs = plan.Pairs{outIdx};
        scales = plan.Scales{outIdx};
        nPair = size(pairs, 1);
        if knownLeft
            left = cell(1, nPair);
            for k = 1:nPair
                left{k} = lhs{pairs(k, 1)} .* scales(k);
            end
            rows = reshape((((pairs(:, 2) - 1) * blockSize) + ...
                (1:blockSize)).', [], 1);
            out{outIdx} = horzcat(left{:}) * symbolic(rows, :);
        else
            right = cell(nPair, 1);
            for k = 1:nPair
                right{k} = rhs{pairs(k, 2)} .* scales(k);
            end
            cols = reshape((((pairs(:, 1) - 1) * blockSize) + ...
                (1:blockSize)).', [], 1);
            out{outIdx} = symbolic(:, cols) * vertcat(right{:});
        end
    end
end

function out = genProd(lhs, rhs, plan)
    %GENPROD Accumulate the precomputed coefficient-pair map.
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

function indices = tenIndex(labels, degree)
    %TENINDEX Map repository labels into MATLAB tensor storage.
    mult = cumprod([1, degree(1:end - 1) + 1]);
    indices = labels * mult' + 1;
end

function shape = tenShape(degree, nPar)
    %TENSHAPE Keep one-parameter tensors as column vectors.
    shape = degree + 1;
    if nPar == 1
        shape = [degree + 1, 1];
    end
end

function labels = mkLbls(degree)
    %MKLBLS Enumerate tensor labels in repository coefficient order.
    labels = helper.combRows(arrayfun(@(d) 0:d, degree, ...
        "UniformOutput", false));
end
