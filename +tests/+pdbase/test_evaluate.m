function tests = test_evaluate
    %TEST_EVALUATE Point evaluation through the shared pdbase contract.
    tests = functiontests(localfunctions);
end

function testOrdinaryCoefficientInterpolation(testCase)
    % One stored coefficient row should reconstruct one matrix value.
    obj = pdbase({[0 2]}, [1 1], 2, {{1, 3, 9}});

    val = obj.evaluate(1);

    testCase.verifyEqual(val, 4, AbsTol=1e-12);
end

function testRateRowsEvaluateIndependently(testCase)
    % Multiple stored rows should remain a row cell array in storage order.
    vals = {{1, 3; 10, 14}};
    obj = pdbase({[0 2]}, [1 1], 1, vals, ...
        HasRateDependence=true, RateBounds=[-1 1]);

    rows = obj.evaluate(0.5);

    testCase.verifySize(rows, [1 2]);
    testCase.verifyEqual(rows{1}, 1.5, AbsTol=1e-12);
    testCase.verifyEqual(rows{2}, 11, AbsTol=1e-12);
end

function testRejectsBadPointsWithBaseErrors(testCase)
    % Direct pdbase calls should own malformed and out-of-domain errors.
    obj = pdbase({[0 1], [10 20]}, [1 1], 1);

    testCase.verifyError(@() obj.evaluate(0.5), "pdbase:InvalidPoint");
    testCase.verifyError(@() obj.evaluate([-0.1 12]), ...
        "pdbase:PointOutOfBounds");
end
