function tests = test_equalities
    %TEST_EQUALITIES Direct coefficient equality and derivative-row contracts.
    tests = functiontests(localfunctions);
end

function setup(~)
    % Equality tests rely on isolated YALMIP handles and assignments.
    yalmip("clear");
end

function testOrdinaryGridDegreeAndKnownPromotions(testCase)
    % Subtraction aligns grids/degrees and promotes supported ordinary operands.
    P = pdvar(1, {[0 0.5 1]}, Degree=1);
    Q = pdvar(1, {[0 1]}, Degree=2);
    mixed = P == Q;

    testCase.verifyEqual(mixed.Relation, "==");
    testCase.verifyEqual(mixed.Residual.GridInfo.Vectors{1}, [0 0.5 1]);
    testCase.verifyEqual(mixed.Residual.Degree, 2);
    testCase.verifyEqual(numel(mixed.Constraints), 2 * 3);

    R = pdvar(1, {[0 1]}, Degree=1);
    known = pdmat({[0 1]}, {1, 2}, Degree=1);
    x = sdpvar(1, 1);
    cases = {R == known, known == R, R == 2, 2 == R, R == x, x == R};
    for k = 1:numel(cases)
        testCase.verifyEqual(cases{k}.Relation, "==");
        testCase.verifyEqual(numel(cases{k}.Constraints), 2);
    end
end

function testRectangularAndNonsymmetricEqualityIsWarningFree(testCase)
    % Equality is entry-wise by definition and never uses inequality dispatch.
    V = pdvar(3, 2, {[0 1]}, "full");
    X = sdpvar(3, 2, 'full');
    F = pdvar(2, {[0 1]}, "full");

    testCase.verifyWarningFree(@() V == X);
    testCase.verifyWarningFree(@() F == 0);
    C = V == X;
    testCase.verifyEqual(numel(C.Constraints), 2);
    for k = 1:numel(C.Constraints)
        metadata = struct(C.Constraints{k});
        testCase.verifySize(metadata.List{1}, [6 1]);
    end
end

function testProvenIdentityIsEmpty(testCase)
    % A proven zero residual contributes no redundant equality constraints.
    P = pdvar(2, {[0 1]}, "full");
    C = P == P;

    testCase.verifyEmpty(C.Constraints);
    testCase.verifyEmpty(toYalmip(C));
end

function testCompatibleDerivativeEqualityPreservesRows(testCase)
    % Matching derivative operands remain paired by cell, rate row, and label.
    rb = [-1 2];
    P = pdvar(1, {[0 1 2]}, Degree=2, RateBounds=rb);
    Q = pdvar(1, {[0 1 2]}, Degree=2, RateBounds=rb);
    Dp = rhodiff(P);
    Dq = rhodiff(Q);
    C = Dp == Dq;

    testCase.verifyEqual(C.Residual.RateBounds, rb);
    testCase.verifyEqual(size(C.Residual.coeffs(1)), [2 2]);
    testCase.verifyEqual(size(C.Residual.coeffs(2)), [2 2]);
    testCase.verifyEqual(numel(C.Constraints), 2 * 2 * 2);
end

function testDerivativeRejectsOrdinaryOperandsBothOrders(testCase)
    % Derivative rows cannot be broadcast during coefficient equality.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    D = rhodiff(P);
    Q = pdvar(1, {[0 1]});

    testCase.verifyError(@() D == 0, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() 0 == D, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() D == Q, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() Q == D, "pdvar:InvalidEqualityRows");
end

function testMixedRowKindRejectedBeforeSubtraction(testCase)
    % The shared storage validator rejects mixed rows before any algebra.
    testCase.verifyError(@() mixedRowPdvar(false), ...
        "pdbase:InvalidCoefficientRows");
    testCase.verifyError(@() mixedRowPdvar(true), ...
        "pdbase:InvalidCoefficientRows");
end

function testDerivativeCompatibilityErrorsRemainSubtractionOwned(testCase)
    % Once both sides are derivative rows, algebra retains its established IDs.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    differentGrid = pdvar(1, {[0 2]}, RateBounds=[-1 1]);
    differentRate = pdvar(1, {[0 1]}, RateBounds=[0 1]);

    testCase.verifyError(@() rhodiff(P) == rhodiff(differentGrid), ...
        "pdvar:MixedGrid");
    testCase.verifyError(@() rhodiff(P) == rhodiff(differentRate), ...
        "pdvar:InvalidSubtraction");
end

function testEqualityRejectsEveryCertificateOptionBeforeValidation(testCase)
    % Any recognized certificate name is rejected before its value is parsed.
    P = pdvar(1, {[0 1]});
    names = ["UsePolya", "PolyaDegree", "UsePutinar", "PutinarOrder", ...
        "UseSparsePutinar", "SparsePutinarOrder", "CliqueSize", ...
        "UseFullBoxPreorder", "FullBoxOrder", ...
        "UseSparseFullBoxPreorder", "SparseFullBoxOrder", "BandWidth"];
    vals = {false, 0, -1, "malformed"};
    for name = names
        for k = 1:numel(vals)
            testCase.verifyError(@() pdlmi(P, "==", name, vals{k}), ...
                "pdlmi:UnsupportedEqualityCertificate");
        end
    end

    testCase.verifyError(@() pdlmi(P, "==", "Unknown", 1), ...
        "pdlmi:UnknownOption");
    testCase.verifyError(@() pdlmi(P, "==", 7, true), ...
        "pdlmi:InvalidOptions");
end

function testEqualityApplyMethodsGuardBeforeArgumentValidation(testCase)
    % Apply methods reject equality before validating malformed orders.
    C = pdlmi(pdvar(1, {[0 1]}), "==");

    testCase.verifyError(@() C.applyPolya(-1), ...
        "pdlmi:UnsupportedEqualityCertificate");
    testCase.verifyError(@() C.applyPutinar("bad"), ...
        "pdlmi:UnsupportedEqualityCertificate");
    testCase.verifyError(@() C.applySparsePutinar("bad", -1), ...
        "pdlmi:UnsupportedEqualityCertificate");
    testCase.verifyError(@() C.applyFullBoxPreorder(0.5), ...
        "pdlmi:UnsupportedEqualityCertificate");
    testCase.verifyError(@() C.applySparseFullBoxPreorder("bad", -1), ...
        "pdlmi:UnsupportedEqualityCertificate");
end

function obj = mixedRowPdvar(derivativeFirst)
    % Construct the cross-cell row-kind inconsistency rejected by pdbase.
    ordinary = {sdpvar(1, 1)};
    derivative = {sdpvar(1, 1); sdpvar(1, 1)};
    if derivativeFirst
        vals = {derivative, ordinary};
    else
        vals = {ordinary, derivative};
    end
    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {{[0 1 2]}}, ...
        "MatrixSize", [1 1], ...
        "Degree", 0, ...
        "LocalValues", {vals}, ...
        "IsContinuous", false, ...
        "ContainsDecision", true, ...
        "HasRateDependence", true, ...
        "RateBounds", [-1 1], ...
        "SourceSummary", "test-mixed-row-kind", ...
        "ValidationMode", "strict");
    obj = pdvar(init);
end
