function tests = test_isequal
    % Behavioral regressions for pdmat.isequal.
    tests = functiontests(localfunctions);
end

function test_equal_values_ignore_weaker_continuity_certificate(testCase)
    grid = {[0 1 3]};
    values = {{0, 1, 3, 6}, {6, 12, 22, 40}};
    inferred = pdmat(grid, values, Degree=3);
    weaker = pdmat(grid, values, Degree=3, Continuity=0);

    testCase.verifyEqual(inferred.Continuity, 2);
    testCase.verifyEqual(weaker.Continuity, 0);
    testCase.verifyTrue(isequal(inferred, weaker));
end
function test_later_rate_coefficient_breaks_equality(testCase)
    % A mismatch outside the first rate row must not compare equal.
    A = pdmat([0 1], {{1, 2; 3, 4}}, Degree=1, RateBounds=[-2 5]);
    B = pdmat([0 1], {{1, 2; 3, 4.01}}, Degree=1, RateBounds=[-2 5]);
    testCase.verifyFalse(isequal(A, B));
    testCase.verifyFalse(isequal(B, A));
    testCase.verifyFalse(isequal(A, A, B));
    testCase.verifyTrue(isequal(A, A.elevate(2)));
end

function test_function_identity_never_equals_placeholder_data(testCase)
    % Exact-handle identity is inspectable without equating placeholder zeros.
    fh = @(x) [x, 1+x];
    F = pdmat([0 1], fh);
    same = pdmat([0 1], fh);
    zero = pdmat([0 1], {zeros(1,2), zeros(1,2)}, Degree=1);
    valid = pdmat([0 1], fh, Degree=1);
    testCase.verifyTrue(isequal(F, same));
    testCase.verifyFalse(isequal(F, zero));
    testCase.verifyFalse(isequal(zero, F));
    testCase.verifyFalse(isequal(F, valid));
    testCase.verifyEqual(F.evaluate(.25), [.25 1.25]);
end

function test_equality_compare_coefficient_evidence_grid_degree(testCase)
    % Equality should compare coefficient evidence after grid/degree alignment.
    grid = [0 1];
    A = pdmat([0, 1], @(x) [-1, 0.5; -1, -2] + ...
        x * [-1.3, -20; 2, -10], Degree=1);
    A1 = pdmat(grid, {[-1, 0.5; -1, -2], ...
        [-1, 0.5; -1, -2] + [-1.3, -20; 2, -10]});
    B = pdmat({[0 0.5 1]}, {0, 0.5, 1}, Degree=1);
    C = pdmat({[0 1]}, {0, 0.5, 1}, Degree=2);
    D = pdmat({[0 1]}, {0, 1}, Degree=1);
    E = pdmat({[0 1]}, {0, 2}, Degree=1);
    F = pdmat({[0 2]}, {0, 2}, Degree=1);
    G = pdmat({[0 1]}, {zeros(2), ones(2)}, Degree=1);

    testCase.verifyTrue(isequal(A, A1));
    testCase.verifyTrue(isequal(B, C));
    testCase.verifyTrue(isequal(C, D));
    testCase.verifyFalse(isequal(D, E));
    testCase.verifyFalse(isequal(D, F));
    testCase.verifyFalse(isequal(D, G));

    testCase.verifyTrue(isequal(A));
    testCase.verifyFalse(isequal(1, A));
    fh = @(x) x;
    exactA = pdmat([0 1], fh);
    exactB = pdmat([0 1], fh);
    exactC = pdmat([0 1], @(x) x);
    testCase.verifyTrue(isequal(exactA, exactB));
    testCase.verifyFalse(isequal(exactA, exactC));
end
