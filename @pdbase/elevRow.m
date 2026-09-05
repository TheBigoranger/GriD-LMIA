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
    %
    %   A plan is a plain struct, independent of coefficient values and grid
    %   coordinates. FromDegree, ToDegree and NumParameters identify the map;
    %   SourceCount and TargetCount are prod(fromDeg+1) and prod(toDeg+1).
    %   Operator is TargetCount-by-SourceCount: if E = plan.Operator, then
    %       out{j} = sum_i E(j,i)*coeffs{i}.
    %   For scalar degrees 1 -> 2, E = [1 0; 1/2 1/2; 0 1], so {A,B}
    %   becomes {A,(A+B)/2,B}. A and B may themselves be matrices.
    %   Reuse requires the same degree pair and coefficient label order;
    %   the caller validates the payloads before applying a supplied plan.
    %   The first nonempty row also stores Columns, Kernel=kron(E',I), and
    %   Blocks (the packed column indices of each target coefficient).
    %   Capture the returned plan to reuse this expanded matrix on later rows;
    %   a different payload width replaces Kernel, without rebuilding E.

    if nargin < 4 || isempty(plan)
        plan = mkPlan(fromDeg, toDeg);
    end
    % An empty row is the build-only interface used by elevData and rhodiff:
    % return the plan without applying it to any coefficients.
    if isempty(coeffs) || isequal(fromDeg, toDeg)
        out = coeffs;
        return
    end

    matrixColumns = size(coeffs{1}, 2);
    if plan.Columns ~= matrixColumns
        plan.Columns = matrixColumns;
        plan.Kernel = kron(plan.Operator', speye(matrixColumns));
        % Keep each index vector horizontal, matching the original slicing
        % path for both numeric matrices and YALMIP's overloaded subsref.
        plan.Blocks = reshape(1:matrixColumns*plan.TargetCount, ...
            matrixColumns, plan.TargetCount)';
    end
    packed = horzcat(coeffs{:});
    % Packing m-by-n coefficients gives [C1 ... Cs], of size m-by-(n*s).
    % E' combines these horizontal blocks; kron(E',I_n) applies each scalar
    % weight to a whole matrix, producing [D1 ... Dt] without mixing columns.
    packed = packed * plan.Kernel;
    if isnumeric(packed)
        packed = full(packed);
    end
    out = cell(1, plan.TargetCount);
    for k = 1:plan.TargetCount
        out{k} = packed(:, plan.Blocks(k, :));
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
    gap = toDeg - fromDeg;
    % Elevation multiplies the source basis by the degree-gap expansion of 1.
    % Enumerate only contributing (source,gap) pairs, instead of scanning all
    % source labels for every target. Each pair has target beta=alpha+delta.
    gapLbl = helper.combRows(arrayfun(@(d) 0:d, gap, ...
        "UniformOutput", false));
    cols = repelem((1:size(srcLbl, 1))', size(gapLbl, 1));
    srcPairLabels = srcLbl(cols, :);
    gapPairLabels = repmat(gapLbl, size(srcLbl, 1), 1);
    % Earlier axes vary more slowly in combRows order. These strides convert
    % each target multi-index directly to its one-based sparse-matrix row.
    strides = fliplr(cumprod([1, fliplr(toDeg(2:end) + 1)]));
    rows = 1 + (srcPairLabels + gapPairLabels) * strides';
    % For each retained (beta,alpha), the weight is the product over axes q:
    % binom(fromDeg(q),alpha(q))*binom(gap(q),beta(q)-alpha(q))
    % / binom(toDeg(q),beta(q)). The helper evaluates these ratios stably.
    vals = helper.bernConvRatios(srcPairLabels, fromDeg, ...
        gapPairLabels, gap);
    plan.FromDegree = fromDeg;
    plan.ToDegree = toDeg;
    plan.NumParameters = nPar;
    plan.SourceCount = size(srcLbl, 1);
    plan.TargetCount = prod(toDeg + 1);
    plan.Operator = sparse(rows, cols, vals, ...
        plan.TargetCount, plan.SourceCount);
    plan.Columns = 0;
    plan.Kernel = [];
    plan.Blocks = [];
end
