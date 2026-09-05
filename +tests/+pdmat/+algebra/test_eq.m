function tests = test_eq
    % Behavioral regressions for pdmat.eq.
    tests = functiontests(localfunctions);
end

function test_function_only_self_equality_rejected(testCase)
    % Coefficient equality is distinct from handle identity through isequal.
    F = pdmat([0 1], @(x) [x 2*x; 3*x 1+x]);
    calls = {@() F == F, @() F == 0, @() 0 == F};
    for k = 1:numel(calls)
        testCase.verifyError(calls{k}, "pdmat:FunctionOnlyAlgebra");
    end
    testCase.verifyTrue(isequal(F, F));
end

function test_equality_returns_logical_coefficient_backed(testCase)
    % Equality returns one logical from the coefficient-backed difference.
    A = pdmat({[0 1]}, {1, 3}, Degree=1);
    same = pdmat({[0 0.5 1]}, {1, 2, 3}, Degree=1);
    different = pdmat({[0 1]}, {1, 4}, Degree=1);

    testCase.verifyTrue(A == same);
    testCase.verifyFalse(A == different);
    testCase.verifyClass(A == same, "logical");
    testCase.verifySize(A == same, [1 1]);
end

function test_numeric_equality_reuse_scalar_expansion_matrix(testCase)
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

function test_equality_subtraction_owned_numeric_validation_api(testCase)
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
