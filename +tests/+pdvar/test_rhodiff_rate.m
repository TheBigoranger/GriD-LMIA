function tests = test_rhodiff_rate
    %TEST_RHODIFF_RATE_VERTICES Rate-vertex derivative storage for pdvar.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function testScaDegOneForAnd(testCase)
    % Scalar degree-one derivatives should become degree-zero rate rows.
    P = pdvar(1, {[0 2]});
    cp = P.coeffs(1);

    D = rhodiff(P, [-2 3]);
    cd = D.coeffs(1);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(D.ncoeff(), 1);
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifyEqual(D.RateBounds, [-2 3]);
    testCase.verifyEqual(D.SourceSummary, "derivative");
    verifyCoeffTable(testCase, cd, {
        -2 * (cp{2} - cp{1}) / 2
        3 * (cp{2} - cp{1}) / 2
    });
end

function testScaDegTwoFor(testCase)
    % Constructor-created scalar quadratics drop to degree-one derivatives.
    C = pdvar(1, {[0 1]}, Degree=2);
    cc = C.coeffs(1);

    D = rhodiff(C, [-1 2]);

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyEqual(D.Degree, 1);
    verifyCoeffTable(testCase, D.coeffs(1), {
        -2 * (cc{2} - cc{1}), -2 * (cc{3} - cc{2})
        4 * (cc{2} - cc{1}), 4 * (cc{3} - cc{2})
    });
end

function testTenDegOneForAnd(testCase)
    % Tensor derivatives should keep degree one and combRows rate-vertex order.
    grid = {[0 2], [10 20]};
    rb = [-1 2; -3 5];
    P = pdvar(1, grid);
    cp = P.coeffs([1 1]);

    D = rhodiff(P, rb);
    cd = D.coeffs([1 1]);

    testCase.verifyEqual(D.Degree, [1 1]);
    testCase.verifyEqual(D.ncoeff(), 4);
    testCase.verifyEqual(size(cd), [4 4]);

    a0 = (cp{3} - cp{1}) / 2;
    a1 = (cp{4} - cp{2}) / 2;
    b0 = (cp{2} - cp{1}) / 10;
    b1 = (cp{4} - cp{3}) / 10;
    verts = [
        -1 -3
        -1 5
        2 -3
        2 5
    ];
    exp = cell(4, 4);
    for row = 1:4
        v = verts(row, :);
        exp(row, :) = {
            v(1) * a0 + v(2) * b0, ...
            v(1) * a1 + v(2) * b0, ...
            v(1) * a0 + v(2) * b1, ...
            v(1) * a1 + v(2) * b1
        };
    end
    verifyCoeffTable(testCase, cd, exp);
end

function testTenDegTwoFor(testCase)
    % Constructor-created tensor quadratics elevate partials to common degree.
    grid = {[0 2], [10 14]};
    rb = [-1 2; -3 5];
    C = pdvar(1, grid, Degree=[2 2]);
    cc = C.coeffs([1 1]);

    D = rhodiff(C, rb);
    cd = D.coeffs([1 1]);

    verts = [
        -1 -3
        -1 5
        2 -3
        2 5
    ];
    exp = cell(4, 9);
    for row = 1:4
        exp(row, :) = tensorDiffExpected(cc, [2 2], ...
            [2 4], verts(row, :), [1 1]);
    end
    testCase.verifyEqual(C.Degree, [2 2]);
    testCase.verifyEqual(D.Degree, [2 2]);
    verifyCoeffTable(testCase, cd, exp);
end

function testAniTenAndZerAxi(testCase)
    % Unequal and zero direction degrees retain one common tensor basis.
    grid = {[0 2], [10 14]};
    rb = [-1 2; -3 5];
    P = pdvar(1, grid, Degree=[1 2]);
    beforeVars = objectVariables(P);
    cp = P.coeffs([1 1]);

    D = rhodiff(P, rb);
    verts = rateVertsExpected(rb);
    expected = cell(4, 6);
    for row = 1:4
        expected(row, :) = tensorDiffExpected(cp, [1 2], ...
            [2 4], verts(row, :), [1 1]);
    end
    testCase.verifyEqual(D.Degree, [1 2]);
    testCase.verifySize(D.coeffs([1 1]), [4 6]);
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifyEqual(D.RateBounds, rb);
    testCase.verifyEqual(objectVariables(D), beforeVars);
    verifyCoeffTable(testCase, D.coeffs([1 1]), expected);

    Q = pdvar(1, grid, Degree=[0 2]);
    qVars = objectVariables(Q);
    cq = Q.coeffs([1 1]);
    E = rhodiff(Q, rb);
    zeroAxisExpected = cell(4, 3);
    for row = 1:4
        zeroAxisExpected(row, :) = tensorDiffExpected(cq, [0 2], ...
            [2 4], verts(row, :), [1 1]);
    end
    testCase.verifyEqual(E.Degree, [0 2]);
    testCase.verifyEqual(objectVariables(E), qVars);
    verifyCoeffTable(testCase, E.coeffs([1 1]), zeroAxisExpected);
end

function testThrDimNumAndAffOracle(testCase)
    % Three-parameter differentiation must preserve tensor/rate ordering for
    % numeric and affine matrix payloads over every physical cell.
    % Dyadic cell widths make exact affine-basis comparison independent of
    % harmless floating-point summation regrouping.
    grid = {[0 1 3], [-2 0 4], [10 14]};
    rb = [-2 3; -5 7; -11 13];
    deg = [2 1 1];
    data = makeNumGrid(grid, deg, [2 2]);
    known = pdmat(grid, data, Degree=deg, RateBounds=rb);
    affine = pdvar(2, grid, "full", Degree=deg, RateBounds=rb);

    verifyTensorDiff(testCase, known, rb, false);
    verifyTensorDiff(testCase, affine, rb, true);

    % Fixed directions collapse duplicate vertices while retaining their
    % coordinate positions in the rate-weighted derivative.
    fixedRb = [2 2; -3 5; 7 7];
    fixed = pdvar(2, grid, "full", Degree=[1 2 1], ...
        RateBounds=fixedRb);
    fixedD = verifyTensorDiff(testCase, fixed, fixedRb, true);
    testCase.verifyEqual(fixedD.NumRateRows, 2);

    % A zero-degree axis remains in the rate box but contributes no partial.
    zeroDeg = [2 0 1];
    zeroData = makeNumGrid(grid, zeroDeg, [2 2]);
    zeroAxis = pdmat(grid, zeroData, Degree=zeroDeg, RateBounds=rb);
    zeroD = verifyTensorDiff(testCase, zeroAxis, rb, false);
    testCase.verifyEqual(zeroD.NumRateRows, 8);
end

function testAllZerTenDegPro(testCase)
    % A constant tensor has one zero coefficient for every rate-box vertex.
    P = pdvar(1, {[0 1 2], [10 20]}, Degree=[0 0]);
    D = rhodiff(P, [-1 2; -3 5]);

    testCase.verifyEqual(D.Degree, [0 0]);
    testCase.verifyFalse(D.ContainsDecision);
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifySize(D.coeffs([1 1]), [4 1]);
    testCase.verifySize(D.coeffs([2 1]), [4 1]);
    verifyCoeffTable(testCase, D.coeffs([1 1]), {0; 0; 0; 0});
    verifyCoeffTable(testCase, D.coeffs([2 1]), {0; 0; 0; 0});
end

function testImpAndInvRatBou(testCase)
    % rhodiff should use object RateBounds or reject incompatible bounds.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    Q = pdvar(1, {[0 1]});

    D = rhodiff(P);

    testCase.verifyEqual(D.RateBounds, [-1 1]);
    testCase.verifyError(@() rhodiff(Q), "pdvar:MissingRateBounds");
    testCase.verifyError(@() rhodiff(P, [0 1]), "pdvar:RateBoundsMismatch");
    testCase.verifyError(@() rhodiff(Q, [0 1; -1 1]), "pdvar:InvalidRateBounds");
end

function testRejRepRho(testCase)
    % Rate-vertex expressions are terminal until quadratic-rate algebra exists.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    D = rhodiff(P);

    testCase.verifyError(@() rhodiff(D), "pdvar:InvalidDiff");
    testCase.verifyError(@() rhodiff(D, [-1 1]), "pdvar:InvalidDiff");
end

function testDerKeeCelBouDat(testCase)
    % A fixed rate produces one row while derivative cells remain independent.
    P = pdvar(1, {[0 1 3]}, RateBounds=[1 1]);
    cp1 = P.coeffs(1);
    cp2 = P.coeffs(2);

    D = rhodiff(P);
    left = D.coeffs(1);
    right = D.coeffs(2);

    verifyCoeffTable(testCase, left, {cp1{2} - cp1{1}});
    verifyCoeffTable(testCase, right, {(cp2{2} - cp2{1}) / 2});
    testCase.verifyFalse(isequal(getvariables(left{1, 1}), getvariables(right{1, 1})));

    tbl = D.bernTable();
    testCase.verifyTrue(ismember("RateVertex", string(tbl.Properties.VariableNames)));
    testCase.verifyEqual(vertcat(tbl.RateVertex{:}), [1; 1]);
    testCase.verifyError(@() rhodiff(D), "pdvar:InvalidDiff");

    shifted = D + 1;
    sliced = D(1, 1);
    testCase.verifyEqual(shifted.NumRateRows, 1);
    testCase.verifyEqual(sliced.NumRateRows, 1);
    testCase.verifyEqual(size(shifted.coeffs(1), 1), 1);
end

function testDegZerDerIsZer(testCase)
    % Degree-zero rate-dependent expressions should differentiate to zero.
    x = sdpvar(1, 1);
    vals = {{x}};
    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {{[0 1]}}, ...
        "MatrixSize", [1 1], ...
        "Degree", 0, ...
        "LocalValues", {vals}, ...
        "IsContinuous", true, ...
        "ContainsDecision", true, ...
        "RateBounds", [-1 1], ...
        "SourceSummary", "test-degree-zero");
    P = pdvar(init);

    D = rhodiff(P);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyFalse(D.ContainsDecision);
    verifyCoeffTable(testCase, D.coeffs(1), {0; 0});
end

function testDerAddBroOrdRow(testCase)
    % Affine algebra should broadcast ordinary coefficients across rate rows.
    P = pdvar(1, {[0 1]});
    cp = P.coeffs(1);
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);
    X = sdpvar(1, 1);
    A = pdmat({[0 1]}, {10, 20}, Degree=1);

    S = D + P;
    R = P - D;
    E = D + X;
    K = D + A;

    testCase.verifyFalse(S.IsContinuous);
    verifyCoeffTable(testCase, S.coeffs(1), {
        cd{1, 1} + cp{1}, cd{1, 1} + cp{2}
        cd{2, 1} + cp{1}, cd{2, 1} + cp{2}
    });
    verifyCoeffTable(testCase, R.coeffs(1), {
        cp{1} - cd{1, 1}, cp{2} - cd{1, 1}
        cp{1} - cd{2, 1}, cp{2} - cd{2, 1}
    });
    verifyCoeffTable(testCase, E.coeffs(1), {
        cd{1, 1} + X
        cd{2, 1} + X
    });
    verifyCoeffTable(testCase, K.coeffs(1), {
        cd{1, 1} + 10, cd{1, 1} + 20
        cd{2, 1} + 10, cd{2, 1} + 20
    });
end

function testDerRowComWitEac(testCase)
    % Matching rate-vertex tables should combine row-wise without broadcasting.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 2]);
    Q = pdvar(1, {[0 1]}, RateBounds=[-1 2]);
    Dp = rhodiff(P);
    Dq = rhodiff(Q);
    cp = Dp.coeffs(1);
    cq = Dq.coeffs(1);

    S = Dp + Dq;
    R = Dp - Dq;

    testCase.verifyFalse(S.IsContinuous);
    testCase.verifyEqual(S.RateBounds, [-1 2]);
    verifyCoeffTable(testCase, S.coeffs(1), {
        cp{1, 1} + cq{1, 1}
        cp{2, 1} + cq{2, 1}
    });
    verifyCoeffTable(testCase, R.coeffs(1), {
        cp{1, 1} - cq{1, 1}
        cp{2, 1} - cq{2, 1}
    });
end

function testDerProWitKnoDat(testCase)
    % Known-data products should multiply each derivative rate row.
    P = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);
    A = pdmat({[0 1]}, {10, 20}, Degree=1);

    L = A * D;
    R = D * A;
    S = 3 * D;

    verifyCoeffTable(testCase, L.coeffs(1), {
        10 * cd{1, 1}, 20 * cd{1, 1}
        10 * cd{2, 1}, 20 * cd{2, 1}
    });
    verifyCoeffTable(testCase, R.coeffs(1), {
        cd{1, 1} * 10, cd{1, 1} * 20
        cd{2, 1} * 10, cd{2, 1} * 20
    });
    verifyCoeffTable(testCase, S.coeffs(1), {3 * cd{1, 1}; 3 * cd{2, 1}});
end

function testDerMatProAndRej(testCase)
    % Numeric matrix products should work while unsafe rate products fail.
    V = pdvar(2, 1, {[0 1]}, "full");
    D = rhodiff(V, [-1 1]);
    cd = D.coeffs(1);
    P = pdvar(2, 1, {[0 1]}, "full");
    R = pdvar(1, {[0 1]}, RateBounds=[-1 1]);

    L = [1 2] * D;
    M = D * [4 5];

    verifyCoeffTable(testCase, L.coeffs(1), {
        [1 2] * cd{1, 1}
        [1 2] * cd{2, 1}
    });
    verifyCoeffTable(testCase, M.coeffs(1), {
        cd{1, 1} * [4 5]
        cd{2, 1} * [4 5]
    });
    testCase.verifyError(@() D * D, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() D * P, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() R * 2, "pdvar:InvalidMultiplication");
end

function row = tensorDiffExpected(vals, deg, h, rate, sz)
    % Local oracle for rate-weighted tensor derivative coefficients.
    nPar = numel(h);
    deg = reshape(deg, 1, []);
    if isscalar(deg)
        deg = repmat(deg, 1, nPar);
    end
    row = cell(1, prod(deg + 1));
    for dim = find(deg > 0)
        vecs = arrayfun(@(oneDeg) 0:oneDeg, deg, ...
            "UniformOutput", false);
        vecs{dim} = 0:(deg(dim) - 1);
        partLbls = labelRowsExpected(cellfun(@(oneVec) numel(oneVec) - 1, vecs));
        for k = 1:size(partLbls, 1)
            lbl = partLbls(k, :);
            nxt = lbl;
            nxt(dim) = nxt(dim) + 1;
            base = (vals{lblIdxExpected(nxt, deg)} - vals{lblIdxExpected(lbl, deg)}) ...
                * (deg(dim) * rate(dim) / h(dim));
            for outLabel = lbl(dim):(lbl(dim) + 1)
                out = lbl;
                out(dim) = outLabel;
                idx = lblIdxExpected(out, deg);
                scale = nchoosek(deg(dim) - 1, lbl(dim)) ...
                    * nchoosek(1, outLabel - lbl(dim)) ...
                    / nchoosek(deg(dim), outLabel);
                if isempty(row{idx})
                    row{idx} = base * scale;
                else
                    row{idx} = row{idx} + base * scale;
                end
            end
        end
    end
    for k = 1:numel(row)
        if isempty(row{k})
            row{k} = zeros(sz);
        end
    end
end

function idx = lblIdxExpected(lbl, deg)
    mult = fliplr(cumprod([1, fliplr(deg(2:end) + 1)]));
    idx = sum(lbl .* mult) + 1;
end

function out = verifyTensorDiff(testCase, source, rb, exactAffine)
    % Check metadata and every cell/rate-row/coefficient against a local oracle.
    out = rhodiff(source);
    verts = rateVertsExpected(rb);
    cells = source.cells();

    testCase.verifyEqual(out.Degree, source.Degree);
    testCase.verifyEqual(out.RateBounds, rb);
    testCase.verifyEqual(out.NumRateRows, size(verts, 1));
    testCase.verifyFalse(out.IsContinuous);
    testCase.verifyEqual(out.SourceSummary, "derivative");
    if exactAffine
        testCase.verifyEqual(objectVariables(out), objectVariables(source));
    else
        testCase.verifyFalse(out.ContainsDecision);
    end

    for c = 1:size(cells, 1)
        subs = cells(c, :);
        vals = source.coeffs(subs);
        widths = zeros(1, numel(subs));
        for dim = 1:numel(subs)
            grid = source.GridInfo.Vectors{dim};
            widths(dim) = grid(subs(dim) + 1) - grid(subs(dim));
        end
        actual = out.coeffs(subs);
        testCase.verifySize(actual, ...
            [size(verts, 1), prod(source.Degree + 1)]);
        for row = 1:size(verts, 1)
            expected = tensorDiffExpected(vals, source.Degree, ...
                widths, verts(row, :), source.MatrixSize);
            for coeff = 1:numel(expected)
                if exactAffine
                    verifyExprExact(testCase, actual{row, coeff}, ...
                        expected{coeff});
                else
                    testCase.verifyEqual(actual{row, coeff}, ...
                        expected{coeff}, AbsTol=1e-12);
                end
            end
        end
    end
end

function data = makeNumGrid(grid, deg, sz)
    % Build distinct matrix coefficients without depending on package traversal.
    dims = (cellfun(@numel, grid) - 1) .* deg + 1;
    data = cell(dims);
    nPar = numel(grid);
    for k = 1:numel(data)
        subs = cell(1, nPar);
        [subs{:}] = ind2sub(dims, k);
        key = sum((cell2mat(subs) - 1) .* 10 .^ (0:(nPar - 1)));
        data{k} = reshape(key + (1:prod(sz)), sz);
    end
end

function verts = rateVertsExpected(rb)
    % Enumerate distinct rate vertices with the last direction varying fastest.
    choice = rb(1, 1);
    if rb(1, 1) ~= rb(1, 2)
        choice = rb(1, :).';
    end
    verts = choice(:);
    for dim = 2:size(rb, 1)
        choice = rb(dim, 1);
        if rb(dim, 1) ~= rb(dim, 2)
            choice = rb(dim, :).';
        end
        nOld = size(verts, 1);
        verts = [repelem(verts, numel(choice), 1), ...
            repmat(choice(:), nOld, 1)]; %#ok<AGROW>
    end
end

function rows = labelRowsExpected(deg)
    % Enumerate tensor labels independently of helper.combRows.
    rows = (0:deg(1)).';
    for dim = 2:numel(deg)
        next = (0:deg(dim)).';
        rows = [repelem(rows, numel(next), 1), ...
            repmat(next, size(rows, 1), 1)]; %#ok<AGROW>
    end
end

function verifyExprExact(testCase, actual, expected)
    % Affine equivalence requires identical YALMIP variables and bases.
    testCase.verifyEqual(getvariables(actual), getvariables(expected));
    testCase.verifyEqual(full(getbase(actual)), full(getbase(expected)), ...
        AbsTol=0);
end

function vars = objectVariables(obj)
    % Collect all unique YALMIP variables without depending on assignments.
    vars = [];
    cells = obj.cells();
    for k = 1:size(cells, 1)
        coeffs = obj.coeffs(cells(k, :));
        for j = 1:numel(coeffs)
            if isa(coeffs{j}, "sdpvar")
                vars = [vars, getvariables(coeffs{j})]; %#ok<AGROW>
            end
        end
    end
    vars = unique(vars);
end

function verifyCoeffTable(testCase, actual, expected)
    % Rate-vertex coefficient tables should match expected shape and entries.
    testCase.verifyEqual(size(actual), size(expected));
    for row = 1:size(expected, 1)
        for col = 1:size(expected, 2)
            verifyExpr(testCase, actual{row, col}, expected{row, col});
        end
    end
end

function verifyExpr(testCase, actual, expected)
    % Compare numeric or affine coefficient expressions without solving them.
    diffVal = actual - expected;
    if isa(diffVal, "sdpvar")
        base = full(getbase(diffVal));
        testCase.verifyEqual(base, zeros(size(base)), AbsTol=1e-10);
    else
        testCase.verifyEqual(diffVal, zeros(size(diffVal)), AbsTol=1e-10);
    end
end
