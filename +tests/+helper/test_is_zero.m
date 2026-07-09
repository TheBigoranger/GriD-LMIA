function tests = test_is_zero
    %TEST_IS_ZERO Shared zero-classification helper.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep YALMIP coefficient bases deterministic for the dpvar object route.
    yalmip("clear");
end

function testNumericModeRejectsNonfiniteAndEmptyInputs(testCase)
    % Numeric zero evidence must be finite, real, nonempty, and identically zero.
    testCase.verifyTrue(helper.isZero(zeros(2), "num"));
    testCase.verifyFalse(helper.isZero([], "num"));
    testCase.verifyFalse(helper.isZero(Inf, "num"));
    testCase.verifyFalse(helper.isZero(1, "num"));
end

function testAdditiveModePreservesScalarExpansionAndShapeCheck(testCase)
    % Scalar zero expands, while an incompatible zero matrix must not bypass algebra checks.
    testCase.verifyTrue(helper.isZero(0, "add", [2 3]));
    testCase.verifyTrue(helper.isZero(zeros(2, 3), "add", [2 3]));
    testCase.verifyFalse(helper.isZero(zeros(2, 2), "add", [2 3]));
end

function testValuesModeHandlesNestedAndRateAffinePayloads(testCase)
    % Nested cells and Constant/Rate payloads share the same recursive evidence rule.
    zeroRate = struct("Constant", 0, "Rate", {{0}});
    nonzeroRate = struct("Constant", 0, "Rate", {{1}});

    testCase.verifyTrue(helper.isZero({0, {zeros(2)}}, "vals"));
    testCase.verifyTrue(helper.isZero(zeroRate, "vals"));
    testCase.verifyFalse(helper.isZero(nonzeroRate, "vals"));
    testCase.verifyFalse(helper.isZero({0, 1}, "vals"));
end

function testObjectModeDistinguishesExplicitAndPlaceholderEvidence(testCase)
    % Function-only dpmat placeholder zeros are not algebra evidence.
    A = dpmat({[0 1]}, {0, 0}, Degree=1);
    F = dpmat({[0 1]}, @(rho) 0);
    P = dpvar(1, {[0 1]});
    Z = P - P;

    testCase.verifyTrue(helper.isZero(A, "obj"));
    testCase.verifyFalse(helper.isZero(F, "obj"));
    testCase.verifyFalse(helper.isZero(P, "obj"));
    testCase.verifyTrue(helper.isZero(Z, "obj"));
end

function testInvalidModesAndArityFailClearly(testCase)
    % Helper misuse should fail as a helper-contract error, not as algebra input.
    testCase.verifyError(@() helper.isZero(0, "unknown"), "helper:InvalidZeroMode");
    testCase.verifyError(@() helper.isZero(0, "add"), "helper:InvalidZeroCall");
    testCase.verifyError(@() helper.isZero(0, 1), "helper:InvalidZeroMode");
end
