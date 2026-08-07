function tests = test_equalities
    %TEST_EQUALITIES Direct coefficient equality and derivative-row contracts.
    tests = functiontests(localfunctions);
end

function setup(~)
    % Equality tests rely on isolated YALMIP handles and assignments.
    yalmip("clear");
end

function testOrdGriDegAndKno(testCase)
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

function testRecAndNonEquIs(testCase)
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

function testProIdeIsEmp(testCase)
    % A proven zero residual contributes no redundant equality constraints.
    P = pdvar(2, {[0 1]}, "full");
    C = P == P;

    testCase.verifyEmpty(C.Constraints);
    testCase.verifyEmpty(toYalmip(C));
end

function testComDerEquPreRow(testCase)
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

function testDerRejOrdOpeBot(testCase)
    % Derivative rows cannot be broadcast during coefficient equality.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    D = rhodiff(P);
    Q = pdvar(1, {[0 1]});

    testCase.verifyError(@() D == 0, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() 0 == D, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() D == Q, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() Q == D, "pdvar:InvalidEqualityRows");
end

function testMixRowKinRejBef(testCase)
    % The shared storage validator rejects mixed rows before any algebra.
    testCase.verifyError(@() mixedRowPdvar(false), ...
        "pdbase:InvalidCoefficientRows");
    testCase.verifyError(@() mixedRowPdvar(true), ...
        "pdbase:InvalidCoefficientRows");
end

function testEquDefRejLatRowDri(testCase)
    % Fast internal sampling may defer later-cell row drift to equality.
    ordinary = {sdpvar(1, 1)};
    derivative = {sdpvar(1, 1); sdpvar(1, 1)};
    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {{[0 1 2]}}, ...
        "MatrixSize", [1 1], ...
        "Degree", 0, ...
        "LocalValues", {{ordinary, derivative}}, ...
        "IsContinuous", false, ...
        "ContainsDecision", true, ...
        "RateBounds", [], ...
        "SourceSummary", "test-late-row-drift", ...
        "ValidationMode", "fast");
    P = pdvar(init);

    testCase.verifyError(@() P == 0, "pdvar:InvalidEqualityRows");
end

function testFixRatDerRejOrdBotAndFir(testCase)
    % A single distinct rate vertex remains a derivative equality row.
    P = pdvar(1, {[0 1]}, Degree=2, RateBounds=[2 2]);
    D = rhodiff(P);

    testCase.verifyEqual(D.NumRateRows, 1);
    testCase.verifySize(D.coeffs(1), [1 2]);
    testCase.verifyError(@() D == P, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() P == D, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() D == 0, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() 0 == D, "pdvar:InvalidEqualityRows");

    % Row-kind precedence is authoritative even when subtraction would first
    % reject another grid, degree, rate box, or matrix shape.
    ordinary = {
        pdvar(1, {[0 2]}, Degree=2, RateBounds=[2 2]), ...
        pdvar(1, {[0 1]}, Degree=1, RateBounds=[2 2]), ...
        pdvar(1, {[0 1]}, Degree=2, RateBounds=[-1 1]), ...
        pdvar(2, {[0 1]}, "full", Degree=2, RateBounds=[2 2]), ...
        [1 2]
    };
    for k = 1:numel(ordinary)
        Q = ordinary{k};
        testCase.verifyError(@() D == Q, "pdvar:InvalidEqualityRows");
        testCase.verifyError(@() Q == D, "pdvar:InvalidEqualityRows");
    end
end

function testFixRatDerEquOneRowInOrd(testCase)
    % Compatible fixed-rate derivatives assemble one row in coefficient order.
    rb = [2 2];
    Dp = rhodiff(pdvar(1, {[0 1]}, Degree=2, RateBounds=rb));
    Dq = rhodiff(pdvar(1, {[0 1]}, Degree=2, RateBounds=rb));
    C = Dp == Dq;

    testCase.verifyEqual(C.Residual.NumRateRows, 1);
    testCase.verifyEqual(C.Residual.RateBounds, rb);
    testCase.verifySize(C.Residual.coeffs(1), [1 2]);
    testCase.verifyEqual(numel(C.Constraints), 2);
    verifyEqualityConstraintOrder(testCase, C);
end

function testMixFixVarTenDerEquRowOrd(testCase)
    % Mixed fixed/varying directions retain distinct combRows vertex order.
    grid = {[0 1], [10 12]};
    rb = [2 2; -1 3];
    Dp = rhodiff(pdvar(1, grid, Degree=[1 1], RateBounds=rb));
    Dq = rhodiff(pdvar(1, grid, Degree=[1 1], RateBounds=rb));
    C = Dp == Dq;

    testCase.verifyEqual(helper.rateVerts(rb), [2 -1; 2 3]);
    testCase.verifyEqual(Dp.NumRateRows, 2);
    testCase.verifySize(Dp.coeffs([1 1]), [2 4]);
    testCase.verifyEqual(C.Residual.NumRateRows, 2);
    testCase.verifyEqual(numel(C.Constraints), 2 * 4);
    verifyEqualityConstraintOrder(testCase, C);

    ordinary = pdvar(1, grid, Degree=[1 1], RateBounds=rb);
    testCase.verifyError(@() Dp == ordinary, "pdvar:InvalidEqualityRows");
    testCase.verifyError(@() ordinary == Dp, "pdvar:InvalidEqualityRows");
end

function testDerComErrRemSub(testCase)
    % Once both sides are derivative rows, algebra retains its established IDs.
    P = pdvar(1, {[0 1]}, RateBounds=[-1 1]);
    differentGrid = pdvar(1, {[0 2]}, RateBounds=[-1 1]);
    differentRate = pdvar(1, {[0 1]}, RateBounds=[0 1]);

    testCase.verifyError(@() rhodiff(P) == rhodiff(differentGrid), ...
        "pdvar:MixedGrid");
    testCase.verifyError(@() rhodiff(P) == rhodiff(differentRate), ...
        "pdvar:InvalidSubtraction");
end

function testEquRejEveCerOpt(testCase)
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

function testEquAppMetGuaBef(testCase)
    % Apply methods reject equality before validating malformed orders.
    C = pdlmi(pdvar(1, {[0 1]}), "==");

    testCase.verifyError(@() C.usePolya(-1), ...
        "pdlmi:UnsupportedEqualityCertificate");
    testCase.verifyError(@() C.usePutinar("bad"), ...
        "pdlmi:UnsupportedEqualityCertificate");
    testCase.verifyError(@() C.useSpPut("bad", -1), ...
        "pdlmi:UnsupportedEqualityCertificate");
    testCase.verifyError(@() C.useFullBox(0.5), ...
        "pdlmi:UnsupportedEqualityCertificate");
    testCase.verifyError(@() C.useSpBox("bad", -1), ...
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
        "RateBounds", [-1 1], ...
        "SourceSummary", "test-mixed-row-kind", ...
        "ValidationMode", "strict");
    obj = pdvar(init);
end

function verifyEqualityConstraintOrder(testCase, wrapper)
    % Direct equality assembly follows cell, row, then coefficient order.
    cells = wrapper.Residual.cells();
    index = 0;
    for c = 1:size(cells, 1)
        coeffs = wrapper.Residual.coeffs(cells(c, :));
        for row = 1:size(coeffs, 1)
            for k = 1:size(coeffs, 2)
                index = index + 1;
                actual = full(getbase(sdpvar(wrapper.Constraints{index})));
                expected = full(getbase(coeffs{row, k}(:)));
                % YALMIP may normalize an equality by reversing its sign.
                testCase.verifyTrue(isequal(actual, expected) || ...
                    isequal(actual, -expected));
            end
        end
    end
    testCase.verifyEqual(index, numel(wrapper.Constraints));
end
