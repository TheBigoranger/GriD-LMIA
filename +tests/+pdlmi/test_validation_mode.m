function tests = test_validation_mode
    %TEST_VALIDATION_MODE Transient validation across assembly entry points.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep constraint and auxiliary-variable IDs local to this suite.
    yalmip("clear");
end

function testDirectDefaultFastStrictEquivalent(testCase)
    % Direct assembly has the same public structure in all validation modes.
    P = pdvar(2, [0 1], "symmetric", Degree=1);

    implicit = pdlmi(P, ">=");
    fast = pdlmi(P, ">=", ValidationMode="FAST");
    strict = pdlmi(P, ">=", ValidationMode='Strict');

    verifySamePublicAssembly(testCase, implicit, fast);
    verifySamePublicAssembly(testCase, fast, strict);
    testCase.verifyFalse(isprop(implicit, "ValidationMode"));
end

function testInvalidModesUseOwnerIdentifier(testCase)
    % Constructor mode failures are owned by pdlmi.
    P = pdvar(1, [0 1], Degree=0);
    make = @(mode) pdlmi(P, ">=", ValidationMode=mode);
    bad = {42, ["fast", "strict"], string(missing), '', "sample"};
    for k = 1:numel(bad)
        testCase.verifyError(@() make(bad{k}), ...
            "pdlmi:InvalidValidationMode");
    end
    testCase.verifyError(@() pdlmi(P, ">=", ...
        "ValidationMode"), "pdlmi:InvalidValidationMode");
end

function testApplyMethodsAcceptTrailingModeAndReplaceFamily(testCase)
    % Every apply method parses its own trailing mode and rebuilds Residual.
    P = pdvar(1, [0 1], Degree=0);
    direct = pdlmi(P, ">=", ValidationMode="strict");

    polya = direct.applyPolya(0, ValidationMode='FAST');
    putinar = direct.applyPutinar(0, ValidationMode="Strict");
    full = direct.applyFullBoxPreorder(0, ValidationMode='fast');
    sparseEndpoint = direct.applySparseFullBoxPreorder(1, 0, ...
        ValidationMode="STRICT");

    testCase.verifyTrue(polya.UsePolya);
    testCase.verifyEqual(polya.PolyaDegree, 0);
    testCase.verifyTrue(putinar.UsePutinar);
    testCase.verifyEqual(putinar.PutinarOrder, 0);
    testCase.verifyTrue(full.UseFullBoxPreorder);
    testCase.verifyEqual(full.FullBoxOrder, 0);
    testCase.verifyFalse(sparseEndpoint.UseSparseFullBoxPreorder);
    testCase.verifyFalse(sparseEndpoint.UseFullBoxPreorder);
    testCase.verifyEqual(numel(sparseEndpoint.Constraints), ...
        numel(direct.Constraints));
end

function testApplyMethodsOwnMalformedModeErrors(testCase)
    % Apply calls reject missing and malformed transient modes consistently.
    P = pdvar(1, [0 1], Degree=0);
    direct = P >= 0;

    testCase.verifyError(@() direct.applyPolya( ...
        ValidationMode="bad"), "pdlmi:InvalidValidationMode");
    testCase.verifyError(@() direct.applyPutinar( ...
        ValidationMode=42), "pdlmi:InvalidValidationMode");
    testCase.verifyError(@() direct.applySparseFullBoxPreorder( ...
        ValidationMode=["fast", "strict"]), ...
        "pdlmi:InvalidValidationMode");
    testCase.verifyError(@() direct.applyFullBoxPreorder( ...
        "ValidationMode"), "pdlmi:InvalidValidationMode");
end

function testGlobalClassificationRemainsGlobalInBothModes(testCase)
    % A later cell or rate row selects entry-wise mode for the whole wrapper.
    first = sdpvar(2, 2, 'symmetric');
    later = sdpvar(2, 2, 'full');
    acrossCells = internalPdvar({{first}, {later}}, false, [], ...
        "test-later-cell");
    for mode = ["fast", "strict"]
        C = constructElementwise(@() pdlmi(acrossCells, ">=", ...
            ValidationMode=mode));
        verifyAllVectorConstraints(testCase, C, 4);
    end

    earlyRow = sdpvar(2, 2, 'symmetric');
    lateRow = sdpvar(2, 2, 'full');
    acrossRows = internalPdvar({{earlyRow; lateRow}}, true, [-1 1], ...
        "test-later-rate-row");
    for mode = ["fast", "strict"]
        C = constructElementwise(@() pdlmi(acrossRows, ">=", ...
            ValidationMode=mode));
        verifyAllVectorConstraints(testCase, C, 4);
    end
end

function verifySamePublicAssembly(testCase, lhs, rhs)
    % Compare observable wrapper metadata and exported decision support.
    testCase.verifyEqual(lhs.Relation, rhs.Relation);
    testCase.verifyEqual(numel(lhs.Constraints), numel(rhs.Constraints));
    testCase.verifyEqual(lhs.UsePolya, rhs.UsePolya);
    testCase.verifyEqual(lhs.UsePutinar, rhs.UsePutinar);
    testCase.verifyEqual(lhs.UseFullBoxPreorder, rhs.UseFullBoxPreorder);
    testCase.verifyEqual(getvariables(toYalmip(lhs)), ...
        getvariables(toYalmip(rhs)));
end

function out = constructElementwise(fun)
    % Suppress the expected global dispatch warning for this focused check.
    id = "pdlmi:ElementwiseInequality";
    state = warning("query", id);
    cleanup = onCleanup(@() warning(state.state, id)); %#ok<NASGU>
    warning("off", id);
    out = fun();
end

function verifyAllVectorConstraints(testCase, C, nEntry)
    % Global entry-wise classification vectorizes every stored coefficient.
    for k = 1:numel(C.Constraints)
        metadata = struct(C.Constraints{k});
        testCase.verifySize(metadata.List{1}, [nEntry 1]);
    end
end

function obj = internalPdvar(vals, hasRate, rb, summary)
    % Build global-classification cases public symmetric allocation excludes.
    init = struct;
    init.PdvarInternal = true;
    if numel(vals) == 2
        init.Grid = {[0 1 2]};
    else
        init.Grid = {[0 1]};
    end
    init.MatrixSize = [2 2];
    init.Degree = 0;
    init.LocalValues = vals;
    init.IsContinuous = false;
    init.ContainsDecision = true;
    init.HasRateDependence = hasRate;
    init.RateBounds = rb;
    init.SourceSummary = summary;
    init.ValidationMode = "strict";
    obj = pdvar(init);
end
