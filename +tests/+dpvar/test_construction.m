function tests = test_construction
    %TEST_CONSTRUCTION dpvar constructor shape, storage, and validation.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function testSdpvarSizeConvention(testCase)
    % Square forms follow sdpvar's symmetric default; rectangular is full.
    Ps = dpvar(2, {[0 1]});
    Pss = dpvar(2, 2, {[0 1]});
    Pf = dpvar(2, 3, {[0 1]});

    testCase.verifyEqual(size(Ps), [2 2]);
    testCase.verifyEqual(size(Pss), [2 2]);
    testCase.verifyEqual(size(Pf), [2 3]);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Ps))), 3);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Pss))), 3);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Pf))), 6);
end

function testExplicitStructureFlags(testCase)
    % Explicit flags let square matrices choose full or symmetric payloads.
    Pf = dpvar(2, 2, {[0 1]}, "full");
    Ps = dpvar(2, 2, {[0 1]}, "symmetric");

    testCase.verifyEqual(numel(getvariables(firstCoeff(Pf))), 4);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Ps))), 3);
    testCase.verifyError(@() dpvar(2, 3, {[0 1]}, "symmetric"), ...
        "dpvar:InvalidStructure");
end

function testDefaultDegreeOne(testCase)
    % The public constructor keeps the original degree-one default.
    P = dpvar(2, {[0 1 2]});
    Q = dpvar(2, {[0 1 2]}, Degree=1);

    testCase.verifyEqual(P.Degree, 1);
    testCase.verifyEqual(Q.Degree, 1);
    testCase.verifyTrue(P.IsContinuous);
    testCase.verifyTrue(P.ContainsDecision);
    testCase.verifyEqual(P.SourceSummary, "decision");
end

function testDegreeZeroSharesOneDecisionAcrossGrid(testCase)
    % Degree-zero variables are parameter-independent on the stored grid.
    P = dpvar(1, {[0 1 2 3]}, Degree=0);
    c1 = P.coeffs(1);
    c2 = P.coeffs(2);
    c3 = P.coeffs(3);

    testCase.verifyEqual(P.Degree, 0);
    testCase.verifyEqual(numel(c1), 1);
    verifySameVars(testCase, c1{1}, c2{1});
    verifySameVars(testCase, c1{1}, c3{1});
end

function testScalarGridVectorShorthand(testCase)
    % A plain numeric vector is accepted as the one-parameter grid.
    P = dpvar(2, [0 1], Degree=0);

    testCase.verifyEqual(P.Degree, 0);
    testCase.verifyEqual(P.GridInfo.Vectors, {[0 1]});
    testCase.verifyEqual(P.npar(), 1);
end

function testDegreeValidation(testCase)
    % Only the implemented constructor degrees are accepted publicly.
    testCase.verifyError(@() dpvar(2, {[0 1]}, Degree=2), ...
        "dpvar:InvalidDegree");
    testCase.verifyError(@() dpvar(2, {[0 1]}, Degree=-1), ...
        "dpvar:InvalidDegree");
end

function testBoundarySharing(testCase)
    % Adjacent scalar cells share the same boundary coefficient handle.
    P = dpvar(1, {[0 1 2]});
    left = P.coeffs(1);
    right = P.coeffs(2);

    verifySameVars(testCase, left{2}, right{1});
end

function testTensorCoefficientOrdering(testCase)
    % Tensor labels use combRows order: [0 0], [0 1], [1 0], [1 1].
    P = dpvar(1, {[0 1 2], [10 20]});
    c11 = P.coeffs([1 1]);
    c21 = P.coeffs([2 1]);

    testCase.verifyEqual(numel(c11), 4);
    verifySameVars(testCase, c11{3}, c21{1});
    verifySameVars(testCase, c11{4}, c21{2});
end

function testRateBounds(testCase)
    % Constructor RateBounds remain metadata outside LocalValues.
    rb = [-1 2; -3 4];
    P = dpvar(1, {[0 1], [10 20]}, RateBounds=rb);

    testCase.verifyTrue(P.HasRateDependence);
    testCase.verifyEqual(P.RateBounds, rb);
    testCase.verifyError(@() dpvar(1, {[0 1]}, RateBounds=[0 1; -1 1]), ...
        "dpbase:InvalidRateBounds");
    testCase.verifyError(@() dpvar(1, {[0 1]}, RateBounds=[1 -1]), ...
        "dpbase:InvalidRateBounds");
end

function verifySameVars(testCase, lhs, rhs)
    % Shared coefficient handles should expose identical YALMIP variable IDs.
    testCase.verifyEqual(getvariables(lhs), getvariables(rhs));
end

function val = firstCoeff(obj)
    % Pull the first scalar-cell coefficient for compact constructor checks.
    coeffs = obj.coeffs(1);
    val = coeffs{1};
end
