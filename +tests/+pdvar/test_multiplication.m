function tests = test_multiplication
    %TEST_MULTIPLICATION pdvar products with known data and affine guards.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function testPdmPdvPro(testCase)
    % Known coefficient data may multiply a pdvar on either side.
    P = pdvar(1, {[0 1]});
    A = pdmat({[0 1]}, {10, 20}, Degree=1);
    cp = P.coeffs(1);

    L = A * P;
    R = P * A;

    testCase.verifyEqual(L.Degree, 2);
    testCase.verifyEqual(R.Degree, 2);
    exp = {10 * cp{1}, (10 * cp{2} + 20 * cp{1}) / 2, 20 * cp{2}};
    verifyCoeffExpr(testCase, L.coeffs(1), exp);
    verifyCoeffExpr(testCase, R.coeffs(1), exp);
end

function testMetRatBouScaPro(testCase)
    % Metadata-only RateBounds do not create active derivative-rate rows.
    tauRange = linspace(0, 7, 2);
    tau = pdmat(tauRange, @(x) x, Degree=1);
    Q = pdvar(2, tauRange, RateBounds=[-1 1], Degree=0);
    cq = Q.coeffs(1);

    L = tau * Q;
    R = Q * tau;
    leftScale = 2 * Q;
    rightScale = Q * 2;

    testCase.verifyEqual(size(L), [2 2]);
    testCase.verifyEqual(size(R), [2 2]);
    testCase.verifyEqual(L.Degree, 1);
    testCase.verifyEqual(R.Degree, 1);
    testCase.verifyEqual(L.RateBounds, [-1 1]);
    testCase.verifyEqual(R.RateBounds, [-1 1]);
    testCase.verifyEqual(L.NumRateRows, 0);
    testCase.verifyEqual(R.NumRateRows, 0);
    testCase.verifyEqual(objectVariables(L), objectVariables(Q));
    testCase.verifyEqual(objectVariables(R), objectVariables(Q));
    verifyCoeffExpr(testCase, L.coeffs(1), {zeros(2), 7 * cq{1}});
    verifyCoeffExpr(testCase, R.coeffs(1), {zeros(2), cq{1} * 7});
    testCase.verifyEqual(leftScale.RateBounds, [-1 1]);
    testCase.verifyEqual(rightScale.RateBounds, [-1 1]);
    testCase.verifyEqual(leftScale.NumRateRows, 0);
    testCase.verifyEqual(rightScale.NumRateRows, 0);
    verifyCoeffExpr(testCase, leftScale.coeffs(1), {2 * cq{1}});
    verifyCoeffExpr(testCase, rightScale.coeffs(1), {cq{1} * 2});
end

function testNumScaAndMatPro(testCase)
    % Numeric products should preserve affine YALMIP structure.
    P = pdvar(2, 1, {[0 1]}, "full");
    cp = P.coeffs(1);

    S = 3 * P;
    L = [1 2] * P;
    R = P * [4 5];

    testCase.verifyEqual(size(S), [2 1]);
    testCase.verifyEqual(size(L), [1 1]);
    testCase.verifyEqual(size(R), [2 2]);
    verifyCoeffExpr(testCase, S.coeffs(1), {3 * cp{1}, 3 * cp{2}});
    verifyCoeffExpr(testCase, L.coeffs(1), {[1 2] * cp{1}, [1 2] * cp{2}});
    verifyCoeffExpr(testCase, R.coeffs(1), {cp{1} * [4 5], cp{2} * [4 5]});
end

function testConDegTwoTimKno(testCase)
    % Known multiplication keeps arbitrary-degree decisions affine.
    P = pdvar(1, {[0 1]}, Degree=2);
    A = pdmat({[0 1]}, {2, 5}, Degree=1);
    cp = P.coeffs(1);

    C = P * A;

    testCase.verifyEqual(C.Degree, 3);
    testCase.verifyTrue(C.ContainsDecision);
    verifyCoeffExpr(testCase, C.coeffs(1), { ...
        2 * cp{1}, ...
        (5 * cp{1} + 4 * cp{2}) / 3, ...
        (10 * cp{2} + 2 * cp{3}) / 3, ...
        5 * cp{3}});
    testCase.verifyError(@() P * pdvar(1, {[0 1]}, Degree=2), ...
        "pdvar:InvalidMultiplication");
end

function testScaPdvScaKnoMat(testCase)
    % A scalar pdvar should scale numeric and pdmat matrices in either order.
    G = pdvar(1, [0 1], Degree=0);
    cg = G.coeffs(1);
    A = pdmat([0 1], {eye(2), 2 * eye(2)}, Degree=1);

    R = G * eye(2);
    L = eye(2) * G;
    knownRight = G * A;
    knownLeft = A * G;

    testCase.verifyEqual(size(R), [2 2]);
    testCase.verifyEqual(size(L), [2 2]);
    testCase.verifyEqual(R.Degree, 0);
    testCase.verifyEqual(L.Degree, 0);
    verifyCoeffExpr(testCase, R.coeffs(1), {cg{1} * eye(2)});
    verifyCoeffExpr(testCase, L.coeffs(1), {eye(2) * cg{1}});
    testCase.verifyEqual(size(knownRight), [2 2]);
    testCase.verifyEqual(size(knownLeft), [2 2]);
    testCase.verifyEqual(knownRight.Degree, 1);
    testCase.verifyEqual(knownLeft.Degree, 1);
    verifyCoeffExpr(testCase, knownRight.coeffs(1), ...
        {cg{1} * eye(2), cg{1} * 2 * eye(2)});
    verifyCoeffExpr(testCase, knownLeft.coeffs(1), ...
        {eye(2) * cg{1}, 2 * eye(2) * cg{1}});
end

function testAniKnoDecPro(testCase)
    % Unequal direction-wise degrees add while both operand orders stay affine.
    grid = {[0 1], [10 20]};
    P = pdvar(1, grid, Degree=[1 2]);
    knownData = cell(3, 2);
    for i = 0:2
        for j = 0:1
            knownData{i + 1, j + 1} = 2 + j;
        end
    end
    A = pdmat(grid, knownData, Degree=[2 1]);

    left = A * P;
    right = P * A;

    testCase.verifyEqual(left.Degree, [3 3]);
    testCase.verifyEqual(right.Degree, [3 3]);
    testCase.verifyEqual(objectVariables(left), objectVariables(P));
    testCase.verifyEqual(objectVariables(right), objectVariables(P));
    testCase.verifyTrue(is(left.evaluate([0.3 14]), "linear"));
    testCase.verifyTrue(is(right.evaluate([0.3 14]), "linear"));

    coeffs = P.coeffs([1 1]);
    for k = 1:numel(coeffs)
        assign(coeffs{k}, k);
    end
    point = [0.3 14];
    expected = A.evaluate(point) * value(P.evaluate(point));
    testCase.verifyEqual(value(left.evaluate(point)), expected, ...
        AbsTol=1e-10);
    testCase.verifyEqual(value(right.evaluate(point)), expected, ...
        AbsTol=1e-10);
end

function testScaPdmScaDecMat(testCase)
    % A scalar pdmat should scale matrix-valued decisions on either side.
    S = pdmat([0 1], {2, 4}, Degree=1);
    P = pdvar(2, 2, [0 1], "full");
    cp = P.coeffs(1);

    knownLeft = S * P;
    knownRight = P * S;
    expected = {
        2 * cp{1}, ...
        (2 * cp{2} + 4 * cp{1}) / 2, ...
        4 * cp{2}
        };

    testCase.verifyEqual(size(knownLeft), [2 2]);
    testCase.verifyEqual(size(knownRight), [2 2]);
    testCase.verifyEqual(knownLeft.Degree, 2);
    testCase.verifyEqual(knownRight.Degree, 2);
    verifyCoeffExpr(testCase, knownLeft.coeffs(1), expected);
    verifyCoeffExpr(testCase, knownRight.coeffs(1), expected);
end

function testSdpPdmScaBro(testCase)
    % A scalar sdpvar and scalar pdmat should broadcast in both orders.
    x = sdpvar(1, 1);
    X = sdpvar(2, 2, 'full');
    A = pdmat([0 1], {eye(2), 2 * eye(2)}, Degree=1);
    S = pdmat([0 1], {2, 3, 4}, Degree=2);

    sdpLeft = x * A;
    sdpRight = A * x;
    knownLeft = S * X;
    knownRight = X * S;

    verifyScalarProduct(testCase, sdpLeft, [2 2], 1, ...
        {x * eye(2), x * 2 * eye(2)}, getvariables(x));
    verifyScalarProduct(testCase, sdpRight, [2 2], 1, ...
        {eye(2) * x, 2 * eye(2) * x}, getvariables(x));
    verifyScalarProduct(testCase, knownLeft, [2 2], 2, ...
        {2 * X, 3 * X, 4 * X}, getvariables(X));
    verifyScalarProduct(testCase, knownRight, [2 2], 2, ...
        {X * 2, X * 3, X * 4}, getvariables(X));
end

function testSdpPdmMatPro(testCase)
    % Compatible affine and known matrices multiply in either operand order.
    X = sdpvar(2, 3, 'full');
    Y = sdpvar(4, 2, 'full');
    a0 = reshape(1:12, 3, 4);
    a1 = a0 + 20;
    a2 = a0 - 7;
    A = pdmat({[0 0.5 1]}, {a0, a1, a2}, Degree=1);

    sdpLeft = X * A;
    knownLeft = A * Y;

    testCase.verifyClass(sdpLeft, "pdvar");
    testCase.verifyClass(knownLeft, "pdvar");
    testCase.verifyEqual(size(sdpLeft), [2 4]);
    testCase.verifyEqual(size(knownLeft), [3 2]);
    testCase.verifyEqual(sdpLeft.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(knownLeft.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(sdpLeft.Degree, 1);
    testCase.verifyEqual(knownLeft.Degree, 1);
    testCase.verifyTrue(sdpLeft.IsContinuous);
    testCase.verifyTrue(knownLeft.IsContinuous);
    testCase.verifyEqual(objectVariables(sdpLeft), getvariables(X));
    testCase.verifyEqual(objectVariables(knownLeft), getvariables(Y));
    verifyCoeffExpr(testCase, sdpLeft.coeffs(1), {X * a0, X * a1});
    verifyCoeffExpr(testCase, sdpLeft.coeffs(2), {X * a1, X * a2});
    verifyCoeffExpr(testCase, knownLeft.coeffs(1), {a0 * Y, a1 * Y});
    verifyCoeffExpr(testCase, knownLeft.coeffs(2), {a1 * Y, a2 * Y});

    vars = unique([getvariables(X), getvariables(Y)]);
    assign(recover(vars), 1:numel(vars));
    for rho = [0 0.25 0.5 0.75 1]
        known = A.evaluate(rho);
        testCase.verifyEqual(value(sdpLeft.evaluate(rho)), ...
            value(X) * known, AbsTol=1e-10);
        testCase.verifyEqual(value(knownLeft.evaluate(rho)), ...
            known * value(Y), AbsTol=1e-10);
    end
end

function testScaComMat(testCase)
    % Exercise the complete accepted scalar/matrix compatibility table.
    x = sdpvar(1, 1);
    X = sdpvar(2, 2, 'full');
    S = pdmat([0 1], {2, 3, 4}, Degree=2);
    A = pdmat([0 1], {eye(2), 2 * eye(2)}, Degree=1);
    G = pdvar(1, [0 1], Degree=2);
    P = pdvar(2, 2, [0 1], "full", Degree=1);

    scalars = {3, x, S, G};
    matrices = {[1 2; 3 5], A, X, P};
    pairs = [
        1 1; 1 2; 2 1; 2 2; 3 1; 3 2; 4 1; 4 2
        1 3; 1 4; 3 3; 3 4
        ];

    vars = unique([getvariables(x), getvariables(X), ...
        objectVariables(G), objectVariables(P)]);
    assign(recover(vars), 1:numel(vars));

    for k = 1:size(pairs, 1)
        scalar = scalars{pairs(k, 1)};
        matrix = matrices{pairs(k, 2)};
        left = scalar * matrix;
        right = matrix * scalar;
        verifyCompatibilityPair(testCase, scalar, matrix, left, right);
    end
end

function testSdpPdmRateRows(testCase)
    % Symbolic scaling and matrix products retain every known-data rate row.
    rb = [-1 2];
    x = sdpvar(1, 1);
    X = sdpvar(2, 2, 'full');
    L = sdpvar(3, 2, 'full');
    R = sdpvar(2, 4, 'full');
    matrixData = pdmat([0 1], {{ ...
        eye(2), 2 * eye(2); ...
        3 * eye(2), 4 * eye(2)}}, Degree=1, RateBounds=rb);
    scalarData = pdmat([0 1], {{1, 2; 10, 14}}, ...
        Degree=1, RateBounds=rb);

    verifySdpRateProduct(testCase, x * matrixData, ...
        {x * eye(2), x * 2 * eye(2); ...
        x * 3 * eye(2), x * 4 * eye(2)}, getvariables(x));
    verifySdpRateProduct(testCase, matrixData * x, ...
        {eye(2) * x, 2 * eye(2) * x; ...
        3 * eye(2) * x, 4 * eye(2) * x}, getvariables(x));
    verifySdpRateProduct(testCase, scalarData * X, ...
        {X, 2 * X; 10 * X, 14 * X}, getvariables(X));
    verifySdpRateProduct(testCase, X * scalarData, ...
        {X, X * 2; X * 10, X * 14}, getvariables(X));

    leftProduct = L * matrixData;
    rightProduct = matrixData * R;
    testCase.verifyClass(leftProduct, "pdvar");
    testCase.verifyClass(rightProduct, "pdvar");
    testCase.verifyEqual(size(leftProduct), [3 2]);
    testCase.verifyEqual(size(rightProduct), [2 4]);
    testCase.verifyEqual(leftProduct.RateBounds, rb);
    testCase.verifyEqual(rightProduct.RateBounds, rb);
    testCase.verifyEqual(leftProduct.NumRateRows, 2);
    testCase.verifyEqual(rightProduct.NumRateRows, 2);
    testCase.verifyEqual(objectVariables(leftProduct), getvariables(L));
    testCase.verifyEqual(objectVariables(rightProduct), getvariables(R));
    verifyCoeffExpr(testCase, leftProduct.coeffs(1), { ...
        L, L * 2; L * 3, L * 4});
    verifyCoeffExpr(testCase, rightProduct.coeffs(1), { ...
        R, 2 * R; 3 * R, 4 * R});
end

function testSdpPdmZerCom(testCase)
    % Proven known zeros should keep the compact zero-product contract.
    x = sdpvar(1, 1);
    X = sdpvar(2, 2, 'full');
    scalarZero = pdmat([0 1], {0, 0, 0}, Degree=2);
    matrixZero = pdmat([0 1], {zeros(2), zeros(2)}, Degree=1);
    rectZero = pdmat([0 1], {zeros(3, 4), zeros(3, 4)}, Degree=1);
    L = sdpvar(2, 3, 'full');
    R = sdpvar(4, 2, 'full');

    verifyZeroPdvar(testCase, scalarZero * X, [2 2]);
    verifyZeroPdvar(testCase, X * scalarZero, [2 2]);
    verifyZeroPdvar(testCase, x * matrixZero, [2 2]);
    verifyZeroPdvar(testCase, matrixZero * x, [2 2]);
    verifyZeroPdvar(testCase, L * rectZero, [2 4]);
    verifyZeroPdvar(testCase, rectZero * R, [3 2]);
end

function testScaDecMatRej(testCase)
    % Package expressions still reject every scalar/matrix double-decision order.
    x = sdpvar(1, 1);
    X = sdpvar(2, 2, 'full');
    G = pdvar(1, [0 1]);
    P = pdvar(2, 2, [0 1], "full");
    ops = {@() x * P, @() P * x, @() G * X, @() X * G, ...
        @() G * P, @() P * G};

    for k = 1:numel(ops)
        testCase.verifyError(ops{k}, "pdvar:InvalidMultiplication");
    end
end

function testSdpPdmRej(testCase)
    % The matrix bridge preserves dimension and coefficient-evidence guards.
    x = sdpvar(1, 1);
    y = sdpvar(1, 1);
    X = sdpvar(3, 4, 'full');
    A = pdmat([0 1], {eye(2), 2 * eye(2)}, Degree=1);
    F = pdmat([0 1], @(rho) rho);
    nonlinear = x * y;
    complexScalar = x + 1i * y;

    testCase.verifyError(@() A * X, "pdmat:InvalidMultiplication");
    testCase.verifyError(@() X * A, "pdmat:InvalidMultiplication");
    testCase.verifyError(@() nonlinear * A, "pdmat:InvalidMultiplication");
    testCase.verifyError(@() A * complexScalar, "pdmat:InvalidMultiplication");
    testCase.verifyError(@() F * X, "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() X * F, "pdmat:FunctionOnlyAlgebra");
end

function testMetRatBouSdpPdm(testCase)
    % Metadata-only known bounds remain ordinary rows in the hidden bridge.
    rb = [-1 2];
    X = sdpvar(3, 4, 'full');
    Y = sdpvar(4, 2, 'full');
    a0 = reshape(1:6, 2, 3);
    a1 = a0 + 10;
    R = pdmat([0 1], {a0, a1}, Degree=1, RateBounds=rb);

    L = R * X;
    U = Y * R;

    testCase.verifyEqual(size(L), [2 4]);
    testCase.verifyEqual(size(U), [4 3]);
    testCase.verifyEqual(L.RateBounds, rb);
    testCase.verifyEqual(U.RateBounds, rb);
    testCase.verifyEqual(L.NumRateRows, 0);
    testCase.verifyEqual(U.NumRateRows, 0);
    testCase.verifyEqual(objectVariables(L), getvariables(X));
    testCase.verifyEqual(objectVariables(U), getvariables(Y));
    verifyCoeffExpr(testCase, L.coeffs(1), {a0 * X, a1 * X});
    verifyCoeffExpr(testCase, U.coeffs(1), {Y * a0, Y * a1});
end

function testDerProPreRatRow(testCase)
    % Known-data products should preserve one output row per rate vertex.
    P = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);
    A = pdmat({[0 1]}, {10, 20}, Degree=1);

    L = A * D;
    R = D * A;
    S = 3 * D;
    T = D * 4;

    testCase.verifyEqual(L.Degree, 1);
    testCase.verifyEqual(L.RateBounds, [-1 2]);
    verifyCoeffExpr(testCase, L.coeffs(1), {
        10 * cd{1, 1}, 20 * cd{1, 1}
        10 * cd{2, 1}, 20 * cd{2, 1}
    });
    verifyCoeffExpr(testCase, R.coeffs(1), {
        cd{1, 1} * 10, cd{1, 1} * 20
        cd{2, 1} * 10, cd{2, 1} * 20
    });
    verifyCoeffExpr(testCase, S.coeffs(1), {3 * cd{1, 1}; 3 * cd{2, 1}});
    verifyCoeffExpr(testCase, T.coeffs(1), {cd{1, 1} * 4; cd{2, 1} * 4});
end

function testExpPdmRatRowMul(testCase)
    % One known rate-row factor is affine-safe on either side of pdvar.
    rb = [-1 2];
    P = pdvar(1, [0 1]);
    cp = P.coeffs(1);
    R = pdmat([0 1], {{1, 3; 10, 14}}, ...
        Degree=1, RateBounds=rb);

    L = R * P;
    U = P * R;
    expected = {
        cp{1}, (3 * cp{1} + cp{2}) / 2, 3 * cp{2}
        10 * cp{1}, (14 * cp{1} + 10 * cp{2}) / 2, 14 * cp{2}
        };

    testCase.verifyClass(L, "pdvar");
    testCase.verifyClass(U, "pdvar");
    testCase.verifyEqual(L.RateBounds, rb);
    testCase.verifyEqual(U.RateBounds, rb);
    verifyCoeffExpr(testCase, L.coeffs(1), expected);
    verifyCoeffExpr(testCase, U.coeffs(1), expected);
end

function testDerNumMatPro(testCase)
    % Numeric matrices may multiply a rate-row vector on either side.
    V = pdvar(2, 1, {[0 1]}, "full");
    D = rhodiff(V, [-1 1]);
    cd = D.coeffs(1);

    L = [1 2] * D;
    R = D * [4 5];

    testCase.verifyEqual(size(L), [1 1]);
    testCase.verifyEqual(size(R), [2 2]);
    verifyCoeffExpr(testCase, L.coeffs(1), {[1 2] * cd{1, 1}; [1 2] * cd{2, 1}});
    verifyCoeffExpr(testCase, R.coeffs(1), {cd{1, 1} * [4 5]; cd{2, 1} * [4 5]});
end

function testScaMixProAllOne(testCase)
    % Every scalar/matrix placement should preserve one derivative row table.
    rb = [-1 2];
    scalarData = pdmat([0 1], {1, 3}, Degree=1, RateBounds=rb);
    matrixData = pdmat([0 1], {eye(2), 2 * eye(2)}, ...
        Degree=1, RateBounds=rb);
    ordinaryScalarData = pdmat([0 1], {2, 4}, Degree=1);
    ordinaryMatrixData = pdmat([0 1], ...
        {eye(2), 2 * eye(2)}, Degree=1);
    scalarDecision = pdvar(1, [0 1]);
    matrixDecision = pdvar(2, 2, [0 1], "full");
    derivativeScalarData = rhodiff(scalarData);
    derivativeMatrixData = rhodiff(matrixData);
    derivativeScalarDecision = rhodiff(scalarDecision, rb);
    derivativeMatrixDecision = rhodiff(matrixDecision, rb);
    cs = scalarDecision.coeffs(1);
    cm = matrixDecision.coeffs(1);
    cds = derivativeScalarDecision.coeffs(1);
    cdm = derivativeMatrixDecision.coeffs(1);

    expectedDataScalar = {
        -2 * cm{1}, -2 * cm{2}
        4 * cm{1}, 4 * cm{2}
        };
    expectedDecisionMatrix = {
        2 * cdm{1, 1}, 4 * cdm{1, 1}
        2 * cdm{2, 1}, 4 * cdm{2, 1}
        };
    expectedDecisionScalar = {
        cds{1, 1} * eye(2), cds{1, 1} * 2 * eye(2)
        cds{2, 1} * eye(2), cds{2, 1} * 2 * eye(2)
        };
    expectedDataMatrix = {
        cs{1} * -eye(2), cs{2} * -eye(2)
        cs{1} * 2 * eye(2), cs{2} * 2 * eye(2)
        };

    verifyRateProduct(testCase, derivativeScalarData * matrixDecision, ...
        expectedDataScalar);
    verifyRateProduct(testCase, matrixDecision * derivativeScalarData, ...
        expectedDataScalar);
    verifyRateProduct(testCase, ordinaryScalarData * derivativeMatrixDecision, ...
        expectedDecisionMatrix);
    verifyRateProduct(testCase, derivativeMatrixDecision * ordinaryScalarData, ...
        expectedDecisionMatrix);
    verifyRateProduct(testCase, derivativeScalarDecision * ordinaryMatrixData, ...
        expectedDecisionScalar);
    verifyRateProduct(testCase, ordinaryMatrixData * derivativeScalarDecision, ...
        expectedDecisionScalar);
    verifyRateProduct(testCase, scalarDecision * derivativeMatrixData, ...
        expectedDataMatrix);
    verifyRateProduct(testCase, derivativeMatrixData * scalarDecision, ...
        expectedDataMatrix);

    testCase.verifyError( ...
        @() derivativeScalarData * derivativeMatrixDecision, ...
        "pdvar:InvalidMultiplication");
    testCase.verifyError( ...
        @() derivativeMatrixDecision * derivativeScalarData, ...
        "pdvar:InvalidMultiplication");
    testCase.verifyError( ...
        @() derivativeScalarDecision * derivativeMatrixData, ...
        "pdvar:InvalidMultiplication");
    testCase.verifyError( ...
        @() derivativeMatrixData * derivativeScalarDecision, ...
        "pdvar:InvalidMultiplication");
end

function testZerProCleMetAnd(testCase)
    % Zero products should not carry decision/rate metadata or form BMIs.
    P = pdvar(2, 1, {[0 1]}, "full");
    D = rhodiff(P, [-1 1]);
    V = pdvar(1, 2, {[0 1]}, "full");
    W = pdvar(2, 1, {[0 1]}, "full");
    Z = V - V;

    Z1 = P * 0;
    Z2 = 0 * P;
    Z3 = D * 0;
    Z4 = zeros(1, 2) * P;
    Z5 = P * zeros(1, 3);
    Z6 = Z * W;
    Z7 = Z * 2;
    Z8 = 2 * Z;

    verifyZeroPdvar(testCase, Z1, [2 1]);
    verifyZeroPdvar(testCase, Z2, [2 1]);
    verifyZeroPdvar(testCase, Z3, [2 1]);
    verifyZeroPdvar(testCase, Z4, [1 1]);
    verifyZeroPdvar(testCase, Z5, [2 3]);
    verifyZeroPdvar(testCase, Z6, [1 1]);
    verifyZeroPdvar(testCase, Z7, [1 2]);
    verifyZeroPdvar(testCase, Z8, [1 2]);
    testCase.verifyError(@() P * zeros(2, 1), "pdvar:InvalidMultiplication");
    testCase.verifyError(@() Z * NaN, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() complex(0, 1) * Z, "pdvar:InvalidMultiplication");
end

function testRatRowZerProNor(testCase)
    % Zero derivative products validate both rate-aware operand orders.
    P = pdvar(1, {[0 1]}, Degree=1);
    D = rhodiff(P, [-1 1]);
    Z = D - D;
    A = pdmat([0 1], {2, 3}, Degree=1);

    left = Z * A;
    right = A * Z;

    verifyZeroPdvar(testCase, left, [1 1]);
    verifyZeroPdvar(testCase, right, [1 1]);
end

function testMixScaGriUseCom(testCase)
    % Products on same-bound mixed grids are recomputed cell-locally.
    P = pdvar(1, {[0 1]});
    A = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    cp = P.coeffs(1);

    C = P * A;

    testCase.verifyEqual(C.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(C.Degree, 2);
    pMid = 0.5 * cp{1} + 0.5 * cp{2};
    verifyCoeffExpr(testCase, C.coeffs(1), { ...
        cp{1} * 10, ...
        (cp{1} * 20 + pMid * 10) / 2, ...
        pMid * 20});
    verifyCoeffExpr(testCase, C.coeffs(2), { ...
        pMid * 20, ...
        (pMid * 30 + cp{2} * 20) / 2, ...
        cp{2} * 30});
end

function testComKnoDecExp(testCase)
    % Chained affine products should preserve degree growth and coefficients.
    P = pdvar(1, {[0 1]});
    A = pdmat({[0 1]}, {10, 20}, Degree=1);
    B = pdmat({[0 1]}, {1, 2, 3}, Degree=2);
    C = pdmat({[0 1]}, {4, 5}, Degree=1);
    D = pdmat({[0 1]}, {7, 8, 9, 10}, Degree=3);
    cp = P.coeffs(1);

    E = (P * A + B) * C - D;

    s0 = 10 * cp{1} + 1;
    s1 = (20 * cp{1} + 10 * cp{2}) / 2 + 2;
    s2 = 20 * cp{2} + 3;
    testCase.verifyEqual(E.Degree, 3);
    verifyCoeffExpr(testCase, E.coeffs(1), { ...
        s0 * 4 - 7, ...
        s0 * 5 / 3 + s1 * 8 / 3 - 8, ...
        s1 * 10 / 3 + s2 * 4 / 3 - 9, ...
        s2 * 5 - 10});
end

function testRejUnsPro(testCase)
    % Products that leave the affine SDP layer should fail clearly.
    P = pdvar(1, {[0 1]});
    Q = pdvar(1, {[0 1]});
    V = pdvar(2, 1, {[0 1]}, "full");
    A = pdmat({[0 2]}, {1, 2}, Degree=1);
    B = pdmat({[0 1]}, {ones(2), 2 * ones(2)}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho);
    x = sdpvar(1, 1);
    X = pdvar(2, 2, {[0 1]}, "full");

    testCase.verifyError(@() P * Q, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() P * X, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() X * P, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() P * x, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() P * F, "pdvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() F * P, "pdvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() P * A, "pdvar:MixedGrid");
    testCase.verifyError(@() V * B, "pdvar:InvalidMultiplication");
end

function testRejUnsDerPro(testCase)
    % Rate-row products require a matching-grid known-data partner.
    P = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 1]);
    Q = pdvar(1, {[0 1]});
    A = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    B = pdmat({[0 2]}, {10, 20}, Degree=1);

    testCase.verifyError(@() D * D, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() D * Q, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() Q * D, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() D * A, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() A * D, "pdvar:InvalidMultiplication");
    testCase.verifyError(@() D * B, "pdvar:MixedGrid");
end

function verifyCoeffExpr(testCase, actual, expected)
    % Compare numeric or affine coefficient expressions without solving them.
    testCase.verifyEqual(numel(actual), numel(expected));
    for k = 1:numel(expected)
        diff = actual{k} - expected{k};
        if isa(diff, "sdpvar")
            base = full(getbase(diff));
            testCase.verifyEqual(base, zeros(size(base)), AbsTol=1e-10);
        else
            testCase.verifyEqual(diff, zeros(size(diff)), AbsTol=1e-10);
        end
    end
end

function verifyRateProduct(testCase, obj, expected)
    % Check one mixed scalar/matrix product and all of its derivative rows.
    testCase.verifyClass(obj, "pdvar");
    testCase.verifyEqual(size(obj), [2 2]);
    testCase.verifyEqual(obj.Degree, 1);
    testCase.verifyEqual(obj.RateBounds, [-1 2]);
    testCase.verifyEqual(size(obj.coeffs(1)), [2 2]);
    verifyCoeffExpr(testCase, obj.coeffs(1), expected);
end

function verifyScalarProduct(testCase, obj, sz, deg, expected, vars)
    % Check scalar broadcasting without introducing new YALMIP decisions.
    testCase.verifyClass(obj, "pdvar");
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.Degree, deg);
    testCase.verifyEqual(obj.GridInfo.Vectors{1}, [0 1]);
    testCase.verifyEqual(objectVariables(obj), unique(vars));
    verifyCoeffExpr(testCase, obj.coeffs(1), expected);
end

function verifyCompatibilityPair(testCase, scalar, matrix, left, right)
    % Check class, metadata, identities, and values for both operand orders.
    expectedClass = productClass(scalar, matrix);
    expectedDegree = operandDegree(scalar) + operandDegree(matrix);
    expectedVars = unique([operandVariables(scalar), operandVariables(matrix)]);

    testCase.verifyClass(left, expectedClass);
    testCase.verifyClass(right, expectedClass);
    testCase.verifyEqual(size(left), [2 2]);
    testCase.verifyEqual(size(right), [2 2]);
    if isa(left, "pdbase")
        testCase.verifyEqual(left.Degree, expectedDegree);
        testCase.verifyEqual(right.Degree, expectedDegree);
        testCase.verifyEqual(left.GridInfo.Vectors{1}, [0 1]);
        testCase.verifyEqual(right.GridInfo.Vectors{1}, [0 1]);
    end
    if isa(left, "pdvar")
        testCase.verifyEqual(objectVariables(left), expectedVars);
        testCase.verifyEqual(objectVariables(right), expectedVars);
    end

    for rho = [0 0.25 0.7 1]
        scalarValue = operandValue(scalar, rho);
        matrixValue = operandValue(matrix, rho);
        testCase.verifyEqual(operandValue(left, rho), ...
            scalarValue * matrixValue, AbsTol=1e-10);
        testCase.verifyEqual(operandValue(right, rho), ...
            matrixValue * scalarValue, AbsTol=1e-10);
    end
end

function verifySdpRateProduct(testCase, obj, expected, vars)
    % Check the complete explicit rate-row table after symbolic scaling.
    testCase.verifyClass(obj, "pdvar");
    testCase.verifyEqual(size(obj), [2 2]);
    testCase.verifyEqual(obj.Degree, 1);
    testCase.verifyEqual(obj.RateBounds, [-1 2]);
    testCase.verifyEqual(obj.NumRateRows, 2);
    testCase.verifyEqual(objectVariables(obj), unique(vars));
    verifyCoeffExpr(testCase, obj.coeffs(1), expected);
end

function name = productClass(lhs, rhs)
    % Return the class required by the accepted scalar compatibility table.
    if isa(lhs, "pdvar") || isa(rhs, "pdvar") || ...
            ((isa(lhs, "sdpvar") || isa(rhs, "sdpvar")) && ...
            (isa(lhs, "pdmat") || isa(rhs, "pdmat")))
        name = "pdvar";
    elseif isa(lhs, "pdmat") || isa(rhs, "pdmat")
        name = "pdmat";
    elseif isa(lhs, "sdpvar") || isa(rhs, "sdpvar")
        name = "sdpvar";
    else
        name = "double";
    end
end

function deg = operandDegree(obj)
    % Numeric and bare sdpvar operands are parameter-independent Degree zero.
    if isa(obj, "pdbase")
        deg = obj.Degree;
    else
        deg = 0;
    end
end

function vars = operandVariables(obj)
    % Collect decision identifiers without counting known pdmat coefficients.
    if isa(obj, "pdvar")
        vars = objectVariables(obj);
    elseif isa(obj, "sdpvar")
        vars = getvariables(obj);
    else
        vars = [];
    end
end

function val = operandValue(obj, rho)
    % Evaluate package and native operands through one test-only oracle.
    if isa(obj, "pdbase")
        val = value(obj.evaluate(rho));
    elseif isa(obj, "sdpvar")
        val = value(obj);
    else
        val = obj;
    end
end

function verifyZeroPdvar(testCase, obj, sz)
    % Zero product shortcuts should return compact ordinary coefficients.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.Degree, zeros(1, obj.npar()));
    testCase.verifyFalse(obj.ContainsDecision);
    testCase.verifyEmpty(obj.RateBounds);
    coeffs = obj.coeffs(ones(1, obj.npar()));
    testCase.verifyEqual(numel(coeffs), 1);
    testCase.verifyEqual(coeffs{1}, zeros(sz));
end

function vars = objectVariables(obj)
    % Collect unique symbolic identifiers across the complete coefficient tree.
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
