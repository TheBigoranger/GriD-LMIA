function tests = test_eq
    % Behavioral regressions for pdvar.eq.
    tests = functiontests(localfunctions);
end

function test_elevated_tensor_identity_exports_no_constraints(testCase)
    % Exact symbolic identity survives anisotropic degree alignment over every cell.
    P = pdvar(2,3,{[0 2 5],[-3 1 6]},'full',Degree=[1 2]);
    C = elevate(P,[1 2])==P;
    testCase.verifyEqual(C.Relation,"==");
    testCase.verifyEmpty(C.Constraints);
    testCase.verifyEmpty(toYalmip(C));
    for subs = [1 1;1 2;2 1;2 2]'
        tests.infrastructure.verify_expr(testCase,C.Residual.coeffs(subs'),{zeros(2,3)});
    end
end

function setup(~)
    % Equality tests rely on isolated YALMIP handles and assignments.
    yalmip("clear");
end

function test_subtraction_aligns_grids_degrees_promotes_supported(testCase)
    % Subtraction aligns grids/degrees and promotes supported ordinary operands.
    P = pdvar(1, {[0 0.5 1]}, Degree=1);
    Q = pdvar(1, {[0 1]}, Degree=2);
    mixed = P == Q;

    testCase.verifyEqual(mixed.Relation, "==");
    testCase.verifyEqual(mixed.Residual.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(mixed.Residual.Degree, 2);
    testCase.verifyEqual(numel(mixed.Constraints), 2 * 3);

    R = pdvar(1, {[0 1]}, Degree=1);
    known = pdmat({[0 1]}, {1, 2}, Degree=1);
    x = sdpvar(1, 1);
    cases = {R == known, known == R, R == 2, 2 == R, R == x, x == R};
    for k = 1:numel(cases)
        testCase.verifyEqual(cases{k}.Relation, "==");
        testCase.verifyEqual(numel(cases{k}.Constraints), 2);
    end
end

function test_derivative_rows_cannot_broadcast_during_coefficient(testCase)
    % Derivative rows cannot be broadcast during coefficient equality.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    D = rhodiff(P);
    Q = pdvar(1, {[0 1]});

    testCase.verifyError(@() D == 0, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() 0 == D, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() D == Q, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() Q == D, "pdvar:InvalidEqualityRows");
end

function test_fast_internal_sampling_may_defer_later(testCase)
    % Fast internal sampling may defer later-cell row drift to equality.
    ordinary = {sdpvar(1, 1)};
    derivative = {sdpvar(1, 1); sdpvar(1, 1)};
    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {{[0 1 2]}}, ...
        "MatrixSize", [1 1], ...
        "Degree", 0, ...
        "LocalValues", {{ordinary, derivative}}, ...
        "IsContinuous", false, ...
        "ContainsDecision", true, ...
        "RateBounds", [], ...
        "SourceSummary", "test-late-row-drift", ...
        "ValidationMode", "fast");
    P = pdvar(init);

    testCase.verifyError(@() P == 0, "pdvar:InvalidEqualityRows");
end

function test_single_distinct_rate_vertex_derivative_equality(testCase)
    % A single distinct rate vertex remains a derivative equality row.
    P = pdvar(1, {[0 1]}, Degree=2, RateBounds=[2 2]);
    D = rhodiff(P);

    testCase.verifyEqual(D.NumRateRows, 1);
    testCase.verifySize(D.coeffs(1), [1 2]);
    testCase.verifyError(@() D == P, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() P == D, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() D == 0, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() 0 == D, "pdvar:InvalidEqualityRows");

    % Row-kind precedence is authoritative even when subtraction would first
    % reject another grid, degree, rate box, or matrix shape.
    ordinary = {
        pdvar(1, {[0 2]}, Degree=2, RateBounds=[2 2]), ...
        pdvar(1, {[0 1]}, Degree=1, RateBounds=[2 2]), ...
        pdvar(1, {[0 1]}, Degree=2, RateBounds=[-1 1]), ...
        pdvar(2, {[0 1]}, "full", Degree=2, RateBounds=[2 2]), ...
        [1 2]
    };
    for k = 1:numel(ordinary)
        Q = ordinary{k};
        testCase.verifyError(@() D == Q, "pdvar:InvalidEqualityRows");
        testCase.verifyError(@() Q == D, "pdvar:InvalidEqualityRows");
    end
end

function test_once_both_sides_derivative_rows_algebra(testCase)
    % Once both sides are derivative rows, algebra retains its established IDs.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    differentGrid = pdvar(1, {[0 2]}, RateBounds=[-1 1]);
    differentRate = pdvar(1, {[0 1]}, RateBounds=[0 1]);

    testCase.verifyError(@() rhodiff(P) == rhodiff(differentGrid), ...
        "pdvar:MixedGrid");
    testCase.verifyError(@() rhodiff(P) == rhodiff(differentRate), ...
        "pdvar:InvalidSubtraction");
end
