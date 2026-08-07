function [out, plan] = elevRow(coeffs, fromDeg, toDeg, plan)
    %ELEVROW Apply one planned map to one rate-row coefficient set.
    %
    %   Syntax:
    %     [out, plan] = obj.elevRow(coeffs, fromDeg, toDeg)
    %     out = obj.elevRow(coeffs, fromDeg, toDeg, plan)
    %
    %   Arguments:
    %     coeffs  - One flat local coefficient row in label order.
    %     fromDeg - Source Bernstein degree.
    %     toDeg   - Target Bernstein degree with toDeg >= fromDeg
    %               componentwise.
    %     plan    - Optional sparse elevation plan returned by a previous
    %               call with the same degree pair.
    %
    %   Output:
    %     out  - Coefficient row representing the same polynomial at toDeg.
    %     plan - Reusable sparse tensor elevation operator and shape metadata.
    %
    %   Example:
    %     coeffs = {1, 3};
    %     [out, plan] = obj.elevRow(coeffs, 1, 3);
    %     sameOut = obj.elevRow(coeffs, 1, 3, plan);
    %
    %   The plan stores the Bernstein degree-elevation matrix only in numeric
    %   sparse form. Applying it to a horizontally packed coefficient row
    %   preserves matrix payload shape and works for both numeric coefficients
    %   and affine sdpvar coefficients.

    if nargin < 4 || isempty(plan)
        plan = mkPlan(fromDeg, toDeg);
    end
    if isempty(coeffs) || isequal(fromDeg, toDeg)
        out = coeffs;
        return
    end

    matrixColumns = size(coeffs{1}, 2);
    packed = horzcat(coeffs{:});
    packed = packed * kron(plan.Operator', speye(matrixColumns));
    if isnumeric(packed)
        packed = full(packed);
    end
    out = cell(1, plan.TargetCount);
    for k = 1:plan.TargetCount
        columns = (k - 1) * matrixColumns + (1:matrixColumns);
        out{k} = packed(:, columns);
    end
end

function plan = mkPlan(fromDeg, toDeg)
    %MKPLAN Build one sparse tensor elevation operator.
    nPar = numel(fromDeg);
    fromDeg = helper.normDeg(fromDeg, nPar, ...
        "pdbase:InvalidDegree", "fromDeg");
    toDeg = helper.normDeg(toDeg, nPar, ...
        "pdbase:InvalidDegree", "toDeg");
    if any(toDeg < fromDeg)
        error("pdbase:InvalidDegreeElevation", ...
            "Cannot degree-elevate to a lower degree in any parameter direction.");
    end
    srcLbl = helper.combRows(arrayfun(@(d) 0:d, fromDeg, ...
        "UniformOutput", false));
    dstLbl = helper.combRows(arrayfun(@(d) 0:d, toDeg, ...
        "UniformOutput", false));
    gap = toDeg - fromDeg;
    pairCount = size(srcLbl, 1) * prod(gap + 1);
    rows = zeros(pairCount, 1);
    cols = zeros(pairCount, 1);
    srcPairLabels = zeros(pairCount, nPar);
    gapPairLabels = zeros(pairCount, nPar);
    nextPair = 1;
    for k = 1:size(dstLbl, 1)
        delta = dstLbl(k, :) - srcLbl;
        keep = all(delta >= 0, 2) & all(delta <= gap, 2);
        src = find(keep);
        kept = delta(keep, :);
        range = nextPair:(nextPair + numel(src) - 1);
        rows(range) = k;
        cols(range) = src;
        srcPairLabels(range, :) = srcLbl(src, :);
        gapPairLabels(range, :) = kept;
        nextPair = nextPair + numel(src);
    end
    vals = helper.bernConvRatios(srcPairLabels, fromDeg, ...
        gapPairLabels, gap);
    plan.FromDegree = fromDeg;
    plan.ToDegree = toDeg;
    plan.NumParameters = nPar;
    plan.SourceCount = size(srcLbl, 1);
    plan.TargetCount = size(dstLbl, 1);
    plan.Operator = sparse(rows, cols, vals, ...
        plan.TargetCount, plan.SourceCount);
end
