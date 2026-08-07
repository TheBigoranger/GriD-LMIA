function tests = test_construction
    %TEST_CONSTRUCTION Constructor defaults and public property contracts.
    tests = functiontests(localfunctions);
end

function testScalarDefaults(testCase)
    % Scalar construction should populate default coefficient-backed state.
    obj = pdbase({[0 1 3]}, [2 3], 1);

    testCase.verifyEqual(obj.MatrixSize, [2 3]);
    testCase.verifyEqual(obj.Degree, 1);
    testCase.verifyFalse(obj.IsContinuous);
    testCase.verifyFalse(obj.ContainsDecision);
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

function testShaMatPro(testCase)
    % Shared matrix protocol methods should report the stored payload shape.
    obj = pdbase({[0 1]}, [2 3], 0);

    testCase.verifyEqual(height(obj), 2);
    testCase.verifyEqual(width(obj), 3);
    testCase.verifyEqual(length(obj), 3);
    testCase.verifyEqual(numel(obj), 6);
    testCase.verifyEqual(ndims(obj), 2);
    testCase.verifyEqual(+obj, obj);
    testCase.verifyEqual(squeeze(obj), obj);

    [m, n, trailing] = size(obj);
    testCase.verifyEqual([m n trailing], [2 3 1]);
    testCase.verifyEqual(numel(obj, 1), 1);
end

function testDirBasConIsRej(testCase)
    % Direct pdbase operands must not create ambiguous MATLAB object arrays.
    obj = pdbase({[0 1]}, [1 1], 0);
    known = pdmat({[0 1]}, {1, 2}, Degree=1);

    testCase.verifyError(@() horzcat(obj, obj), ...
        "pdbase:UnsupportedConcatenation");
    testCase.verifyError(@() vertcat(obj, obj), ...
        "pdbase:UnsupportedConcatenation");
    testCase.verifyError(@() cat(1, obj, obj), ...
        "pdbase:UnsupportedConcatenation");
    testCase.verifyError(@() cat(2, obj, obj), ...
        "pdbase:UnsupportedConcatenation");
    testCase.verifyError(@() horzcat(obj, known), ...
        "pdbase:UnsupportedConcatenation");
    testCase.verifyError(@() horzcat(known, obj), ...
        "pdbase:UnsupportedConcatenation");
end

function testTensorOptions(testCase)
    % Tensor construction should preserve explicit flags and rate bounds.
    obj = pdbase({[0 1 2], [10 20]}, [1 1], 2, [], ...
        IsContinuous=true, ContainsDecision=true, ...
        RateBounds=[-1 1; -2 2], SourceSummary="test-coefficients");

    testCase.verifyEqual(obj.GridInfo.NumNodes, [3 2]);
    testCase.verifyTrue(obj.IsContinuous);
    testCase.verifyTrue(obj.ContainsDecision);
    testCase.verifyEqual(obj.RateBounds, [-1 1; -2 2]);
    testCase.verifyEqual(obj.SourceSummary, "test-coefficients");
    testCase.verifyEqual(obj.npar(), 2);
    testCase.verifyEqual(obj.ncell(), 2);
    testCase.verifyEqual(obj.ncoeff(), 9);
end

function testOptionsWithoutLocalValues(testCase)
    % Named metadata may omit the optional LocalValues position.
    obj = pdbase({[0 1]}, [1 1], 0, ...
        IsContinuous=1, ContainsDecision=true, SourceSummary="option-parser");

    testCase.verifyTrue(obj.IsContinuous);
    testCase.verifyTrue(obj.ContainsDecision);
    testCase.verifyEqual(obj.SourceSummary, "option-parser");
end

function testRateStateUsesBoundsOnly(testCase)
    % RateBounds should be the only stored rate-metadata state.
    ordinary = pdbase({[0 1]}, [1 1], 0);
    bounded = pdbase({[0 1]}, [1 1], 0, [], RateBounds=[-1 1]);

    testCase.verifyFalse(isprop(ordinary, "HasRateDependence"));
    testCase.verifyEmpty(ordinary.RateBounds);
    testCase.verifyEqual(bounded.RateBounds, [-1 1]);
end

function testNumRatRowMetVal(testCase)
    % Explicit internal row counts require matching distinct rate vertices.
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], ...
        NumRateRows=1), "pdbase:InvalidRateBounds");
    testCase.verifyError(@() pdbase({[0 1]}, [1 1], 0, [], ...
        RateBounds=[-1 1], NumRateRows=1), ...
        "pdbase:InvalidRateBounds");
end


function testReadOnlyProps(testCase)
    % Public state properties should be inspectable but not mutable.
    obj = pdbase({[0 1]}, [1 1], 0);

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
