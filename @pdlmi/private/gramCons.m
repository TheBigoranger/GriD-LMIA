function cons = gramCons(expr, relation, targetDeg, specs, cmpMode, valMode, band)
    %GRAMCONS Assemble one Bernstein-Gram certificate per cell and rate row.
    %
    %   Syntax:
    %     cons = gramCons(expr, relation, targetDeg, specs, cmpMode, valMode)
    %     cons = gramCons(expr, relation, targetDeg, specs, cmpMode, valMode, band)
    %
    %   Arguments:
    %     expr      - pdvar or coefficient-backed pdmat inequality residual.
    %     relation  - "<=" or ">=".
    %     targetDeg - Common Bernstein degree for coefficient matching.
    %     specs     - Cell table of Gram degree and generator-mask powers.
    %     cmpMode   - "semidefinite" or "elementwise".
    %     valMode   - "fast" or "strict" generated-assembly validation mode.
    %     band      - Optional tensor-window side length for sparse variants.
    %
    %   Output:
    %     cons - Cell array containing PSD cone constraints followed by exact
    %            coefficient-matching constraints for every local certificate.
    %
    %   Example:
    %     [targetDeg, specs] = putSpec(expr, order);
    %     cons = gramCons(expr, ">=", targetDeg, specs, ...
    %         "semidefinite", "fast");
    %
    %   Each physical cell and active derivative-rate row receives fresh Gram
    %   variables. Element-wise inequalities allocate scalar Gram certificates
    %   for each matrix entry, while semidefinite inequalities use matrix Gram
    %   blocks. The optional band restricts each Gram basis to sliding tensor
    %   windows without changing the target coefficient-matching degree.
    if nargin < 7
        band = [];
    end
    elevated = expr.elevate(targetDeg - expr.Degree, valMode);
    vals = elevated.LocalValues;
    chkAsmVals(expr, vals, targetDeg, valMode);
    cells = expr.cells();
    plan = mkCertPlan(specs, expr.npar(), band, targetDeg);
    if cmpMode == "elementwise"
        certPerRow = prod(expr.MatrixSize);
        gramSize = 1;
    else
        certPerRow = 1;
        gramSize = expr.MatrixSize(1);
    end
    nLocal = countCert(vals, cells, certPerRow);
    cons = cell(nLocal * (plan.BlockCount + plan.TargetCount), 1);
    next = 0;
    checked = false(plan.BlockCount, 1);

    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        for row = 1:size(coeffs, 1)
            target = coeffs(row, :);
            if relation == "<="
                for k = 1:numel(target)
                    target{k} = -target{k};
                end
            end
            if cmpMode == "elementwise"
                for entry = 1:prod(expr.MatrixSize)
                    scalar = cellfun(@(mat) mat(entry), target, ...
                        "UniformOutput", false);
                    appendCert(1, scalar);
                end
            else
                appendCert(gramSize, target);
            end
        end
    end

    function appendCert(matrixSize, target)
        % Preserve cone-before-matching order for every local certificate.
        [cones, represented, checked] = mkCert( ...
            matrixSize, plan, valMode, checked);
        for k = 1:numel(cones)
            next = next + 1;
            cons{next} = cones{k};
        end
        for k = 1:plan.TargetCount
            next = next + 1;
            cons{next} = represented{k} == target{k};
        end
    end
end

function count = countCert(vals, cells, perRow)
    %COUNTCERT Count independent local Gram certificates exactly.
    count = 0;
    for c = 1:size(cells, 1)
        coeffs = helper.cellGet(vals, cells(c, :));
        count = count + size(coeffs, 1) * perRow;
    end
end

function [cons, coeffs, checked] = mkCert(sz, plan, mode, checked)
    %MKCERT Allocate fresh Gram variables and apply all numeric maps.
    cons = cell(plan.BlockCount, 1);
    coeffs = repmat({zeros(sz)}, 1, plan.TargetCount);
    for block = 1:plan.BlockCount
        map = plan.Blocks{block};
        dim = sz * map.BasisCount;
        gram = sdpvar(dim, dim, 'symmetric');
        cons{block} = gram >= 0;
        doChk = mode == "strict" || ~checked(block);
        term = applyPlan(gram, map, doChk);
        checked(block) = true;
        for k = 1:plan.TargetCount
            coeffs{k} = coeffs{k} + term{k};
        end
    end
end

function cert = mkCertPlan(specs, nPar, band, targetDeg)
    %MKCERTPLAN Expand dense or tensor-window Gram maps once.
    plans = {};
    for k = 1:size(specs, 1)
        gramDeg = reshape(specs{k, 1}, 1, []);
        if any(gramDeg < 0)
            continue
        end
        weight = specs{k, 2};
        alpha = reshape(weight(1, :), 1, nPar);
        oneMinus = reshape(weight(2, :), 1, nPar);
        if isempty(band)
            plans{end + 1, 1} = mkPlan(gramDeg, alpha, oneMinus); %#ok<AGROW>
        else
            winSize = min(band, gramDeg + 1);
            local = labelRows(winSize - 1);
            starts = labelRows(gramDeg - winSize + 1);
            for w = 1:size(starts, 1)
                plans{end + 1, 1} = mkPlan(gramDeg, alpha, ...
                    oneMinus, local + starts(w, :)); %#ok<AGROW>
            end
        end
    end
    targetCount = prod(targetDeg + 1);
    for k = 1:numel(plans)
        if ~isequal(plans{k}.TargetDegree, targetDeg) || ...
                plans{k}.TargetCount ~= targetCount
            error("pdlmi:InvalidGramPowers", ...
                "Every Gram block must map to the common target tensor degree.");
        end
    end
    cert.Blocks = plans;
    cert.BlockCount = numel(plans);
    cert.TargetDegree = targetDeg;
    cert.TargetCount = targetCount;
end

function plan = mkPlan(gramDeg, alpha, oneMinus, basis)
    %MKPLAN Precompute one weighted Bernstein-Gram coefficient map.
    gramDeg = rowVec(gramDeg, "gramDegree");
    nPar = numel(gramDeg);
    alpha = rowVec(alpha, "alphaPower");
    oneMinus = rowVec(oneMinus, "oneMinusAlphaPower");
    allPowers = [gramDeg, alpha, oneMinus];
    if numel(alpha) ~= nPar || numel(oneMinus) ~= nPar || ...
            any(allPowers < 0) || any(mod(allPowers, 1) ~= 0)
        error("pdlmi:InvalidGramPowers", ...
            "Gram degrees and weight powers must be nonnegative integer vectors of equal length.");
    end
    if nargin < 4 || isempty(basis)
        basis = labelRows(gramDeg);
    else
        basis = chkBasis(basis, gramDeg);
    end
    targetDeg = 2 * gramDeg + alpha + oneMinus;
    targetCount = prod(targetDeg + 1);
    mult = ones(1, nPar);
    for k = 1:nPar - 1
        mult(k) = prod(targetDeg(k + 1:end) + 1);
    end
    diagonal = cell(targetCount, 1);
    offDiag = cell(targetCount, 1);
    nBasis = size(basis, 1);
    pairCount = nBasis * (nBasis + 1) / 2;
    left = zeros(pairCount, 1);
    right = zeros(pairCount, 1);
    output = zeros(pairCount, 1);
    outputLabels = zeros(pairCount, nPar);
    nextPair = 1;
    for i = 1:nBasis
        for j = i:nBasis
            label = basis(i, :) + basis(j, :) + alpha;
            left(nextPair) = i;
            right(nextPair) = j;
            output(nextPair) = label * mult' + 1;
            outputLabels(nextPair, :) = label;
            nextPair = nextPair + 1;
        end
    end
    scales = helper.bernConvRatios(basis(left, :), gramDeg, ...
        basis(right, :), gramDeg, outputLabels, targetDeg);
    for pair = 1:pairCount
        out = output(pair);
        if left(pair) == right(pair)
            diagonal{out}(end + 1, :) = [left(pair), scales(pair)];
        else
            offDiag{out}(end + 1, :) = ...
                [left(pair), right(pair), scales(pair)];
        end
    end
    plan.GramDegree = gramDeg;
    plan.AlphaPower = alpha;
    plan.OneMinusAlphaPower = oneMinus;
    plan.BasisLabels = basis;
    plan.BasisCount = nBasis;
    plan.TargetDegree = targetDeg;
    plan.TargetCount = targetCount;
    plan.OutputMultipliers = mult;
    plan.Diagonal = diagonal;
    plan.OffDiagonal = offDiag;
end

function coeffs = applyPlan(gram, plan, doChk)
    %APPLYPLAN Realize one precomputed Bernstein-Gram coefficient map.
    if doChk
        chkPlan(gram, plan);
    end
    n = size(gram, 1) / plan.BasisCount;
    coeffs = repmat({zeros(n)}, 1, plan.TargetCount);
    for out = 1:plan.TargetCount
        val = zeros(n);
        diagonal = plan.Diagonal{out};
        for k = 1:size(diagonal, 1)
            block = blockIdx(diagonal(k, 1), n);
            val = val + diagonal(k, 2) * gram(block, block);
        end
        offDiag = plan.OffDiagonal{out};
        for k = 1:size(offDiag, 1)
            left = blockIdx(offDiag(k, 1), n);
            right = blockIdx(offDiag(k, 2), n);
            val = val + offDiag(k, 3) * ...
                (gram(left, right) + gram(right, left));
        end
        coeffs{out} = val;
    end
end

function idx = blockIdx(basis, sz)
    %BLOCKIDX Return one basis-major matrix block.
    idx = (basis - 1) * sz + (1:sz);
end

function chkPlan(gram, plan)
    %CHKPLAN Check one distinct map and compatible Gram block.
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

function rows = labelRows(maxLabel)
    %LABELROWS Enumerate a tensor box in repository coefficient order.
    ranges = arrayfun(@(d) 0:d, maxLabel, "UniformOutput", false);
    rows = helper.combRows(ranges);
end

function labels = chkBasis(labels, gramDeg)
    %CHKBASIS Validate an explicit tensor-basis subset.
    nPar = numel(gramDeg);
    if ~isnumeric(labels) || ~isreal(labels) || isempty(labels) || ...
            size(labels, 2) ~= nPar || any(~isfinite(labels), "all") || ...
            any(mod(labels, 1) ~= 0, "all") || any(labels < 0, "all") || ...
            any(labels > gramDeg, "all") || ...
            size(unique(labels, "rows"), 1) ~= size(labels, 1)
        error("pdlmi:InvalidGramBasis", ...
            "basisLabels must contain unique valid tensor Gram labels.");
    end
    labels = double(labels);
end

function out = rowVec(value, name)
    %ROWVEC Normalize one finite real Gram metadata vector.
    if ~isnumeric(value) || ~isreal(value) || isempty(value) || ...
            ~isvector(value) || any(~isfinite(value))
        error("pdlmi:InvalidGramPowers", ...
            "%s must be a finite real vector.", name);
    end
    out = reshape(double(value), 1, []);
end
