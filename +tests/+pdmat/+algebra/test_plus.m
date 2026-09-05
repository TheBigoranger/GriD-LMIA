function tests = test_plus
    % Behavioral regressions for pdmat.plus.
    tests = functiontests(localfunctions);
end

function test_function_only_zero_shortcuts_rejected(testCase)
    % Placeholder zeros cannot authorize an arithmetic identity shortcut.
    F = pdmat([0 1], @(x) [x 2*x; 3*x 1+x]);
    Z = pdmat([0 1], {zeros(2), zeros(2)}, Degree=1);
    saved = F.LocalValues;
    calls = {@() F + 0, @() 0 + F, @() F + zeros(2), ...
        @() zeros(2) + F, @() F + Z, @() Z + F};
    for k = 1:numel(calls)
        testCase.verifyError(calls{k}, "pdmat:FunctionOnlyAlgebra");
    end
    testCase.verifyEqual(F.LocalValues, saved);
    testCase.verifyEqual(F.evaluate(0.5), [0.5 1; 1.5 1.5]);
end

function test_addition_elevate_lower_degree_operands_summing(testCase)
    % Addition should elevate lower-degree operands before summing coefficients.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);
    B = pdmat({[0 1]}, {10, 20, 30}, Degree=2);

    C = A + B;

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyTrue(C.IsContinuous);
    testCase.verifyEqual(C.SourceSummary, "coefficient-backed");
    testCase.verifyEmpty(C.FunctionHandle);
    tests.infrastructure.verify_coeff(testCase, C, 1, {11, 21.5, 32});
end

function test_numeric_scalars_promote_compatible_constant_pdmat(testCase)
    % Numeric scalars should promote to compatible constant pdmat operands.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);

    tests.infrastructure.verify_coeff(testCase, A + 5, 1, {6, 7});
    tests.infrastructure.verify_coeff(testCase, 5 - A, 1, {4, 3});
    tests.infrastructure.verify_coeff(testCase, 2 * A, 1, {2, 4});
    tests.infrastructure.verify_coeff(testCase, A * 3, 1, {3, 6});
end

function test_proven_numeric_zeros_identities_only_size(testCase)
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

    matrixZero = pdmat({[0 1]}, {zeros(2), zeros(2)}, Degree=1);
    testCase.verifyError(@() A - matrixZero, ...
        "pdmat:InvalidSubtraction");
end

function test_ordinary_operands_broadcast_products_allow_explicit(testCase)
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

function R = rateScalar()
    % A two-row scalar fixture with one physical cell.
    R = pdmat([0 1], {{1, 3; 10, 14}}, ...
        Degree=1, RateBounds=[-1 2]);
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

function test_complete_residual_in_both_orders(testCase)
    A = tests.infrastructure.fixture("pdmat", true);
    saved = A.LocalValues;
    constant = [2 -7;11 3];
    left = A + constant;
    right = constant + A;
    for cellIndex = 1:2
        c = A.coeffs(cellIndex);
        tests.infrastructure.verify_expr(testCase,left.coeffs(cellIndex), ...
            cellfun(@(x) x + constant,c,'UniformOutput',false));
        tests.infrastructure.verify_expr(testCase,right.coeffs(cellIndex), ...
            cellfun(@(x) constant + x,c,'UniformOutput',false));
    end
    testCase.verifyEqual(A.LocalValues,saved);
    testCase.verifyError(@() A + ones(3), 'pdmat:InvalidAddition');
end
