function tests = test_is_zero
    % Behavioral regressions for helper.is_zero.
    tests = functiontests(localfunctions);
end

function test_later_nested_affine_identity_and_distinct_variables(testCase)
    % Zero assigned values cannot erase independent decision identities.
    P = sdpvar(2,3,'full'); Q = sdpvar(2,3,'full');
    testCase.verifyTrue(helper.isZero({0, {P-P}}, "vals"));
    testCase.verifyFalse(helper.isZero({0, {P-Q}}, "vals"));
    testCase.verifyFalse(helper.isZero({0, {zeros(2), [0 0;0 eps]}}, "vals"));
end

function setupOnce(~)
    % Keep YALMIP coefficient bases deterministic for the pdvar object route.
    yalmip("clear");
end

function test_numeric_zero_evidence_finite_real_nonempty(testCase)
    % Numeric zero evidence must be finite, real, nonempty, and identically zero.
    testCase.verifyTrue(helper.isZero(zeros(2), "num"));
    testCase.verifyFalse(helper.isZero([], "num"));
    testCase.verifyFalse(helper.isZero(Inf, "num"));
    testCase.verifyFalse(helper.isZero(1, "num"));
end

function test_scalar_zero_expands_while_incompatible_zero(testCase)
    % Scalar zero expands, while an incompatible zero matrix must not bypass algebra checks.
    testCase.verifyTrue(helper.isZero(0, "add", [2 3]));
    testCase.verifyTrue(helper.isZero(zeros(2, 3), "add", [2 3]));
    testCase.verifyFalse(helper.isZero(zeros(2, 2), "add", [2 3]));
end

function test_nested_cells_constant_rate_payloads_share(testCase)
    % Nested cells and Constant/Rate payloads share the same recursive evidence rule.
    zeroRate = struct("Constant", 0, "Rate", {{0}});
    nonzeroRate = struct("Constant", 0, "Rate", {{1}});

    testCase.verifyTrue(helper.isZero({0, {zeros(2)}}, "vals"));
    testCase.verifyTrue(helper.isZero(zeroRate, "vals"));
    testCase.verifyFalse(helper.isZero(nonzeroRate, "vals"));
    testCase.verifyFalse(helper.isZero({0, 1}, "vals"));
end

function test_function_only_pdmat_placeholder_zeros_algebra(testCase)
    % Function-only pdmat placeholder zeros are not algebra evidence.
    A = pdmat({[0 1]}, {0, 0}, Degree=1);
    F = pdmat({[0 1]}, @(rho) 0);
    P = pdvar(1, {[0 1]});
    Z = P - P;

    testCase.verifyTrue(helper.isZero(A, "obj"));
    testCase.verifyFalse(helper.isZero(F, "obj"));
    testCase.verifyFalse(helper.isZero(P, "obj"));
    testCase.verifyTrue(helper.isZero(Z, "obj"));
    testCase.verifyFalse(helper.isZero(struct(), "obj"));
end

function test_helper_misuse_fail_as_helper_contract(testCase)
    % Helper misuse should fail as a helper-contract error, not as algebra input.
    testCase.verifyError(@() helper.isZero(0, "unknown"), "helper:InvalidZeroMode");
    testCase.verifyError(@() helper.isZero(0, "add"), "helper:InvalidZeroCall");
    testCase.verifyError(@() helper.isZero(0, 1), "helper:InvalidZeroMode");
end
