function tests = test_construction
    %TEST_CONSTRUCTION pdvar constructor shape, storage, and validation.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function testSdpSizCon(testCase)
    % Square forms follow sdpvar's symmetric default; rectangular is full.
    Ps = pdvar(2, {[0 1]});
    Pss = pdvar(2, 2, {[0 1]});
    Pf = pdvar(2, 3, {[0 1]});

    testCase.verifyEqual(size(Ps), [2 2]);
    testCase.verifyEqual(size(Pss), [2 2]);
    testCase.verifyEqual(size(Pf), [2 3]);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Ps))), 3);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Pss))), 3);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Pf))), 6);
end

function testExpStrFla(testCase)
    % Explicit flags let square matrices choose full or symmetric payloads.
    Pf = pdvar(2, 2, {[0 1]}, "full");
    Ps = pdvar(2, 2, {[0 1]}, "symmetric");

    testCase.verifyEqual(numel(getvariables(firstCoeff(Pf))), 4);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Ps))), 3);
    testCase.verifyError(@() pdvar(2, 3, {[0 1]}, "symmetric"), ...
        "pdvar:InvalidStructure");
end

function testDefaultDegreeOne(testCase)
    % The public constructor keeps the original degree-one default.
    P = pdvar(2, {[0 1 2]});
    Q = pdvar(2, {[0 1 2]}, Degree=1);

    testCase.verifyEqual(P.Degree, 1);
    testCase.verifyEqual(Q.Degree, 1);
    testCase.verifyTrue(P.IsContinuous);
    testCase.verifyTrue(P.ContainsDecision);
    testCase.verifyEqual(P.SourceSummary, "decision");
end

function testDegZerShaOneDec(testCase)
    % Degree-zero variables are parameter-independent on the stored grid.
    P = pdvar(1, {[0 1 2 3]}, Degree=0);
    c1 = P.coeffs(1);
    c2 = P.coeffs(2);
    c3 = P.coeffs(3);

    testCase.verifyEqual(P.Degree, 0);
    testCase.verifyEqual(numel(c1), 1);
    verifySameVars(testCase, c1{1}, c2{1});
    verifySameVars(testCase, c1{1}, c3{1});
end

function testArbScaDeg(testCase)
    % Constructor-created decisions support every nonnegative scalar degree.
    P2 = pdvar(1, {[0 1]}, Degree=2);
    P4 = pdvar(1, {[0 1]}, Degree=4);

    testCase.verifyEqual(P2.Degree, 2);
    testCase.verifyEqual(P2.ncoeff(), 3);
    testCase.verifyEqual(numel(P2.coeffs(1)), 3);
    testCase.verifyEqual(P4.Degree, 4);
    testCase.verifyEqual(P4.ncoeff(), 5);
    testCase.verifyEqual(numel(P4.coeffs(1)), 5);
end

function testScaGriVecSho(testCase)
    % A plain numeric vector is accepted as the one-parameter grid.
    P = pdvar(2, [0 1], Degree=0);

    testCase.verifyEqual(P.Degree, 0);
    testCase.verifyEqual(P.GridInfo.Vectors, {[0 1]});
    testCase.verifyEqual(P.npar(), 1);
end

function testDegreeValidation(testCase)
    % Degree accepts ell-vectors and reports owner-specific shape failures.
    grid = {[0 1], [10 20]};
    row = pdvar(1, grid, Degree=[0 2]);
    column = pdvar(1, grid, Degree=[0; 2]);
    testCase.verifyEqual(row.Degree, [0 2]);
    testCase.verifyEqual(column.Degree, [0 2]);

    bad = {[], [1 2 3], [1 2; 3 4], -1, 1.5, NaN, Inf, "two"};
    for k = 1:numel(bad)
        testCase.verifyError(@() pdvar(2, grid, Degree=bad{k}), ...
            "pdvar:InvalidDegree");
    end

    try
        pdvar(2, grid, Degree=[1 2 3]);
        error("tests:ExpectedError", "The invalid degree did not fail.");
    catch err
    end
    testCase.verifyEqual(string(err.identifier), "pdvar:InvalidDegree");
    testCase.verifyEqual(string(err.message), ...
        "Degree must be a finite nonnegative integer scalar or an ell-element vector.");
end

function testScaDegWarAndSil(testCase)
    % Explicit multidimensional scalar shorthand warns; defaults and 1-D do not.
    grid = {[0 1], [10 20]};
    explicit = constructWithWarning(testCase, ...
        @() pdvar(1, grid, Degree=1), ...
        "pdvar:ScalarDegreeExpansion");
    default = constructWarningFree(testCase, @() pdvar(1, grid));
    oneDimensional = constructWarningFree(testCase, ...
        @() pdvar(1, [0 1], Degree=1));

    testCase.verifyEqual(explicit.Degree, [1 1]);
    testCase.verifyEqual(default.Degree, [1 1]);
    testCase.verifyEqual(oneDimensional.Degree, 1);
end

function testBoundarySharing(testCase)
    % Adjacent scalar cells share the same boundary coefficient handle.
    P = pdvar(1, {[0 1 2]});
    left = P.coeffs(1);
    right = P.coeffs(2);

    verifySameVars(testCase, left{2}, right{1});
end

function testScaDegTwoUseFiv(testCase)
    % Two quadratic cells share only their common endpoint control handle.
    P = pdvar(1, {[0 1 2]}, Degree=2);
    left = P.coeffs(1);
    right = P.coeffs(2);
    leftIds = cellfun(@getvariables, left);
    rightIds = cellfun(@getvariables, right);

    testCase.verifyEqual(numel(left), 3);
    testCase.verifyEqual(numel(right), 3);
    testCase.verifyEqual(numel(unique(leftIds)), 3);
    testCase.verifyEqual(numel(unique(rightIds)), 3);
    testCase.verifyEqual(numel(unique([leftIds rightIds])), 5);
    verifySameVars(testCase, left{3}, right{1});
    testCase.verifyEmpty(intersect(leftIds(1:2), rightIds(2:3)));
end

function testTenCoeOrd(testCase)
    % Tensor labels use combRows order: [0 0], [0 1], [1 0], [1 1].
    P = pdvar(1, {[0 1 2], [10 20]});
    c11 = P.coeffs([1 1]);
    c21 = P.coeffs([2 1]);

    testCase.verifyEqual(numel(c11), 4);
    verifySameVars(testCase, c11{3}, c21{1});
    verifySameVars(testCase, c11{4}, c21{2});
end

function testTenDegTwoShaCom(testCase)
    % Adjacent quadratic tensor cells reuse every control on their full face.
    P = pdvar(1, {[0 1 2], [10 20 30]}, Degree=[2 2]);
    c11 = P.coeffs([1 1]);
    c21 = P.coeffs([2 1]);
    c12 = P.coeffs([1 2]);
    lbls = helper.combRows({0:2, 0:2});

    testCase.verifyEqual(P.ncoeff(), 9);
    testCase.verifyEqual(numel(c11), 9);
    for q = 0:2
        verifySameVars(testCase, c11{labelIndex(lbls, [2 q])}, ...
            c21{labelIndex(lbls, [0 q])});
        verifySameVars(testCase, c11{labelIndex(lbls, [q 2])}, ...
            c12{labelIndex(lbls, [q 0])});
    end

    center = getvariables(c11{labelIndex(lbls, [1 1])});
    testCase.verifyNotEqual(center, getvariables(c21{labelIndex(lbls, [1 1])}));
    testCase.verifyNotEqual(center, getvariables(c12{labelIndex(lbls, [1 1])}));
end

function testParConAxiUseExp(testCase)
    % Degree [0 2] shares the complete constant axis and quadratic faces.
    P = pdvar(1, {[0 1 2], [10 20 30]}, Degree=[0 2]);
    c11 = P.coeffs([1 1]);
    c21 = P.coeffs([2 1]);
    c12 = P.coeffs([1 2]);
    c22 = P.coeffs([2 2]);

    testCase.verifyEqual(P.Degree, [0 2]);
    testCase.verifyEqual(P.ncoeff(), 3);
    for k = 1:3
        verifySameVars(testCase, c11{k}, c21{k});
        verifySameVars(testCase, c12{k}, c22{k});
    end
    verifySameVars(testCase, c11{3}, c12{1});

    vars = cellfun(@getvariables, [c11, c21, c12, c22]);
    testCase.verifyEqual(numel(unique(vars)), 5);
end

function testRateBounds(testCase)
    % Constructor RateBounds remain metadata outside LocalValues.
    rb = [-1 2; -3 4];
    P = pdvar(1, {[0 1], [10 20]}, RateBounds=rb);

    testCase.verifyEqual(P.RateBounds, rb);
    testCase.verifyError(@() pdvar(1, {[0 1]}, RateBounds=[0 1; -1 1]), ...
        "pdbase:InvalidRateBounds");
    testCase.verifyError(@() pdvar(1, {[0 1]}, RateBounds=[1 -1]), ...
        "pdbase:InvalidRateBounds");
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

function idx = labelIndex(lbls, label)
    % Locate one tensor Bernstein label in the package-wide combRows order.
    idx = find(all(lbls == label, 2), 1);
end

function testConInpAndOptParBou(testCase)
    % Public parsing rejects missing grids and malformed option sequences.
    testCase.verifyError(@() pdvar(1), "pdvar:InvalidInput");
    testCase.verifyError(@() pdvar(1, 2), "pdvar:InvalidInput");
    testCase.verifyError(@() pdvar(1, 2, 3), "pdvar:InvalidInput");
    testCase.verifyError(@() pdvar(1, [0 1], 7), ...
        "pdvar:InvalidOptions");
    testCase.verifyError(@() pdvar(1, [0 1], "Degree"), ...
        "pdvar:InvalidOptions");
    testCase.verifyError(@() pdvar(1, [0 1], ...
        "ValidationMode", "fast", "ValidationMode", "strict"), ...
        "pdvar:InvalidValidationMode");
    testCase.verifyError(@() pdvar(1, [0 1], ...
        "IsContinuous", true), "pdvar:UnsupportedOption");
    testCase.verifyError(@() pdvar(1, [0 1], "Unknown", 1), ...
        "pdvar:UnknownOption");
end

function obj = constructWithWarning(testCase, fcn, warningId)
    % Capture the public scalar-expansion warning and retain the result.
    obj = [];
    testCase.verifyWarning(@construct, warningId);

    function construct
        obj = fcn();
    end
end

function obj = constructWarningFree(testCase, fcn)
    % Defaults and one-dimensional shorthand must remain warning-free.
    obj = [];
    testCase.verifyWarningFree(@construct);

    function construct
        obj = fcn();
    end
end
