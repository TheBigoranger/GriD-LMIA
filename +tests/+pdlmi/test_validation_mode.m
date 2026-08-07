function tests = test_validation_mode
    %TEST_VALIDATION_MODE Transient validation across assembly entry points.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep constraint and auxiliary-variable IDs local to this suite.
    yalmip("clear");
end

function testDirDefFasStrEqu(testCase)
    % Direct assembly has the same public structure in all validation modes.
    P = pdvar(2, [0 1], "symmetric", Degree=1);

    implicit = pdlmi(P, ">=");
    fast = pdlmi(P, ">=", ValidationMode="FAST");
    strict = pdlmi(P, ">=", ValidationMode='Strict');

    veriSamPubAss(testCase, implicit, fast);
    veriSamPubAss(testCase, fast, strict);
    testCase.verifyFalse(isprop(implicit, "ValidationMode"));
end

function testInvModUseOwnIde(testCase)
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

function testAppMetAccTraMod(testCase)
    % Every apply method parses its own trailing mode and rebuilds Residual.
    P = pdvar(1, [0 1], Degree=0);
    direct = pdlmi(P, ">=", ValidationMode="strict");

    polya = direct.usePolya(0, ValidationMode='FAST');
    putinar = direct.usePutinar(0, ValidationMode="Strict");
    sparsePutinarEndpoint = direct.useSpPut(1, 0, ...
        ValidationMode="fast");
    full = direct.useFullBox(0, ValidationMode='fast');
    sparseEndpoint = direct.useSpBox(1, 0, ...
        ValidationMode="STRICT");
    activeP = pdvar(1, [0 1], Degree=4);
    activeDirect = activeP >= 0;
    sparsePutinar = activeDirect.useSpPut(2, 2, ...
        ValidationMode="STRICT");

    testCase.verifyTrue(polya.UsePolya);
    testCase.verifyEqual(polya.PolyaDegree, 0);
    testCase.verifyTrue(putinar.UsePutinar);
    testCase.verifyEqual(putinar.PutinarOrder, 0);
    testCase.verifyFalse(sparsePutinarEndpoint.UseSparsePutinar);
    testCase.verifyEqual(numel(sparsePutinarEndpoint.Constraints), ...
        numel(direct.Constraints));
    testCase.verifyTrue(full.UseFullBoxPreorder);
    testCase.verifyEqual(full.FullBoxOrder, 0);
    testCase.verifyFalse(sparseEndpoint.UseSparseFullBoxPreorder);
    testCase.verifyFalse(sparseEndpoint.UseFullBoxPreorder);
    testCase.verifyEqual(numel(sparseEndpoint.Constraints), ...
        numel(direct.Constraints));
    testCase.verifyTrue(sparsePutinar.UseSparsePutinar);
    testCase.verifyEqual(sparsePutinar.SparsePutinarOrder, 2);
    testCase.verifyEqual(sparsePutinar.CliqueSize, 2);
    testCase.verifyEqual(numel(sparsePutinar.Constraints), 8);
end

function testAppMetOwnMalMod(testCase)
    % Apply calls reject missing and malformed transient modes consistently.
    P = pdvar(1, [0 1], Degree=0);
    direct = P >= 0;

    testCase.verifyError(@() direct.usePolya( ...
        ValidationMode="bad"), "pdlmi:InvalidValidationMode");
    testCase.verifyError(@() direct.usePutinar( ...
        ValidationMode=42), "pdlmi:InvalidValidationMode");
    testCase.verifyError(@() direct.useSpPut( ...
        ValidationMode=42), "pdlmi:InvalidValidationMode");
    testCase.verifyError(@() direct.useSpBox( ...
        ValidationMode=["fast", "strict"]), ...
        "pdlmi:InvalidValidationMode");
    testCase.verifyError(@() direct.useFullBox( ...
        "ValidationMode"), "pdlmi:InvalidValidationMode");
end

function testConParAndAppPosBou(testCase)
    % Constructor selectors and apply methods reject malformed public calls.
    P = pdvar(1, [0 1], Degree=0);
    direct = P >= 0;

    testCase.verifyError(@() pdlmi(1, ">="), ...
        "pdlmi:InvalidExpression");
    testCase.verifyError(@() pdlmi(P, ">=", "PolyaDegree"), ...
        "pdlmi:InvalidOptions");
    testCase.verifyError(@() pdlmi(P, ">=", "UsePolya", 1), ...
        "pdlmi:InvalidUsePolya");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        "UseFullBoxPreorder", 1), "pdlmi:InvalidUseFullBoxPreorder");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        "UseSparseFullBoxPreorder", 1), ...
        "pdlmi:InvalidUseSparseFullBoxPreorder");

    testCase.verifyError(@() direct.usePolya(0, 1), ...
        "pdlmi:InvalidApplyOptions");
    testCase.verifyError(@() direct.usePutinar(0, 1), ...
        "pdlmi:InvalidApplyOptions");
    testCase.verifyError(@() direct.useFullBox(0, 1), ...
        "pdlmi:InvalidApplyOptions");
    testCase.verifyError(@() direct.useSpPut(1, 0, 1), ...
        "pdlmi:InvalidApplyOptions");
    testCase.verifyError(@() direct.useSpBox(1, 0, 1), ...
        "pdlmi:InvalidApplyOptions");
end

function testGloClaRemGloIn(testCase)
    % A later cell or rate row selects entry-wise mode for the whole wrapper.
    first = sdpvar(2, 2, 'symmetric');
    later = sdpvar(2, 2, 'full');
    acrossCells = internalPdvar({{first}, {later}}, [], ...
        "test-later-cell");
    for mode = ["fast", "strict"]
        C = constructElementwise(@() pdlmi(acrossCells, ">=", ...
            ValidationMode=mode));
        veriAllVecCon(testCase, C, 4);
    end

    earlyRow = sdpvar(2, 2, 'symmetric');
    lateRow = sdpvar(2, 2, 'full');
    acrossRows = internalPdvar({{earlyRow; lateRow}}, [-1 1], ...
        "test-later-rate-row");
    for mode = ["fast", "strict"]
        C = constructElementwise(@() pdlmi(acrossRows, ">=", ...
            ValidationMode=mode));
        veriAllVecCon(testCase, C, 4);
    end
end

function testStrAssRejMalLat(testCase)
    % Strict assembly diagnoses later-cell tensor, rate-row, and payload drift.
    first = sdpvar(2, 2, 'symmetric');
    later = sdpvar(2, 2, 'symmetric');

    wrongCount = internalPdvar({{first}, {later, later}}, [], ...
        "test-wrong-count", "fast");
    testCase.verifyError(@() pdlmi(wrongCount, ">=", ...
        ValidationMode="strict"), "pdlmi:InvalidAssemblyData");

    mixedRows = internalPdvar({{first}, {later; later}}, [-1 1], ...
        "test-mixed-rate-layout", "fast");
    testCase.verifyError(@() pdlmi(mixedRows, ">=", ...
        ValidationMode="strict"), "pdlmi:InvalidAssemblyData");

    wrongSize = internalPdvar({{first}, {sdpvar(1, 1)}}, [], ...
        "test-wrong-payload-size", "fast");
    testCase.verifyError(@() pdlmi(wrongSize, ">=", ...
        ValidationMode="strict"), "pdlmi:InvalidAssemblyData");
end

function veriSamPubAss(testCase, lhs, rhs)
    % Compare observable wrapper metadata and exported decision support.
    testCase.verifyEqual(lhs.Relation, rhs.Relation);
    testCase.verifyEqual(numel(lhs.Constraints), numel(rhs.Constraints));
    testCase.verifyEqual(lhs.UsePolya, rhs.UsePolya);
    testCase.verifyEqual(lhs.UsePutinar, rhs.UsePutinar);
    testCase.verifyEqual(lhs.UseSparsePutinar, rhs.UseSparsePutinar);
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

function veriAllVecCon(testCase, C, nEntry)
    % Global entry-wise classification vectorizes every stored coefficient.
    for k = 1:numel(C.Constraints)
        metadata = struct(C.Constraints{k});
        testCase.verifySize(metadata.List{1}, [nEntry 1]);
    end
end

function obj = internalPdvar(vals, rb, summary, validationMode)
    % Build global-classification cases public symmetric allocation excludes.
    if nargin < 4
        validationMode = "strict";
    end
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
    init.RateBounds = rb;
    init.SourceSummary = summary;
    init.ValidationMode = validationMode;
    obj = pdvar(init);
end
