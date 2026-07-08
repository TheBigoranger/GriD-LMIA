function tests = test_construction
    %TEST_CONSTRUCTION Constructor defaults and public property contracts.
    tests = functiontests(localfunctions);
end

function testScalarDefaults(testCase)
    % Scalar construction should populate default coefficient-backed state.
    obj = dpbase({[0 1 3]}, [2 3], 1);

    testCase.verifyEqual(obj.MatrixSize, [2 3]);
    testCase.verifyEqual(obj.Degree, 1);
    testCase.verifyFalse(obj.IsContinuous);
    testCase.verifyFalse(obj.ContainsDecision);
    testCase.verifyFalse(obj.HasRateDependence);
    testCase.verifyEmpty(obj.RateBounds);

    % Default objects are coefficient-backed zeros, not sampled grid data.
    testCase.verifyEqual(obj.SourceSummary, "coefficient-backed");
    testCase.verifyEqual(obj.npar(), 1);
    testCase.verifyEqual(obj.ncell(), 2);
    testCase.verifyEqual(obj.ncoeff(), 2);
    testCase.verifyEqual(size(obj), [2 3]);
    testCase.verifyEqual(size(obj, 1), 2);
    testCase.verifyEqual(size(obj, 3), 1);
end

function testTensorOptions(testCase)
    % Tensor construction should preserve explicit flags and rate bounds.
    obj = dpbase({[0 1 2], [10 20]}, [1 1], 2, [], ...
        IsContinuous=true, ContainsDecision=true, ...
        RateBounds=[-1 1; -2 2], SourceSummary="test-coefficients");

    testCase.verifyEqual(obj.GridInfo.NumNodes, [3 2]);
    testCase.verifyTrue(obj.IsContinuous);
    testCase.verifyTrue(obj.ContainsDecision);
    testCase.verifyTrue(obj.HasRateDependence);
    testCase.verifyEqual(obj.RateBounds, [-1 1; -2 2]);
    testCase.verifyEqual(obj.SourceSummary, "test-coefficients");
    testCase.verifyEqual(obj.npar(), 2);
    testCase.verifyEqual(obj.ncell(), 2);
    testCase.verifyEqual(obj.ncoeff(), 9);
end

function testReadOnlyProps(testCase)
    % Public state properties should be inspectable but not mutable.
    obj = dpbase({[0 1]}, [1 1], 0);

    testCase.verifyError(@() setSummary(obj), "MATLAB:class:SetProhibited");
    testCase.verifyError(@() setDeg(obj), "MATLAB:class:SetProhibited");
end

function setSummary(obj)
    % Local setter helper should trigger the read-only property guard.
    obj.SourceSummary = "manual";
end

function setDeg(obj)
    % Local setter helper should exercise the Degree immutability path.
    obj.Degree = 3;
end
