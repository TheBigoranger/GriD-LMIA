function tests = test_evaluate
    %TEST_EVALUATE Numeric evaluation of known dpmat data.
    tests = functiontests(localfunctions);
end

function testScalarCoefficientInterpolation(testCase)
    % Scalar coefficient-backed data should evaluate by Bernstein interpolation.
    A = dpmat({[0 1]}, {2, 4}, Degree=1);

    testCase.verifyEqual(evaluate(A, 0.25), 2.5, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(0.75), 3.5, AbsTol=1e-12);
end

function testTensorCoefficientInterpolation(testCase)
    % Tensor coefficient-backed data should interpolate across both dimensions.
    A = dpmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=1);

    val = A.evaluate([0.25, 12.5]);

    testCase.verifyEqual(val, 2.5, AbsTol=1e-12);
end

function testFunctionBackedUsesExactHandle(testCase)
    % Function-backed dpmat should evaluate through the retained exact handle.
    A = dpmat({[0 pi]}, @(rho) sin(rho));

    testCase.verifyEqual(A.evaluate(pi / 2), 1, AbsTol=1e-12);
end

function testFunctionBernsteinStillUsesHandle(testCase)
    % Function-Bernstein objects should evaluate through the original handle.
    A = dpmat({[0 1]}, @(rho) rho.^2, Degree=2);

    testCase.verifyEqual(A.evaluate(0.5), 0.25, AbsTol=1e-12);
end

function testRejectsBadPoints(testCase)
    % Evaluation should reject out-of-bounds and wrong-dimensional points.
    A = dpmat({[0 1]}, {2, 4}, Degree=1);

    testCase.verifyError(@() A.evaluate(-0.1), "dpmat:PointOutOfBounds");
    testCase.verifyError(@() A.evaluate([0.5 0.5]), "dpmat:InvalidPoint");
end

function testContinuousBoundaryUsesRightCell(testCase)
    % Boundary evaluation should choose a valid continuous cell value.
    A = dpmat({[0 1 2]}, {1, 2, 3}, Degree=1);

    testCase.verifyEqual(A.evaluate(1), 2, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(2), 3, AbsTol=1e-12);
end
