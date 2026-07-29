function tests = test_algebra
    %TEST_ALGEBRA Coefficient-backed pdmat arithmetic.
    tests = functiontests(localfunctions);
end

function testAdditionElevatesDegree(testCase)
    % Addition should elevate lower-degree operands before summing coefficients.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);
    B = pdmat({[0 1]}, {10, 20, 30}, Degree=2);

    C = A + B;

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyTrue(C.IsContinuous);
    testCase.verifyEqual(C.SourceSummary, "coefficient-backed");
    testCase.verifyEmpty(C.FunctionHandle);
    verifyCoeff(testCase, C, 1, {11, 21.5, 32});
end

function testSubtractionAndUnaryMinus(testCase)
    % Subtraction and unary minus should operate coefficient-wise.
    A = pdmat({[0 1]}, {1, 3}, Degree=1);
    B = pdmat({[0 1]}, {4, 8}, Degree=1);

    verifyCoeff(testCase, B - A, 1, {3, 5});
    verifyCoeff(testCase, -A, 1, {-1, -3});
end

function testEqualityUsesZeroDifference(testCase)
    % Equality returns one logical from the coefficient-backed difference.
    A = pdmat({[0 1]}, {1, 3}, Degree=1);
    same = pdmat({[0 0.5 1]}, {1, 2, 3}, Degree=1);
    different = pdmat({[0 1]}, {1, 4}, Degree=1);

    testCase.verifyTrue(A == same);
    testCase.verifyFalse(A == different);
    testCase.verifyClass(A == same, "logical");
    testCase.verifySize(A == same, [1 1]);
end

function testEqualitySupportsSubtractionCompatibleNumericOperands(testCase)
    % Numeric equality should reuse scalar expansion and matrix subtraction.
    Z = pdmat({[0 1]}, {zeros(2), zeros(2)}, Degree=1);
    I = pdmat({[0 1]}, {eye(2), eye(2)}, Degree=1);
    O = pdmat({[0 1]}, {ones(2), ones(2)}, Degree=1);

    testCase.verifyTrue((I - I) == 0);
    testCase.verifyTrue(0 == (I - I));
    testCase.verifyTrue(O == 1);
    testCase.verifyTrue(1 == O);
    testCase.verifyTrue(I == eye(2));
    testCase.verifyTrue(eye(2) == I);
    testCase.verifyFalse(I == 0);
    testCase.verifyFalse(0 == I);
    testCase.verifyFalse(I == [1 0; 0 2]);
    testCase.verifyFalse([1 0; 0 2] == I);
    testCase.verifyClass(Z == 0, "logical");
    testCase.verifySize(Z == 0, [1 1]);
end

function testEqualityRejectsInvalidNumericAndUnsupportedOperands(testCase)
    % Equality keeps subtraction-owned numeric validation and API errors.
    A = pdmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    notFinite = str2double("NaN");

    testCase.verifyError(@() A == ones(1, 3), ...
        "pdmat:InvalidSubtraction");
    testCase.verifyError(@() A == notFinite, "pdmat:InvalidSubtraction");
    testCase.verifyError(@() A == 1i, "pdmat:InvalidSubtraction");
    testCase.verifyError(@() A == [], "pdmat:InvalidSubtraction");
    testCase.verifyError(@() A == "zero", "pdmat:InvalidEquality");
end

function testMatrixMultiplicationDegreeGrowth(testCase)
    % Matrix multiplication should convolve Bernstein coefficients and grow degree.
    A = pdmat({[0 1]}, {[1 2], [3 4]}, Degree=1);
    B = pdmat({[0 1]}, {[5; 6], [7; 8]}, Degree=1);

    C = A * B;

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyEqual(size(C), [1 1]);
    verifyCoeff(testCase, C, 1, {17, 31, 53});
end

function testChainedScalarMultiplicationCubicCoefficients(testCase)
    % Chained scalar products should retain cubic Bernstein coefficients.
    A = pdmat({[0 1]}, {2, 5}, Degree=1);
    B = pdmat({[0 1]}, {7, 11}, Degree=1);
    C = pdmat({[0 1]}, {3, 4}, Degree=1);

    L = A * B * C;

    testCase.verifyEqual(L.Degree, 3);
    verifyCoeff(testCase, L, 1, {42, 227 / 3, 131, 220});
end

function testTensorGridCoefficientProduct(testCase)
    % Tensor-grid products should preserve tensor coefficient ordering.
    grid = {[0 1], [10 20]};
    A = pdmat(grid, {1 2; 3 4}, Degree=1);
    B = pdmat(grid, {5 6; 7 8}, Degree=1);

    K = A * B;
    coeffs = K.coeffs([1 1]);

    testCase.verifyEqual(K.Degree, [2 2]);
    testCase.verifyEqual(size(K), [1 1]);
    testCase.verifyEqual(numel(coeffs), 9);
    testCase.verifyEqual(coeffs{1}, 5);
    testCase.verifyEqual(coeffs{5}, 15);
    testCase.verifyEqual(coeffs{9}, 32);
end

function testTensorHighDegreeProduct(testCase)
    % A 2-D degree-2 by degree-1 product should use tensor binomial scaling.
    grid = {[0 1], [10 20]};
    Adata = cell(3, 3);
    Bdata = cell(2, 2);
    for i = 0:2
        for j = 0:2
            Adata{i + 1, j + 1} = i + 10 * j;
        end
    end
    for i = 0:1
        for j = 0:1
            Bdata{i + 1, j + 1} = 100 + i + 10 * j;
        end
    end
    A = pdmat(grid, Adata, Degree=2);
    B = pdmat(grid, Bdata, Degree=1);

    C = A * B;

    testCase.verifyEqual(C.Degree, [3 3]);
    verifyCoeff(testCase, C, [1 1], ...
        bernProdExpected(A.coeffs([1 1]), 2, B.coeffs([1 1]), 1, 2));
end

function testMixedScalarGridUsesCommonRefinement(testCase)
    % Same-bound mixed scalar grids should align on a common refinement.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);
    B = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);

    S = A + B;
    P = A * B;

    testCase.verifyEqual(S.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(P.GridInfo.Vectors{1}, [0 0.5 1]);
    verifyCoeff(testCase, S, 1, {11, 21.5});
    verifyCoeff(testCase, S, 2, {21.5, 32});
    verifyCoeff(testCase, P, 1, {10, 17.5, 30});
    verifyCoeff(testCase, P, 2, {30, 42.5, 60});
end

function testMixedTensorGridUsesCommonRefinement(testCase)
    % Same-bound tensor grids should refine each affected physical axis.
    A = pdmat({[0 1], [0 1]}, {1 2; 3 4}, Degree=1);
    B = pdmat({[0 0.5 1], [0 1]}, {10 20; 30 40; 50 60}, Degree=1);

    S = A + B;

    testCase.verifyEqual(S.GridInfo.Vectors, {[0 0.5 1], [0 1]});
    verifyCoeff(testCase, S, [1 1], {11, 22, 32, 43});
    verifyCoeff(testCase, S, [2 1], {32, 43, 53, 64});
end

function testNumericPromotion(testCase)
    % Numeric scalars should promote to compatible constant pdmat operands.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);

    verifyCoeff(testCase, A + 5, 1, {6, 7});
    verifyCoeff(testCase, 5 - A, 1, {4, 3});
    verifyCoeff(testCase, 2 * A, 1, {2, 4});
    verifyCoeff(testCase, A * 3, 1, {3, 6});
end

function testAdditionZeroFastPathsRetainCompatibilityChecks(testCase)
    % Proven and numeric zeros are identities only after size and grid checks.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);
    Z = A - A;

    testCase.verifyTrue(isequal(Z + A, A));
    testCase.verifyTrue(isequal(A + Z, A));
    testCase.verifyTrue(isequal(A + 0, A));
    testCase.verifyTrue(isequal(zeros(1) + A, A));

    matrixZero = pdmat({[0 1]}, {zeros(2), zeros(2)}, Degree=1);
    scalarData = pdmat({[0 1]}, {1, 2}, Degree=1);
    testCase.verifyError(@() matrixZero + scalarData, ...
        "pdmat:InvalidAddition");

    otherGrid = pdmat({[0 2]}, {1, 2}, Degree=1);
    testCase.verifyError(@() Z + otherGrid, "pdmat:MixedGrid");
end

function testRateRowZeroAdditionUsesGeneralPath(testCase)
    % A zero rate table must broadcast its rows instead of losing rate metadata.
    rb = [-1 2];
    Z = pdmat([0 1], {{0, 0; 0, 0}}, Degree=1, RateBounds=rb);
    A = pdmat([0 1], {3, 5}, Degree=1);

    S = Z + A;

    testCase.verifyTrue(S.HasRateDependence);
    testCase.verifyEqual(S.RateBounds, rb);
    testCase.verifyEqual(S.coeffs(1), {3, 5; 3, 5});
end

function testNumericMatrixMultiplication(testCase)
    % Numeric matrices should multiply pdmat operands on either side.
    A = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);

    L = [1 0] * A;
    R = A * [1; 2];

    testCase.verifyEqual(size(L), [1 2]);
    testCase.verifyEqual(size(R), [2 1]);
    verifyCoeff(testCase, L, 1, {[1 2], [5 6]});
    verifyCoeff(testCase, R, 1, {[5; 11], [17; 23]});
end

function testAnisotropicAdditionSubtractionAndMultiplication(testCase)
    % Degree alignment is componentwise while product degrees add by axis.
    grid = {[0 1], [10 20]};
    addLeft = cell(2, 4);
    addRight = cell(3, 2);
    for i = 0:1
        for j = 0:3
            addLeft{i + 1, j + 1} = i;
        end
    end
    for i = 0:2
        for j = 0:1
            addRight{i + 1, j + 1} = 10 * j;
        end
    end
    A = pdmat(grid, addLeft, Degree=[1 3]);
    B = pdmat(grid, addRight, Degree=[2 1]);

    sumObj = A + B;
    difference = A - B;
    labels = helper.combRows({0:2, 0:3});
    expectedSum = num2cell(labels(:, 1) ./ 2 + ...
        10 .* labels(:, 2) ./ 3).';
    expectedDifference = num2cell(labels(:, 1) ./ 2 - ...
        10 .* labels(:, 2) ./ 3).';

    testCase.verifyEqual(sumObj.Degree, [2 3]);
    testCase.verifyEqual(difference.Degree, [2 3]);
    verifyCoeff(testCase, sumObj, [1 1], expectedSum);
    verifyCoeff(testCase, difference, [1 1], expectedDifference);

    productLeft = cell(2, 3);
    productRight = cell(3, 2);
    for i = 0:1
        for j = 0:2
            productLeft{i + 1, j + 1} = i;
        end
    end
    for i = 0:2
        for j = 0:1
            productRight{i + 1, j + 1} = j;
        end
    end
    P = pdmat(grid, productLeft, Degree=[1 2]);
    Q = pdmat(grid, productRight, Degree=[2 1]);
    product = P * Q;
    productLabels = helper.combRows({0:3, 0:3});
    expectedProduct = num2cell( ...
        (productLabels(:, 1) ./ 3) .* ...
        (productLabels(:, 2) ./ 3)).';

    testCase.verifyEqual(product.Degree, [3 3]);
    verifyCoeff(testCase, product, [1 1], expectedProduct);
end

function testZeroDegreeAxisAndNumericOperandOrders(testCase)
    % Numeric promotion must preserve a direction that is exactly constant.
    grid = {[0 1], [10 20]};
    A = pdmat(grid, {1, 2, 3}, Degree=[0 2]);
    plusRight = A + 2;
    plusLeft = 2 + A;
    timesRight = A * 2;
    timesLeft = 2 * A;

    testCase.verifyEqual(plusRight.Degree, [0 2]);
    testCase.verifyEqual(plusLeft.Degree, [0 2]);
    testCase.verifyEqual(timesRight.Degree, [0 2]);
    testCase.verifyEqual(timesLeft.Degree, [0 2]);
    verifyCoeff(testCase, plusRight, [1 1], {3, 4, 5});
    verifyCoeff(testCase, plusLeft, [1 1], {3, 4, 5});
    verifyCoeff(testCase, timesRight, [1 1], {2, 4, 6});
    verifyCoeff(testCase, timesLeft, [1 1], {2, 4, 6});
end

function testScalarPdmatScalesNumericAndPdmatMatrices(testCase)
    % A 1-by-1 pdmat should scale matrices in either operand order.
    S = pdmat({[0 1]}, {2, 4}, Degree=1);
    M = [1 2; 3 4];
    A = pdmat({[0 0.5 1]}, ...
        {eye(2), 2 * eye(2), 3 * eye(2)}, Degree=1);
    F = pdmat({[0 1]}, @(rho) 1 + rho, Degree=1);

    numericRight = S * M;
    numericLeft = M * S;
    knownRight = S * A;
    knownLeft = A * S;

    testCase.verifyClass(numericRight, "pdmat");
    testCase.verifyClass(numericLeft, "pdmat");
    testCase.verifyEqual(size(numericRight), [2 2]);
    testCase.verifyEqual(size(numericLeft), [2 2]);
    testCase.verifyEqual(numericRight.Degree, 1);
    testCase.verifyEqual(numericLeft.Degree, 1);
    verifyCoeff(testCase, numericRight, 1, {2 * M, 4 * M});
    verifyCoeff(testCase, numericLeft, 1, {2 * M, 4 * M});

    testCase.verifyEqual(knownRight.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(knownLeft.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(size(knownRight), [2 2]);
    testCase.verifyEqual(size(knownLeft), [2 2]);
    testCase.verifyEqual(knownRight.Degree, 2);
    testCase.verifyEqual(knownLeft.Degree, 2);
    verifyCoeff(testCase, knownRight, 1, ...
        {2 * eye(2), 3.5 * eye(2), 6 * eye(2)});
    verifyCoeff(testCase, knownLeft, 1, ...
        {2 * eye(2), 3.5 * eye(2), 6 * eye(2)});
    verifyCoeff(testCase, knownRight, 2, ...
        {6 * eye(2), 8.5 * eye(2), 12 * eye(2)});
    verifyCoeff(testCase, knownLeft, 2, ...
        {6 * eye(2), 8.5 * eye(2), 12 * eye(2)});
    verifyCoeff(testCase, F * M, 1, {M, 2 * M});
    verifyCoeff(testCase, M * F, 1, {M, 2 * M});
end

function testAlgebraRejectsIncompatibleInputs(testCase)
    % Algebra should reject size, grid-bound, and function-only incompatibilities.
    A = pdmat({[0 1]}, {ones(1, 2), 2 * ones(1, 2)}, Degree=1);
    B = pdmat({[0 1]}, {1, 2}, Degree=1);
    C = pdmat({[0 2]}, {1, 2}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho);

    testCase.verifyError(@() A + B, "pdmat:InvalidAddition");
    testCase.verifyError(@() A * A, "pdmat:InvalidMultiplication");
    testCase.verifyError(@() B + C, "pdmat:MixedGrid");
    testCase.verifyError(@() F + 1, "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() F * eye(2), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() eye(2) * F, "pdmat:FunctionOnlyAlgebra");
end

function testFunctionBernsteinCanEnterAlgebra(testCase)
    % Function handles with Bernstein evidence should enter coefficient algebra.
    A = pdmat({[0 1]}, @(rho) rho, Degree=1);

    C = A + 1;

    testCase.verifyEqual(C.SourceSummary, "coefficient-backed");
    verifyCoeff(testCase, C, 1, {1, 2});
end

function testAnisotropicFunctionBernsteinCanEnterAlgebra(testCase)
    % A linear-by-quadratic handle should preserve its tensor degree in algebra.
    A = pdmat({[0 2], [10 14]}, @(rho, eta) rho + eta.^2, ...
        Degree=[1 2]);

    C = A + 1;

    testCase.verifyEqual(C.SourceSummary, "coefficient-backed");
    testCase.verifyEqual(C.Degree, [1 2]);
    verifyCoeff(testCase, C, [1 1], {101, 141, 197, 103, 143, 199});
    testCase.verifyEqual(C.evaluate([0.5 11]), 122.5, AbsTol=1e-10);
end

function testDiscontinuousInputRewrapStaysSilent(testCase)
    % Algebra should preserve discontinuity without repeating constructor warnings.
    localValues = {{1, 2}, {3, 4}};
    A = constructWithWarning(testCase, ...
        @() pdmat({[0 1 2]}, localValues, Degree=1), ...
        "pdmat:DiscontinuousLocalValues");

    C = constructWarningFree(testCase, @() A + 1);

    testCase.verifyFalse(A.IsContinuous);
    testCase.verifyFalse(C.IsContinuous);
    verifyCoeff(testCase, C, 1, {2, 3});
    verifyCoeff(testCase, C, 2, {4, 5});
end

function testZeroFastPathsCollapseDegree(testCase)
    % Provably zero arithmetic should return compact degree-zero data.
    A = pdmat({[0 1]}, {1, 3}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho * ones(2));

    Z1 = A - A;
    Z2 = A + (-A);
    Z3 = A * 0;
    Z4 = 0 * A;
    Z5 = F * 0;
    Z6 = Z1 * A;
    Z7 = Z1 * 2;
    Z8 = 2 * Z1;
    Z9 = Z1 * eye(2);
    Z10 = eye(2) * Z1;

    verifyZeroPdmat(testCase, Z1, [1 1]);
    verifyZeroPdmat(testCase, Z2, [1 1]);
    verifyZeroPdmat(testCase, Z3, [1 1]);
    verifyZeroPdmat(testCase, Z4, [1 1]);
    verifyZeroPdmat(testCase, Z5, [2 2]);
    verifyZeroPdmat(testCase, Z6, [1 1]);
    verifyZeroPdmat(testCase, Z7, [1 1]);
    verifyZeroPdmat(testCase, Z8, [1 1]);
    verifyZeroPdmat(testCase, Z9, [2 2]);
    verifyZeroPdmat(testCase, Z10, [2 2]);
    testCase.verifyTrue(isequal(A + Z1, A));
    testCase.verifyTrue(isequal(A - Z1, A));
    testCase.verifyError(@() F + 1, "pdmat:FunctionOnlyAlgebra");
end

function testZeroMatrixMultiplicationSizes(testCase)
    % Zero numeric matrices should still enforce matrix-product dimensions.
    A = pdmat({[0 1]}, {ones(2, 3), 2 * ones(2, 3)}, Degree=1);

    L = zeros(4, 2) * A;
    R = A * zeros(3, 5);

    verifyZeroPdmat(testCase, L, [4 3]);
    verifyZeroPdmat(testCase, R, [2 5]);
    testCase.verifyError(@() A * zeros(4, 1), "pdmat:InvalidMultiplication");
end

function out = bernProdExpected(lhs, lhsDeg, rhs, rhsDeg, nPar)
    % Local oracle for tensor Bernstein product coefficients.
    outDeg = lhsDeg + rhsDeg;
    lhsLbls = helper.combRows(repmat({0:lhsDeg}, 1, nPar));
    outLbls = helper.combRows(repmat({0:outDeg}, 1, nPar));
    out = cell(1, size(outLbls, 1));
    for outIdx = 1:size(outLbls, 1)
        outLbl = outLbls(outIdx, :);
        acc = [];
        for lhsIdx = 1:size(lhsLbls, 1)
            lhsLbl = lhsLbls(lhsIdx, :);
            rhsLbl = outLbl - lhsLbl;
            if all(rhsLbl >= 0) && all(rhsLbl <= rhsDeg)
                rhsIdx = lblIdxExpected(rhsLbl, rhsDeg);
                term = lhs{lhsIdx} * rhs{rhsIdx} ...
                    * prodScaleExpected(lhsLbl, lhsDeg, rhsLbl, rhsDeg, outLbl);
                if isempty(acc)
                    acc = term;
                else
                    acc = acc + term;
                end
            end
        end
        out{outIdx} = acc;
    end
end

function scale = prodScaleExpected(lhsLbl, lhsDeg, rhsLbl, rhsDeg, outLbl)
    outDeg = lhsDeg + rhsDeg;
    scale = 1;
    for k = 1:numel(outLbl)
        scale = scale ...
            * nchoosek(lhsDeg, lhsLbl(k)) ...
            * nchoosek(rhsDeg, rhsLbl(k)) ...
            / nchoosek(outDeg, outLbl(k));
    end
end

function idx = lblIdxExpected(lbl, deg)
    mult = (deg + 1) .^ (numel(lbl) - 1:-1:0);
    idx = sum(lbl .* mult) + 1;
end

function verifyCoeff(testCase, obj, cellSubs, expected)
    % Compare one physical cell's coefficients against numeric expectations.
    coeffs = obj.coeffs(cellSubs);
    testCase.verifyEqual(numel(coeffs), numel(expected));
    for k = 1:numel(expected)
        testCase.verifyEqual(coeffs{k}, expected{k}, AbsTol=1e-10);
    end
end

function verifyZeroPdmat(testCase, obj, sz)
    % Check the compact zero representation used by arithmetic fast paths.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.Degree, zeros(1, obj.npar()));
    coeffs = obj.coeffs(ones(1, obj.npar()));
    testCase.verifyEqual(numel(coeffs), 1);
    testCase.verifyEqual(coeffs{1}, zeros(sz));
end

function obj = constructWithWarning(testCase, fcn, warningId)
    % Capture one direct-construction warning while retaining its result.
    obj = [];
    testCase.verifyWarning(@construct, warningId);

    function construct
        obj = fcn();
    end
end

function obj = constructWarningFree(testCase, fcn)
    % Capture an algebra result while asserting its internal rewrap is silent.
    obj = [];
    testCase.verifyWarningFree(@construct);

    function construct
        obj = fcn();
    end
end
