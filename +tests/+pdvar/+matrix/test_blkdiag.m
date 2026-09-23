function tests = test_blkdiag
    % Behavioral regressions for pdvar.blkdiag.
    tests = functiontests(localfunctions);
end

function test_tensor_mixed_rate_rectangular_blocks(testCase)
    % Rectangular block placement and numeric padding expose off-diagonal drift.
    tests.infrastructure.verify_tensor_transform(testCase,"pdvar", ...
        @(x) blkdiag([2 -3],x,[5;7]),"mixed");
end

function test_function_only_and_nonlinear_blocks_are_rejected(testCase)
    % Invalid trailing blocks must not bypass validation after valid leading data.
    P = pdvar(1,[0 2 5],Degree=2);
    F = pdmat([0 2 5],@(r) r);
    x = sdpvar(1);
    testCase.verifyError(@() blkdiag(P,2,F),'pdvar:FunctionOnlyAlgebra');
    testCase.verifyError(@() blkdiag(P,2,x*x),'pdvar:InvalidBlkdiag');
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function test_blkdiag_align_grids_elevate_degree_accept(testCase)
    % blkdiag should align grids, elevate degree, and accept numeric blocks.
    P = pdvar(1, {[0 1]});
    B = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    cp = P.coeffs(1);
    pMid = 0.5 * cp{1} + 0.5 * cp{2};

    C = blkdiag(P, 5, B);

    testCase.verifyEqual(size(C), [3 3]);
    testCase.verifyEqual(C.GridInfo.Vectors{1}, [0 0.5 1]);
    tests.infrastructure.verify_expr(testCase, C.coeffs(1), { ...
        diag([cp{1}, 5, 10]), ...
        diag([pMid, 5, 20])});
    tests.infrastructure.verify_expr(testCase, C.coeffs(2), { ...
        diag([pMid, 5, 20]), ...
        diag([cp{2}, 5, 30])});
end

function test_blkdiag_preserve_derivative_rate_rows_broadcast(testCase)
    % blkdiag should preserve derivative rate rows and broadcast ordinary rows.
    P = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cp = P.coeffs(1);
    cd = D.coeffs(1);

    B = blkdiag(D, P);
    cb = B.coeffs(1);

    testCase.verifyEqual(size(B), [2 2]);
    testCase.verifyEqual(B.Degree, 1);
    testCase.verifyEqual(B.Continuity, Inf);
    testCase.verifyTrue(B.IsContinuous);
    testCase.verifyEqual(size(cb), [2 2]);
    tests.infrastructure.verify_expr(testCase, cb(1, :), {blkdiag(cd{1, 1}, cp{1}), blkdiag(cd{1, 1}, cp{2})});
    tests.infrastructure.verify_expr(testCase, cb(2, :), {blkdiag(cd{2, 1}, cp{1}), blkdiag(cd{2, 1}, cp{2})});
end
