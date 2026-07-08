function tests = test_validation
    %TEST_VALIDATION dpmat rejects malformed constructor inputs clearly.
    tests = functiontests(localfunctions);
end

function testInvalidSourceType(testCase)
    % Constructor should reject unsupported source payload types.
    testCase.verifyError(@() dpmat({[0 1]}, eye(2)), "dpmat:InvalidSource");
end

function testGlobalDegreeMismatch(testCase)
    % Global coefficient grids should imply a degree compatible with grid size.
    data = {1, 2, 3, 4};

    testCase.verifyError(@() dpmat({[0 1 2]}, data), "dpmat:InvalidDegree");
    testCase.verifyError(@() dpmat({[0 1 2]}, data, Degree=2), "dpmat:InvalidDegree");
end

function testGlobalPayloadsMustHaveSameFiniteRealSize(testCase)
    % Global payloads should share one finite real matrix size.
    testCase.verifyError(@() dpmat({[0 1]}, {1, [1 2]}), "dpmat:InvalidData");
    testCase.verifyError(@() dpmat({[0 1]}, {1, Inf}), "dpmat:InvalidData");
    testCase.verifyError(@() dpmat({[0 1]}, {1, 1i}), "dpmat:InvalidData");
end

function testMalformedNestedLocalValues(testCase)
    % Explicit LocalValues should validate nesting, degree, and payload shape.
    testCase.verifyError(@() dpmat({[0 1 2]}, {{1, 2}}), ...
        "dpmat:InvalidLocalValues");
    testCase.verifyError(@() dpmat({[0 1 2]}, {{1, 2}, {2, 3}}, Degree=2), ...
        "dpmat:InvalidDegree");
    testCase.verifyError(@() dpmat({[0 1 2]}, {{1, "bad"}, {2, 3}}), ...
        "dpmat:InvalidCoefficientPayload");
end

function testFunctionArityAndOutputs(testCase)
    % Function handles should match parameter arity and return real matrices.
    testCase.verifyError(@() dpmat({[0 1]}, @(rho, eta) rho + eta), ...
        "dpmat:InvalidFunctionHandle");
    testCase.verifyError(@() dpmat({[0 1]}, @(rho) []), ...
        "dpmat:InvalidFunctionOutput");
    testCase.verifyError(@() dpmat({[0 1]}, @(rho) rho + 1i), ...
        "dpmat:InvalidFunctionOutput");
end

function testFunctionDegreeMustBeBernsteinRepresentable(testCase)
    % Explicit-degree function data should reject nonrepresentable polynomials.
    testCase.verifyError(@() dpmat({[0 1]}, @(rho) rho.^2, Degree=1), ...
        "dpmat:NonBernsteinPolynomial");
end

function testNumericFallbackRejectsNonPolynomialHandle(testCase)
    % Numeric probing fallback should still reject non-polynomial handles.
    testCase.verifyError(@() dpmat({[0 1]}, @numericOnlyNonpoly, Degree=1), ...
        "dpmat:NonBernsteinPolynomial");
end

function testMalformedFunctionDuringBernsteinProbe(testCase)
    % Bernstein probing should reject handles with inconsistent output shape.
    testCase.verifyError(@() dpmat({[0 1]}, @badProbeShape, Degree=1), ...
        "dpmat:InvalidFunctionValue");
end

function testDecisionAndRateOptionsUnavailable(testCase)
    % dpmat should reject decision, discontinuity, and rate options for now.
    data = {1, 2};

    testCase.verifyError(@() dpmat({[0 1]}, data, IsContinuous=false), ...
        "dpmat:UnsupportedOption");
    testCase.verifyError(@() dpmat({[0 1]}, data, ContainsDecision=true), ...
        "dpmat:UnsupportedOption");
    testCase.verifyError(@() dpmat({[0 1]}, data, HasRateDependence=true), ...
        "dpmat:UnsupportedOption");
    testCase.verifyError(@() dpmat({[0 1]}, data, RateBounds=[-1 1]), ...
        "dpmat:UnsupportedOption");
end

function out = numericOnlyNonpoly(rho)
    % Force numeric fallback before rejecting a non-polynomial handle.
    if ~isnumeric(rho)
        error("test:NoSymbolicPath", "Use numeric fallback.");
    end
    out = sin(rho);
end

function out = badProbeShape(rho)
    % Return inconsistent probe sizes so Bernstein sampling fails validation.
    if rho == 0
        out = 1;
    else
        out = [1 2];
    end
end
