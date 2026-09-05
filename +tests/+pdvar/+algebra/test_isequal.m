function tests = test_isequal
    % Public pdvar.isequal behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_later_cell_and_last_entry_change_is_detected(testCase)
    % Equality traverses the whole expression rather than a sampled first leaf.
    grid = {[0 2 5],[-3 1 6]};
    P = pdvar(2,3,grid,'full',Degree=[1 2])+[2 3 5;7 11 13];
    Q = P;
    testCase.verifyTrue(isequal(P,Q,P));
    zero = {0,0,0,0,0,0};
    data = {{zero,zero},{zero,{0,0,0,0,0,15}}};
    bump = pdmat(grid,data,Degree=[1 2]);
    Q(2,3) = Q(2,3)+bump;
    % The first three leaves and all metadata match, so only the last leaf can decide.
    for subs = [1 1;1 2;2 1]'
        testCase.verifyEqual(P.coeffs(subs'),Q.coeffs(subs'));
    end
    testCase.verifyEqual(Q.SourceSummary,P.SourceSummary);
    testCase.verifyEqual(Q.Degree,P.Degree);
    testCase.verifyEqual(Q.GridInfo,P.GridInfo);
    testCase.verifyEqual(Q.IsContinuous,P.IsContinuous);
    p = P.coeffs([2 2]); q = Q.coeffs([2 2]);
    testCase.verifyEqual(p(1:5),q(1:5));
    tests.infrastructure.verify_expr(testCase,q{end}-p{end},[0 0 0;0 0 15]);
    testCase.verifyFalse(isequal(P,Q));
    testCase.verifyFalse(isequal(Q,P));
    testCase.verifyFalse(isequal(P,7));
end

function test_equal_polynomial_different_representation_is_not_identity(testCase)
    % isequal is representation identity, unlike an affine equality constraint.
    P = pdvar(1,[0 2 5],Degree=2);
    Q = elevate(P,1);
    testCase.verifyFalse(isequal(P,Q));
    for point = [0 .7 2 4.2 5]
        tests.infrastructure.verify_expr(testCase,P.evaluate(point),Q.evaluate(point));
    end
    testCase.verifyTrue(isequal(P));
end

function test_same_values_do_not_merge_decision_identity(testCase)
    P=pdvar(1,[0 2 5]); Q=pdvar(1,[0 2 5]);
    p=P.coeffs(1); q=Q.coeffs(1);
    assign([p{:} q{:}], [2 3 2 3]);
    testCase.verifyTrue(isequal(P,P));
    testCase.verifyFalse(isequal(P,Q));
    tests.infrastructure.verify_expr(testCase,P.coeffs(1),p);
end
