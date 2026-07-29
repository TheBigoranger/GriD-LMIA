function tests = test_rhodiff_rate_vertices
    %TEST_RHODIFF_RATE_VERTICES Rate-vertex derivative storage for pdvar.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function testScalarDegreeOneFormulaAndMetadata(testCase)
    % Scalar degree-one derivatives should become degree-zero rate rows.
    P = pdvar(1, {[0 2]});
    cp = P.coeffs(1);

    D = rhodiff(P, [-2 3]);
    cd = D.coeffs(1);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(D.ncoeff(), 1);
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifyTrue(D.HasRateDependence);
    testCase.verifyEqual(D.RateBounds, [-2 3]);
    testCase.verifyEqual(D.SourceSummary, "derivative");
    verifyCoeffTable(testCase, cd, {
        -2 * (cp{2} - cp{1}) / 2
        3 * (cp{2} - cp{1}) / 2
    });
end

function testScalarDegreeTwoFormula(testCase)
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

function testTensorDegreeOneFormulaAndRateOrder(testCase)
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

function testTensorDegreeTwoFormula(testCase)
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

function testAnisotropicTensorAndZeroAxisFormula(testCase)
    % Unequal and zero direction degrees retain one common tensor basis.
    grid = {[0 2], [10 14]};
    rb = [-1 2; -3 5];
    P = pdvar(1, grid, Degree=[1 2]);
    beforeVars = objectVariables(P);
    cp = P.coeffs([1 1]);

    D = rhodiff(P, rb);
    verts = helper.combRows(num2cell(rb, 2).');
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

function testAllZeroTensorDegreeProducesCompleteRateTable(testCase)
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

function testImplicitAndInvalidRateBounds(testCase)
    % rhodiff should use object RateBounds or reject incompatible bounds.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    Q = pdvar(1, {[0 1]});

    D = rhodiff(P);

    testCase.verifyEqual(D.RateBounds, [-1 1]);
    testCase.verifyError(@() rhodiff(Q), "pdvar:MissingRateBounds");
    testCase.verifyError(@() rhodiff(P, [0 1]), "pdvar:RateBoundsMismatch");
    testCase.verifyError(@() rhodiff(Q, [0 1; -1 1]), "pdvar:InvalidRateBounds");
end

function testRejectsRepeatedRhodiff(testCase)
    % Rate-vertex expressions are terminal until quadratic-rate algebra exists.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    D = rhodiff(P);

    testCase.verifyError(@() rhodiff(D), "pdvar:InvalidDiff");
    testCase.verifyError(@() rhodiff(D, [-1 1]), "pdvar:InvalidDiff");
end

function testDerivativeKeepsCellBoundaryDataSeparate(testCase)
    % Derivative cells should not reuse continuous boundary coefficient handles.
    P = pdvar(1, {[0 1 3]}, RateBounds=[1 1]);
    cp1 = P.coeffs(1);
    cp2 = P.coeffs(2);

    D = rhodiff(P);
    left = D.coeffs(1);
    right = D.coeffs(2);

    verifyCoeffTable(testCase, left, {cp1{2} - cp1{1}; cp1{2} - cp1{1}});
    verifyCoeffTable(testCase, right, {(cp2{2} - cp2{1}) / 2; (cp2{2} - cp2{1}) / 2});
    testCase.verifyFalse(isequal(getvariables(left{1, 1}), getvariables(right{1, 1})));
end

function testDegreeZeroDerivativeIsZero(testCase)
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
        "HasRateDependence", true, ...
        "RateBounds", [-1 1], ...
        "SourceSummary", "test-degree-zero");
    P = pdvar(init);

    D = rhodiff(P);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyFalse(D.ContainsDecision);
    verifyCoeffTable(testCase, D.coeffs(1), {0; 0});
end

function testDerivativeAdditionBroadcastsOrdinaryRows(testCase)
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

function testDerivativeRowsCombineWithEachOther(testCase)
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
    testCase.verifyTrue(S.HasRateDependence);
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

function testDerivativeProductsWithKnownData(testCase)
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

function testDerivativeMatrixProductsAndRejections(testCase)
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
        partLbls = helper.combRows(vecs);
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
