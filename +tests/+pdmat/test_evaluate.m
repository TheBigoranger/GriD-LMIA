function tests = test_evaluate
    %TEST_EVALUATE Numeric evaluation of known pdmat data.
    tests = functiontests(localfunctions);
end

function testScalarCoefficientInterpolation(testCase)
    % Scalar coefficient-backed data should evaluate by Bernstein interpolation.
    A = pdmat({[0 1]}, {2, 4}, Degree=1);

    testCase.verifyEqual(evaluate(A, 0.25), 2.5, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(0.75), 3.5, AbsTol=1e-12);
end

function testTensorCoefficientInterpolation(testCase)
    % Tensor coefficient-backed data should interpolate across both dimensions.
    A = pdmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=1);

    val = A.evaluate([0.25, 12.5]);

    testCase.verifyEqual(val, 2.5, AbsTol=1e-12);
end

function testThreeDimensionalDegreeTwoInterpolation(testCase)
    % 3-D degree-2 data should evaluate with tensor Bernstein weights.
    data = cell(3, 3, 3);
    for i = 0:2
        for j = 0:2
            for k = 0:2
                data{i + 1, j + 1, k + 1} = i + 10 * j + 100 * k;
            end
        end
    end
    A = pdmat({[0 1], [0 1], [0 1]}, data, Degree=2);

    val = A.evaluate([0.25, 0.5, 0.75]);

    testCase.verifyEqual(val, 160.5, AbsTol=1e-12);
end

function testNonuniformQuadraticCellsUseForwardAlpha(testCase)
    % These controls represent rho^2 independently on two unequal cells.
    A = pdmat({[-2 0.5 4]}, {4, -1, 0.25, 2, 16}, Degree=2);

    testCase.verifyEqual(A.evaluate(-2), 4, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(-0.75), 0.75^2, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(0.5), 0.25, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(2.25), 2.25^2, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(4), 16, AbsTol=1e-12);
end

function testFunctionBackedUsesExactHandle(testCase)
    % Function-backed pdmat should evaluate through the retained exact handle.
    A = pdmat({[0 pi]}, @(rho) sin(rho));

    testCase.verifyEqual(A.evaluate(pi / 2), 1, AbsTol=1e-12);
end

function testFunctionBernsteinStillUsesHandle(testCase)
    % Function-Bernstein objects should evaluate through the original handle.
    A = pdmat({[0 1]}, @(rho) rho.^2, Degree=2);

    testCase.verifyEqual(A.evaluate(0.5), 0.25, AbsTol=1e-12);
end

function testFunctionBackedEvaluationValidatesBoundsAndPayload(testCase)
    % Exact handles still obey grid bounds and the stored matrix contract.
    bounded = pdmat({[0 1]}, @(rho) rho);
    throws = pdmat({[0 1]}, @(rho) failAwayFromLowerBound(rho));
    wrongSize = pdmat({[0 1]}, @(rho) changeSizeAwayFromLowerBound(rho));

    testCase.verifyError(@() bounded.evaluate(1.1), ...
        "pdmat:PointOutOfBounds");
    testCase.verifyError(@() throws.evaluate(0.5), ...
        "pdmat:InvalidFunctionValue");
    testCase.verifyError(@() wrongSize.evaluate(0.5), ...
        "pdmat:InvalidFunctionValue");
end

function testRejectsBadPoints(testCase)
    % Evaluation should reject out-of-bounds and wrong-dimensional points.
    A = pdmat({[0 1]}, {2, 4}, Degree=1);

    testCase.verifyError(@() A.evaluate(-0.1), "pdmat:PointOutOfBounds");
    testCase.verifyError(@() A.evaluate([0.5 0.5]), "pdmat:InvalidPoint");
end

function testBoundaryUsesRightCell(testCase)
    % Distinct face values make deterministic right-cell ownership observable.
    state = warning("query", "pdmat:DiscontinuousLocalValues");
    cleanup = onCleanup(@() warning(state.state, ...
        "pdmat:DiscontinuousLocalValues")); %#ok<NASGU>
    warning("off", "pdmat:DiscontinuousLocalValues");
    A = pdmat({[0 1 2]}, {{1, 2}, {20, 3}}, Degree=1);

    testCase.verifyEqual(A.evaluate(0), 1, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(1), 20, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(2), 3, AbsTol=1e-12);
end

function out = failAwayFromLowerBound(rho)
    if rho == 0
        out = 0;
        return
    end
    error("tests:ExpectedHandleFailure", "deliberate evaluation failure");
end

function out = changeSizeAwayFromLowerBound(rho)
    if rho == 0
        out = 0;
    else
        out = eye(2);
    end
end
