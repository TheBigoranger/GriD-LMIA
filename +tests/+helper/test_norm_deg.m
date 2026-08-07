function tests = test_norm_deg
    %TEST_NORM_DEG Shared scalar and direction-wise degree contract.
    tests = functiontests(localfunctions);
end

function testScaExpAndVecNor(testCase)
    % Scalars expand uniformly and vector orientation is not public state.
    testCase.verifyEqual( ...
        helper.normDeg(2, 3, "test:InvalidDegree", "Degree"), ...
        [2 2 2]);
    testCase.verifyEqual( ...
        helper.normDeg([0; 2; 1], 3, ...
        "test:InvalidDegree", "Degree"), [0 2 1]);
    testCase.verifyEqual( ...
        helper.normDeg([3 1 0], 3, ...
        "test:InvalidDegree", "Degree"), [3 1 0]);
    testCase.verifyEqual(helper.normDeg(1, 2, ...
        "test:InvalidDegree"), [1 1]);
end

function testGriDefOwn(testCase)
    % The standalone grid helper defaults to pdbase-owned diagnostics.
    info = helper.mkGrid({[0 1], [10 20]});

    testCase.verifyEqual(info.NumNodes, [2 2]);
    testCase.verifyError(@() helper.mkGrid({[0 0]}), ...
        "pdbase:InvalidGridVector");
end

function testInvInpPreCalErr(testCase)
    % Reject every shape and value outside scalar-or-ell-vector degrees.
    bad = {[], [1 2], [1 2; 3 4], -1, 0.5, Inf, NaN, 1i, ...
        "one", true};
    for k = 1:numel(bad)
        testCase.verifyError(@() helper.normDeg( ...
            bad{k}, 3, "test:InvalidDegree", "Degree"), ...
            "test:InvalidDegree");
    end
end
