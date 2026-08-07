function tests = test_validation_mode
    %TEST_VALIDATION_MODE Public pdvar mode parsing and invariant preservation.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep decision-variable bookkeeping local to this suite.
    yalmip("clear");
end

function testModPrePubCon(testCase)
    % Every mode builds the same shape, grid, degree, and affine structure.
    implicit = pdvar(2, [0 1 2], "full", Degree=2);
    fast = pdvar(2, [0 1 2], "full", Degree=2, ...
        ValidationMode="FAST");
    strict = pdvar(2, [0 1 2], "full", Degree=2, ...
        ValidationMode='Strict');
    implicitCoeffs = implicit.coeffs(1);

    for obj = {fast, strict}
        oneCoeffs = obj{1}.coeffs(1);
        testCase.verifyEqual(obj{1}.GridInfo, implicit.GridInfo);
        testCase.verifyEqual(obj{1}.MatrixSize, implicit.MatrixSize);
        testCase.verifyEqual(obj{1}.Degree, implicit.Degree);
        testCase.verifyEqual(size(oneCoeffs), size(implicitCoeffs));
        testCase.verifyEqual(numel(getvariables(oneCoeffs{1})), ...
            numel(getvariables(implicitCoeffs{1})));
    end
end

function testInvModUseOwnIde(testCase)
    % pdvar owns missing and malformed ValidationMode diagnostics.
    make = @(mode) pdvar(1, [0 1], ValidationMode=mode);
    bad = {42, ["fast", "strict"], string(missing), '', "sample"};
    for k = 1:numel(bad)
        testCase.verifyError(@() make(bad{k}), ...
            "pdvar:InvalidValidationMode");
    end
    testCase.verifyError(@() pdvar(1, [0 1], ...
        "ValidationMode"), "pdvar:InvalidValidationMode");
end

function testSymSliCanResCon(testCase)
    % Exact recomputation recognizes a continuous slice of a forged jump.
    shared = sdpvar(1);
    jumpLeft = sdpvar(1);
    jumpRight = sdpvar(1);
    vals = { ...
        {[shared; jumpLeft], [shared; jumpLeft]}, ...
        {[shared; jumpRight], [shared; jumpRight]}};
    P = internalPdvar(vals);
    slice = P(1, :);

    testCase.verifyFalse(P.IsContinuous);
    testCase.verifyTrue(slice.IsContinuous);
end

function obj = internalPdvar(vals)
    % Build a targeted discontinuous coefficient tree unavailable publicly.
    init = struct;
    init.PdvarInternal = true;
    init.Grid = {[0 1 2]};
    init.MatrixSize = [2 1];
    init.Degree = 1;
    init.LocalValues = vals;
    init.IsContinuous = false;
    init.ContainsDecision = true;
    init.RateBounds = [];
    init.SourceSummary = "test-validation-mode";
    init.ValidationMode = "strict";
    obj = pdvar(init);
end
