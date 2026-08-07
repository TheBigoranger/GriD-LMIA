function tests = test_rate_rows
    %TEST_RATE_ROWS Explicit pdmat rate rows across construction and algebra.
    tests = functiontests(localfunctions);
end

function testRatBouMetEveSou(testCase)
    % RateBounds alone is metadata for every existing public source family.
    rb = [-2 3];
    values = {
        pdmat([0 1], @(rho) rho, RateBounds=rb), ...
        pdmat([0 1], @(rho) rho, Degree=1, RateBounds=rb), ...
        pdmat([0 1], {0, 1}, Degree=1, RateBounds=rb), ...
        pdmat([0 1], {{0, 1}}, Degree=1, RateBounds=rb)
        };

    for k = 1:numel(values)
        A = values{k};
        testCase.verifyEqual(A.RateBounds, rb);
        testCase.verifyEqual(size(A.coeffs(1), 1), 1);
    end
end

function testExpRowAndConSca(testCase)
    % A mismatch confined to the second rate row must mark the object discontinuous.
    rb = [-1 2];
    aligned = pdmat([0 1], {{1, 3; 10, 14}}, ...
        Degree=1, RateBounds=rb);
    vals = {
        {1, 2; 10, 20}, ...
        {2, 3; 999, 30}
        };

    broken = constructWithWarning(testCase, ...
        @() pdmat([0 1 2], vals, Degree=1, RateBounds=rb), ...
        "pdmat:DiscontinuousLocalValues");

    testCase.verifyTrue(aligned.IsContinuous);
    testCase.verifyFalse(broken.IsContinuous);
    testCase.verifyEqual(size(aligned.coeffs(1)), [2 2]);
    testCase.verifyEqual(aligned.evaluate(0.25), {1.5, 11}, ...
        AbsTol=1e-12);
end

function testInhRhoNumStaAnd(testCase)
    % pdmat differentiation remains numeric and clears exact function state.
    rb = [-2 3];
    A = pdmat([0 2], @(rho) rho.^2, Degree=2, RateBounds=rb);

    D = rhodiff(A);

    testCase.verifyClass(D, "pdmat");
    testCase.verifyEqual(D.Degree, 1);
    testCase.verifyEqual(D.coeffs(1), {0, -8; 0, 12}, AbsTol=1e-10);
    testCase.verifyFalse(D.ContainsDecision);
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifyEqual(D.RateBounds, rb);
    testCase.verifyEqual(D.SourceSummary, "derivative");
    testCase.verifyEmpty(D.FunctionHandle);

    fixed = pdmat([0 2], {1, 5}, Degree=1, RateBounds=[3 3]);
    fixedD = rhodiff(fixed);
    testCase.verifyEqual(fixedD.coeffs(1), {6});
    testCase.verifyEqual(fixedD.NumRateRows, 1);
    fixedTbl = fixedD.bernTable();
    testCase.verifyEqual(vertcat(fixedTbl.RateVertex{:}), 3);
    testCase.verifyError(@() rhodiff(fixedD), "pdmat:InvalidDiff");
    shifted = fixedD + 1;
    testCase.verifyEqual(shifted.NumRateRows, 1);
    testCase.verifyEqual(fixedD(1, 1).NumRateRows, 1);

    exactOnly = pdmat([0 1], @(rho) rho, RateBounds=rb);
    rows = pdmat([0 1], {{1, 2; 3, 4}}, ...
        Degree=1, RateBounds=rb);
    testCase.verifyError(@() rhodiff(exactOnly), ...
        "pdmat:FunctionOnlyDiff");
    testCase.verifyError(@() rhodiff(rows), "pdmat:InvalidDiff");
end

function testAddSubAndProPre(testCase)
    % Ordinary operands broadcast; products allow explicit rows on one side.
    R = rateScalar();
    A = pdmat([0 1], {2, 4}, Degree=1, RateBounds=[-1 2]);

    verifyRows(testCase, R + A, {3, 7; 12, 18});
    verifyRows(testCase, A - R, {1, 1; -8, -10});
    verifyRows(testCase, 5 - R, {4, 2; -5, -9});
    verifyRows(testCase, R * A, {2, 5, 12; 20, 34, 56});
    verifyRows(testCase, A * R, {2, 5, 12; 20, 34, 56});
    testCase.verifyError(@() R * R, "pdmat:InvalidMultiplication");
end

function testScaMatProAllOne(testCase)
    % Scalar scaling should preserve one complete derivative rate-row table.
    rb = [-1 2];
    scalarData = pdmat([0 1], {1, 3}, Degree=1, RateBounds=rb);
    matrixData = pdmat([0 1], {eye(2), 2 * eye(2)}, ...
        Degree=1, RateBounds=rb);
    ordinaryScalar = pdmat([0 1], {2, 4}, Degree=1);
    ordinaryMatrix = pdmat([0 1], {eye(2), 2 * eye(2)}, Degree=1);
    derivativeScalar = rhodiff(scalarData);
    derivativeMatrix = rhodiff(matrixData);
    expected = {
        -2 * eye(2), -4 * eye(2)
        4 * eye(2), 8 * eye(2)
        };

    products = {
        derivativeScalar * ordinaryMatrix, ...
        ordinaryMatrix * derivativeScalar, ...
        ordinaryScalar * derivativeMatrix, ...
        derivativeMatrix * ordinaryScalar
        };
    for k = 1:numel(products)
        product = products{k};
        testCase.verifyEqual(product.Degree, 1);
        testCase.verifyEqual(product.coeffs(1), expected, AbsTol=1e-10);
        verifyRateMeta(testCase, product, [2 2]);
    end

    testCase.verifyError(@() derivativeScalar * derivativeMatrix, ...
        "pdmat:InvalidMultiplication");
    testCase.verifyError(@() derivativeMatrix * derivativeScalar, ...
        "pdmat:InvalidMultiplication");
end

function testGriBouAndZerFas(testCase)
    % Explicit rows require exact grids and matching nonempty rate bounds.
    R = rateScalar();
    otherGrid = pdmat([0 0.5 1], {1, 2, 3}, ...
        Degree=1, RateBounds=[-1 2]);
    otherBounds = pdmat([0 1], {1, 2}, ...
        Degree=1, RateBounds=[0 2]);

    testCase.verifyError(@() R + otherGrid, "pdmat:InvalidAddition");
    testCase.verifyError(@() R + otherBounds, "pdmat:InvalidAddition");

    Z = R - R;
    testCase.verifyEqual(Z.Degree, 0);
    testCase.verifyEqual(Z.coeffs(1), {0});
    testCase.verifyEmpty(Z.RateBounds);
end

function testStrComIndAndAss(testCase)
    % Leaf-touching operations must retain both rows and their metadata.
    leaf = {
        [1 2; 3 4], [5 6; 7 8]
        [10 20; 30 40], [50 60; 70 80]
        };
    R = pdmat([0 1], {leaf}, Degree=1, RateBounds=[-1 2]);
    A = pdmat([0 1], {eye(2), 2 * eye(2)}, ...
        Degree=1, RateBounds=[-1 2]);

    T = R.';
    S = sum(R, 2);
    H = [R, A];
    B = blkdiag(R, A);
    C = R(:, 1);
    R(1, :) = pdmat([0 1], {{[9 8], [7 6]; [5 4], [3 2]}}, ...
        Degree=1, RateBounds=[-1 2]);

    verifyRateMeta(testCase, T, [2 2]);
    verifyRateMeta(testCase, S, [2 1]);
    verifyRateMeta(testCase, H, [2 4]);
    verifyRateMeta(testCase, B, [4 4]);
    verifyRateMeta(testCase, C, [2 1]);
    verifyRateMeta(testCase, R, [2 2]);
    tCoeff = T.coeffs(1);
    sCoeff = S.coeffs(1);
    hCoeff = H.coeffs(1);
    bCoeff = B.coeffs(1);
    cCoeff = C.coeffs(1);
    rCoeff = R.coeffs(1);
    testCase.verifyEqual(tCoeff{2, 2}, [50 70; 60 80]);
    testCase.verifyEqual(sCoeff{2, 1}, [30; 70]);
    testCase.verifyEqual(hCoeff{2, 1}, [10 20 1 0; 30 40 0 1]);
    testCase.verifyEqual(bCoeff{2, 2}, ...
        blkdiag([50 60; 70 80], 2 * eye(2)));
    testCase.verifyEqual(cCoeff{2, 1}, [10; 30]);
    testCase.verifyEqual(rCoeff{2, 2}, [3 2; 70 80]);
end

function testEleTabDisAndPlo(testCase)
    % Inspection and plotting preserve deterministic rate-row order.
    R = rateScalar();
    elevated = R.elevate(1);
    tbl = bernTable(R);
    short = evalc("disp(R)");
    detail = evalc("display(R)");

    testCase.verifyEqual(elevated.coeffs(1), ...
        {1, 2, 3; 10, 12, 14});
    testCase.verifyEqual(tbl.RateVertexIndex, [1; 1; 2; 2]);
    testCase.verifyEqual(tbl.RateVertex, {-1; -1; 2; 2});
    testCase.verifyTrue(contains(short, "rate rows true"));
    testCase.verifyTrue(contains(detail, "Explicit rate rows: true"));

    fig = figure(Visible="off");
    cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
    h1 = plot(R, SamplesPerCell=2, LineWidth=2);
    y1 = h1.YData;
    h2 = plot(R, SamplesPerCell=2, RateVertex=2, LineWidth=3);
    testCase.verifyEqual(y1, [1 2 3], AbsTol=1e-12);
    testCase.verifyEqual(h2.YData, [10 12 14], AbsTol=1e-12);
    testCase.verifyEqual(h2.LineWidth, 3);
    testCase.verifyError(@() plot(R, RateVertex=3), ...
        "pdmat:InvalidRateVertex");
    ordinary = pdmat([0 1], {1, 2}, Degree=1);
    testCase.verifyError(@() plot(ordinary, RateVertex=1), ...
        "pdmat:InvalidRateVertex");
end

function testFixTenRatRowEle(testCase)
    % A fixed tensor direction reduces the active rows before elevation.
    [D, ~] = fixedTensorRateData();

    E = D.elevate([1 0]);

    testCase.verifyEqual(E.Degree, D.Degree + [1 0]);
    testCase.verifyEqual(E.NumRateRows, 2);
    testCase.verifyEqual(size(E.coeffs([1 1]), 1), 2);
    testCase.verifyEqual(E.RateBounds, D.RateBounds);
end

function testFixTenRatRowPro(testCase)
    % Product validation must use distinct rate vertices, not 2^npar rows.
    [D, A] = fixedTensorRateData();

    C = D * A;

    testCase.verifyEqual(C.NumRateRows, 2);
    testCase.verifyEqual(size(C.coeffs([1 1]), 1), 2);
    testCase.verifyEqual(C.RateBounds, D.RateBounds);
end

function testFixOneRatRowDouPro(testCase)
    % A fixed rate box still represents rate rows on both product sides.
    source = pdmat([0 2], {1, 5}, Degree=1, RateBounds=[3 3]);
    D = rhodiff(source);

    testCase.verifyEqual(D.NumRateRows, 1);
    testCase.verifyError(@() D * D, "pdmat:InvalidMultiplication");
end

function testFixRatRowPloBou(testCase)
    % Plot selection rejects indices beyond the distinct stored vertices.
    fixed = pdmat([0 2], {1, 5}, Degree=1, RateBounds=[3 3]);
    fixedD = rhodiff(fixed);
    [tensorD, ~] = fixedTensorRateData();

    testCase.verifyError(@() plot(fixedD, RateVertex=2), ...
        "pdmat:InvalidRateVertex");
    testCase.verifyError(@() plot(tensorD, [1 2], RateVertex=3), ...
        "pdmat:InvalidRateVertex");
end

function R = rateScalar()
    % A two-row scalar fixture with one physical cell.
    R = pdmat([0 1], {{1, 3; 10, 14}}, ...
        Degree=1, RateBounds=[-1 2]);
end

function [D, A] = fixedTensorRateData()
    % Build two stored rate rows from one fixed and one varying direction.
    grid = {[0 1], [10 12]};
    rb = [1 1; -3 5];
    source = pdmat(grid, @(rho, eta) rho + eta, ...
        Degree=[1 1], RateBounds=rb);
    D = rhodiff(source);
    A = pdmat(grid, @(rho, eta) 1 + rho, ...
        Degree=[1 0], RateBounds=rb);
end

function verifyRows(testCase, obj, expected)
    % Assert numeric rows, order, and rate metadata together.
    testCase.verifyEqual(obj.coeffs(1), expected, AbsTol=1e-10);
    verifyRateMeta(testCase, obj, [1 1]);
end

function verifyRateMeta(testCase, obj, sz)
    % Explicit rows remain rate-dependent and preserve their matrix shape.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.RateBounds, [-1 2]);
    testCase.verifyEqual(size(obj.coeffs(1), 1), 2);
end

function obj = constructWithWarning(testCase, fcn, warningId)
    % Capture one expected construction warning and retain the object.
    obj = [];
    testCase.verifyWarning(@construct, warningId);

    function construct
        obj = fcn();
    end
end
