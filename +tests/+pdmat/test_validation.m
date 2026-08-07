function tests = test_validation
    %TEST_VALIDATION pdmat rejects malformed constructor inputs clearly.
    tests = functiontests(localfunctions);
end

function testInvSouTyp(testCase)
    % Constructor should reject unsupported source payload types.
    testCase.verifyError(@() pdmat({[0 1]}, eye(2)), "pdmat:InvalidSource");
end

function testGloDegMis(testCase)
    % Global coefficient grids should imply a degree compatible with grid size.
    data = {1, 2, 3, 4};

    testCase.verifyError(@() pdmat({[0 1 2]}, data), "pdmat:InvalidDegree");
    testCase.verifyError(@() pdmat({[0 1 2]}, data, Degree=2), "pdmat:InvalidDegree");
end

function testGloPayMusHavSam(testCase)
    % Global payloads should share one finite real matrix size.
    testCase.verifyError(@() pdmat({[0 1]}, {1, [1 2]}), "pdmat:InvalidData");
    testCase.verifyError(@() pdmat({[0 1]}, {1, Inf}), "pdmat:InvalidData");
    testCase.verifyError(@() pdmat({[0 1]}, {1, 1i}), "pdmat:InvalidData");
end

function testMalNesLocVal(testCase)
    % Explicit LocalValues should validate nesting, degree, and payload shape.
    testCase.verifyError(@() pdmat({[0 1 2]}, {{1, 2}}), ...
        "pdmat:InvalidLocalValues");
    testCase.verifyError(@() pdmat({[0 1 2]}, {{1, 2}, {2, 3}}, Degree=2), ...
        "pdmat:InvalidDegree");
    testCase.verifyError(@() pdmat({[0 1 2]}, {{1, "bad"}, {2, 3}}), ...
        "pdmat:InvalidCoefficientPayload");
end

function testFunAriAndOut(testCase)
    % Function handles should match parameter arity and return real matrices.
    testCase.verifyError(@() pdmat({[0 1]}, @(rho, eta) rho + eta), ...
        "pdmat:InvalidFunctionHandle");
    testCase.verifyError(@() pdmat({[0 1]}, @(rho) []), ...
        "pdmat:InvalidFunctionOutput");
    testCase.verifyError(@() pdmat({[0 1]}, @(rho) rho + 1i), ...
        "pdmat:InvalidFunctionOutput");
end

function testFunDegMusBeBer(testCase)
    % Explicit-degree function data should reject nonrepresentable polynomials.
    testCase.verifyError(@() pdmat({[0 1]}, @(rho) rho.^2, Degree=1), ...
        "pdmat:NonBernsteinPolynomial");
end

function testFunMatDegMusBeBer(testCase)
    % One over-degree matrix entry should reject the complete function.
    testCase.verifyError(@() pdmat({[0 1]}, ...
        @(rho) [rho, rho.^2; 0, 1], Degree=1), ...
        "pdmat:NonBernsteinPolynomial");
end

function testNumFalRejNonPol(testCase)
    % Numeric probing fallback should still reject non-polynomial handles.
    testCase.verifyError(@() pdmat({[0 1]}, @numericOnlyNonpoly, Degree=1), ...
        "pdmat:NonBernsteinPolynomial");
end

function testMalFunDurBerPro(testCase)
    % Bernstein probing should reject handles with inconsistent output shape.
    testCase.verifyError(@() pdmat({[0 1]}, @badProbeShape, Degree=1), ...
        "pdmat:InvalidFunctionValue");
end

function testFixOptAndMalRat(testCase)
    % Fixed representation flags stay unavailable while RateBounds is public.
    data = {1, 2};

    testCase.verifyError(@() pdmat({[0 1]}, data, IsContinuous=false), ...
        "pdmat:UnsupportedOption");
    testCase.verifyError(@() pdmat({[0 1]}, data, ContainsDecision=true), ...
        "pdmat:UnsupportedOption");
    testCase.verifyError(@() pdmat({[0 1]}, data, RateBounds=[1 -1]), ...
        "pdmat:InvalidRateBounds");
    testCase.verifyError(@() pdmat({[0 1]}, data, RateBounds=[-1 1; -1 1]), ...
        "pdmat:InvalidRateBounds");
end

function testConOptParBou(testCase)
    % Constructor option syntax rejects missing, nontext, duplicate, and unknown names.
    grid = {[0 1]};
    data = {1, 2};

    testCase.verifyError(@() pdmat(grid, data, "Degree"), ...
        "pdmat:InvalidOptions");
    testCase.verifyError(@() pdmat(grid, data, 7, 1), ...
        "pdmat:InvalidOptions");
    testCase.verifyError(@() pdmat(grid, data, ...
        "Degree", 1, "Degree", 1), "pdmat:DuplicateOption");
    testCase.verifyError(@() pdmat(grid, data, ...
        "RateBounds", [-1 1], "RateBounds", [-1 1]), ...
        "pdmat:DuplicateOption");
    testCase.verifyError(@() pdmat(grid, data, ...
        "ValidationMode", "fast", "ValidationMode", "strict"), ...
        "pdmat:InvalidValidationMode");
    testCase.verifyError(@() pdmat(grid, data, "Unknown", 1), ...
        "pdmat:UnknownOption");
end

function testFunCalFaiOwnSta(testCase)
    % Callback failures are normalized at the lower-bound and validation seams.
    testCase.verifyError(@() pdmat({[0 1]}, @alwaysFail), ...
        "pdmat:InvalidFunctionHandle");
    testCase.verifyError(@() pdmat({[0 1]}, @failAwayFromNodes, Degree=1), ...
        "pdmat:InvalidFunctionValue");
end

function testDegreeValidation(testCase)
    % Explicit Degree rejects empty and every non-scalar/non-ell shape.
    grid = {[0 1], [10 20]};
    data = {1 2; 3 4};
    bad = {[], [1 2 3], [1 2; 3 4], -1, 0.5, Inf, NaN, "one"};
    for k = 1:numel(bad)
        testCase.verifyError(@() pdmat(grid, data, Degree=bad{k}), ...
            "pdmat:InvalidDegree");
    end
end

function testMalAndMixExpRat(testCase)
    % Explicit leaves use one row or one row per distinct rate vertex.
    collapsed = pdmat({[0 1], [0 1]}, {{{1; 2}}}, ...
        Degree=[0 0], RateBounds=[1 1; -2 3]);
    testCase.verifyEqual(collapsed.NumRateRows, 2);
    testCase.verifyEqual(collapsed.coeffs([1 1]), {1; 2});

    testCase.verifyError(@() pdmat([0 1], {{1, 2; 3, Inf}}, ...
        Degree=1, RateBounds=[-1 1]), ...
        "pdmat:InvalidCoefficientPayload");
    testCase.verifyError(@() pdmat([0 1], {{1, 2; 3, 4; 5, 6}}, ...
        Degree=1, RateBounds=[-1 1]), ...
        "pdmat:InvalidCoefficientCell");

    mixed = {
        {1, 2}, ...
        {2, 3; 4, 5}
        };
    testCase.verifyError(@() pdmat([0 1 2], mixed, ...
        Degree=1, RateBounds=[-1 1]), ...
        "pdmat:InvalidLocalValues");
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

function out = alwaysFail(~)
    % Fail at the constructor's lower-bound probe.
    error("tests:CallbackFailure", "intentional lower-bound failure");
    out = []; %#ok<UNRCH>
end

function out = failAwayFromNodes(rho)
    % Interpolation nodes succeed while off-node validation probes fail.
    if isnumeric(rho) && isscalar(rho) && any(rho == [0 1])
        out = rho;
        return
    end
    error("tests:CallbackFailure", "intentional validation failure");
end
