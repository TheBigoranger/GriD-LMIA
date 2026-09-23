function tests = test_continuity
    % Direction-wise continuity propagation through pdvar algebra.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    yalmip("clear");
end

function test_binary_concatenation_assignment_and_constant_minima(testCase)
    grid = {[0 1 3]};
    low = pdvar(1, grid, Degree=3, Continuity=1);
    high = pdvar(1, grid, Degree=3, Continuity=2);
    known = pdmat(grid, {{0,1,3,6},{6,12,22,40}}, ...
        Degree=3, Continuity=2);

    plusResult = low + high;
    minusResult = high - low;
    product = low * known;
    stacked = [low; high];
    blocked = blkdiag(low, high);
    assigned = pdvar(2, grid, "full", Degree=3, Continuity=2);
    assigned(1, 1) = low;

    for result = {plusResult, minusResult, product, stacked, blocked, assigned}
        testCase.verifyEqual(result{1}.Continuity, 1);
    end
    shifted = low + 3;
    testCase.verifyEqual(shifted.Continuity, 1);
    tests.infrastructure.verify_expr(testCase, plusResult.coeffs(1), ...
        cellfun(@plus, low.coeffs(1), high.coeffs(1), UniformOutput=false));
end

function test_unary_structural_elevation_refinement_zero_and_recovery(testCase)
    coarseGrid = {[0 1 3]};
    fineGrid = {[0 0.5 1 2 3]};
    coarse = pdvar(2, coarseGrid, "full", Degree=3, Continuity=2);
    fine = pdvar(2, fineGrid, "full", Degree=3, Continuity=2);

    negated = -coarse;
    transposed = coarse.';
    reduced = sum(coarse, 1);
    elevated = elevate(coarse, 1);
    testCase.verifyEqual(negated.Continuity, 2);
    testCase.verifyEqual(transposed.Continuity, 2);
    testCase.verifyEqual(reduced.Continuity, 2);
    testCase.verifyEqual(elevated.Continuity, 2);
    refined = coarse + fine;
    testCase.verifyEqual(refined.Continuity, 2);
    testCase.verifyEqual(refined.GridInfo.Vectors, fineGrid);
    % Check the represented affine matrices after refinement/elevation; their
    % continuity metadata alone cannot expose a tensor or restriction defect.
    for rho = [0 .17 .5 .83 1 1.37 2 2.81 3]
        expected = evaluate(coarse,rho);
        tests.infrastructure.verify_expr(testCase,evaluate(negated,rho),-expected);
        tests.infrastructure.verify_expr(testCase,evaluate(transposed,rho),expected.');
        tests.infrastructure.verify_expr(testCase,evaluate(reduced,rho),sum(expected,1));
        tests.infrastructure.verify_expr(testCase,evaluate(elevated,rho),expected);
        tests.infrastructure.verify_expr(testCase,evaluate(refined,rho), ...
            expected+evaluate(fine,rho));
    end

    c0 = pdvar(1, [0 1 2], Degree=1);
    derivative = rhodiff(c0, [1 1]);
    testCase.verifyEqual(derivative.Continuity, -1);
    recovered = derivative - derivative;
    testCase.verifyEqual(recovered.Continuity, Inf);
    testCase.verifyTrue(helper.isZero(recovered.LocalValues, "vals"));
end
