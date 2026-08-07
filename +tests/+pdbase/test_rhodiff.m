function tests = test_rhodiff
    %TEST_RHODIFF Shared inherited derivative behavior at the parent boundary.
    tests = functiontests(localfunctions);
end

function testScaStoBouAndDyn(testCase)
    % The parent implementation should retain the dynamic class and row order.
    A = pdbase({[0 2]}, [1 1], 1, {{1, 5}}, ...
        RateBounds=[-2 3], IsContinuous=true);

    D = rhodiff(A);

    testCase.verifyClass(D, "pdbase");
    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(D.coeffs(1), {-4; 6});
    veriDerSta(testCase, D, [-2 3]);
end

function testTenRatVerOrd(testCase)
    % A linear tensor polynomial has one constant partial per parameter.
    grid = {[0 2], [10 14]};
    rb = [-1 2; -3 5];
    leaf = {30, 42, 34, 46};
    A = pdbase(grid, [1 1], 1, {{leaf}}, RateBounds=rb);

    D = rhodiff(A);

    expected = repmat(num2cell([-11; 13; -5; 19]), 1, 4);
    testCase.verifyEqual(D.Degree, [1 1]);
    testCase.verifyEqual(D.coeffs([1 1]), expected);
    veriDerSta(testCase, D, rb);
end

function testDegZerAndExpBou(testCase)
    % Degree-zero input still produces a complete zero rate-vertex table.
    A = pdbase({[0 1]}, [2 2], 0, {{eye(2)}});

    D = rhodiff(A, [-1 2]);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(D.coeffs(1), {zeros(2); zeros(2)});
    testCase.verifyFalse(D.ContainsDecision);
    veriDerSta(testCase, D, [-1 2]);
end

function testFixBouGenOneRow(testCase)
    % A fixed scheduling rate is one vertex, not two duplicate endpoints.
    A = pdbase({[0 2]}, [1 1], 1, {{1, 5}}, ...
        RateBounds=[3 3], IsContinuous=true);

    D = rhodiff(A);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(D.coeffs(1), {6});
    veriDerSta(testCase, D, [3 3]);
end

function testFixTenDirRedVerCou(testCase)
    % Each fixed tensor direction removes one duplicate Cartesian endpoint.
    grid = {[0 2], [10 14]};
    rb = [1 1; -3 5];
    A = pdbase(grid, [1 1], [1 1], {{ {30, 42, 34, 46} }}, ...
        RateBounds=rb);

    D = rhodiff(A);

    expected = repmat(num2cell([-7; 17]), 1, 4);
    testCase.verifyEqual(D.coeffs([1 1]), expected);
    testCase.verifyEqual(D.NumRateRows, 2);
    veriDerSta(testCase, D, rb);
end

function testInvBouAndRepDer(testCase)
    % Missing, malformed, mismatched, and repeated derivative requests fail.
    ordinary = pdbase({[0 1]}, [1 1], 1, {{1, 2}});
    stored = pdbase({[0 1]}, [1 1], 1, {{1, 2}}, ...
        RateBounds=[-1 1]);
    D = rhodiff(stored);

    testCase.verifyError(@() rhodiff(ordinary), ...
        "pdbase:MissingRateBounds");
    testCase.verifyError(@() rhodiff(ordinary, [0 1; -1 1]), ...
        "pdbase:InvalidRateBounds");
    testCase.verifyError(@() rhodiff(stored, [0 1]), ...
        "pdbase:RateBoundsMismatch");
    testCase.verifyError(@() rhodiff(D), "pdbase:InvalidDiff");
end

function veriDerSta(testCase, D, rb)
    % Every inherited derivative is rate-dependent and cellwise discontinuous.
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifyEqual(D.RateBounds, rb);
    testCase.verifyEqual(D.SourceSummary, "derivative");
end
