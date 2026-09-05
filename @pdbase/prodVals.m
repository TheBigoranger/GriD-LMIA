function vals = prodVals(obj, lhsVals, lhsDeg, rhsVals, rhsDeg, ...
        grid, errId, validationMode, lhsNumRateRows, rhsNumRateRows)
    %PRODVALS Multiply complete cell-wise Bernstein coefficient trees.
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
    %   This protected kernel owns the cell-wise Bernstein convolution used
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
    plan = addPairPlan(plan);
    nCell = cellfun(@numel, grid) - 1;
    firstCell = true;
    vals = helper.mkNest(nCell, @prodAt);

    function coeffs = prodAt(subs)
        lhs = helper.cellGet(lhsVals, subs);
        rhs = helper.cellGet(rhsVals, subs);
        doChk = validationMode == "strict" || firstCell;
        coeffs = prodRows(lhs, rhs, plan, ...
            lhsNumRateRows, rhsNumRateRows, errId, doChk);
        firstCell = false;
    end
end

function coeffs = prodRows(lhs, rhs, plan, lhsRows, rhsRows, ...
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
        coeffs = prodRow(lhs, rhs, plan);
        return
    end
    nRows = max(size(lhs, 1), size(rhs, 1));
    coeffs = cell(nRows, plan.OutputCount);
    for row = 1:nRows
        left = lhs(min(row, size(lhs, 1)), :);
        right = rhs(min(row, size(rhs, 1)), :);
        rowVals = prodRow(left, right, plan);
        coeffs(row, :) = rowVals;
    end
end

function out = prodRow(lhs, rhs, plan)
    %PRODROW Contract weighted coefficient blocks for numeric or affine data.
    knownLeft = all(cellfun(@isnumeric, lhs));
    lhsSize = size(lhs{1});
    rhsSize = size(rhs{1});
    reshapeOutput = false;
    % Flatten the matrix factor for scalar multiplication so the same block
    % contraction applies without expanding scalars into identity matrices.
    if isequal(lhsSize, [1 1]) && ~isequal(rhsSize, [1 1])
        outSize = rhsSize;
        rhs = cellfun(@(a) reshape(a, 1, []), rhs, UniformOutput=false);
        reshapeOutput = true;
    elseif isequal(rhsSize, [1 1]) && ~isequal(lhsSize, [1 1])
        outSize = lhsSize;
        lhs = cellfun(@(a) reshape(a, [], 1), lhs, UniformOutput=false);
        reshapeOutput = true;
    end
    if knownLeft
        blocks = vertcat(rhs{:});
        blockSize = size(rhs{1}, 1);
    else
        blocks = horzcat(lhs{:});
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
            out{outIdx} = horzcat(left{:}) * blocks(rows, :);
        else
            right = cell(nPair, 1);
            for k = 1:nPair
                right{k} = rhs{pairs(k, 2)} .* scales(k);
            end
            cols = reshape((((pairs(:, 1) - 1) * blockSize) + ...
                (1:blockSize)).', [], 1);
            out{outIdx} = blocks(:, cols) * vertcat(right{:});
        end
        if reshapeOutput
            out{outIdx} = reshape(out{outIdx}, outSize);
        end
    end
end

function plan = mkPlan(nPar, lhsDeg, rhsDeg)
    %MKPLAN Normalize degrees and record coefficient counts for the product.
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
    %ADDPAIRPLAN Build shared coefficient pairs and weights for every cell.
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

function labels = mkLbls(degree)
    %MKLBLS Enumerate tensor labels in repository coefficient order.
    labels = helper.combRows(arrayfun(@(d) 0:d, degree, ...
        "UniformOutput", false));
end
