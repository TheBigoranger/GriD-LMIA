function tests = test_validation
    %TEST_VALIDATION pdmat rejects malformed constructor inputs clearly.
    tests = functiontests(localfunctions);
end

function testInvalidSourceType(testCase)
    % Constructor should reject unsupported source payload types.
    testCase.verifyError(@() pdmat({[0 1]}, eye(2)), "pdmat:InvalidSource");
end

function testGlobalDegreeMismatch(testCase)
    % Global coefficient grids should imply a degree compatible with grid size.
    data = {1, 2, 3, 4};

    testCase.verifyError(@() pdmat({[0 1 2]}, data), "pdmat:InvalidDegree");
    testCase.verifyError(@() pdmat({[0 1 2]}, data, Degree=2), "pdmat:InvalidDegree");
end

function testGlobalPayloadsMustHaveSameFiniteRealSize(testCase)
    % Global payloads should share one finite real matrix size.
    testCase.verifyError(@() pdmat({[0 1]}, {1, [1 2]}), "pdmat:InvalidData");
    testCase.verifyError(@() pdmat({[0 1]}, {1, Inf}), "pdmat:InvalidData");
    testCase.verifyError(@() pdmat({[0 1]}, {1, 1i}), "pdmat:InvalidData");
end

function testMalformedNestedLocalValues(testCase)
    % Explicit LocalValues should validate nesting, degree, and payload shape.
    testCase.verifyError(@() pdmat({[0 1 2]}, {{1, 2}}), ...
        "pdmat:InvalidLocalValues");
    testCase.verifyError(@() pdmat({[0 1 2]}, {{1, 2}, {2, 3}}, Degree=2), ...
        "pdmat:InvalidDegree");
    testCase.verifyError(@() pdmat({[0 1 2]}, {{1, "bad"}, {2, 3}}), ...
        "pdmat:InvalidCoefficientPayload");
end

function testFunctionArityAndOutputs(testCase)
    % Function handles should match parameter arity and return real matrices.
    testCase.verifyError(@() pdmat({[0 1]}, @(rho, eta) rho + eta), ...
        "pdmat:InvalidFunctionHandle");
    testCase.verifyError(@() pdmat({[0 1]}, @(rho) []), ...
        "pdmat:InvalidFunctionOutput");
    testCase.verifyError(@() pdmat({[0 1]}, @(rho) rho + 1i), ...
        "pdmat:InvalidFunctionOutput");
end

function testFunctionDegreeMustBeBernsteinRepresentable(testCase)
    % Explicit-degree function data should reject nonrepresentable polynomials.
    testCase.verifyError(@() pdmat({[0 1]}, @(rho) rho.^2, Degree=1), ...
        "pdmat:NonBernsteinPolynomial");
end

function testNumericFallbackRejectsNonPolynomialHandle(testCase)
    % Numeric probing fallback should still reject non-polynomial handles.
    testCase.verifyError(@() pdmat({[0 1]}, @numericOnlyNonpoly, Degree=1), ...
        "pdmat:NonBernsteinPolynomial");
end

function testMalformedFunctionDuringBernsteinProbe(testCase)
    % Bernstein probing should reject handles with inconsistent output shape.
    testCase.verifyError(@() pdmat({[0 1]}, @badProbeShape, Degree=1), ...
        "pdmat:InvalidFunctionValue");
end

function testDecisionAndRateOptionsUnavailable(testCase)
    % pdmat should reject decision, discontinuity, and rate options for now.
    data = {1, 2};

    testCase.verifyError(@() pdmat({[0 1]}, data, IsContinuous=false), ...
        "pdmat:UnsupportedOption");
    testCase.verifyError(@() pdmat({[0 1]}, data, ContainsDecision=true), ...
        "pdmat:UnsupportedOption");
    testCase.verifyError(@() pdmat({[0 1]}, data, HasRateDependence=true), ...
        "pdmat:UnsupportedOption");
    testCase.verifyError(@() pdmat({[0 1]}, data, RateBounds=[-1 1]), ...
        "pdmat:UnsupportedOption");
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
