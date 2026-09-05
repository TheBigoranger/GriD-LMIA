function tests = test_equalities
    % Behavioral regressions for pdlmi.equalities.
    tests = functiontests(localfunctions);
end

function setup(~)
    % Equality tests rely on isolated YALMIP handles and assignments.
    yalmip("clear");
end

function test_composed_fixed_rate_equality_preserves_affine_targets(testCase)
    % Recover each target from original controls, not from the assembled residual.
    grid = [0 1 4];
    P = pdvar(2, 1, grid, 'full', Degree=2, RateBounds=[2 2]);
    Q = pdvar(2, 1, grid, 'full', Degree=2, RateBounds=[2 2]);
    L = [2 -1; 3 4];
    actual = L * rhodiff(P) == L * rhodiff(Q);
    index = 0;
    for c = 1:2
        p = P.coeffs(c); q = Q.coeffs(c);
        for k = 1:2
            expected = 4 / (grid(c + 1) - grid(c)) * ...
                L * (p{k + 1} - p{k} - q{k + 1} + q{k});
            index = index + 1;
            testCase.verifyTrue(logical(is(actual.Constraints{index}, 'equality')));
            expression = sdpvar(actual.Constraints{index});
            % YALMIP may reverse an equality's sign; variable identities remain exact.
            forward = norm(full(getbase(expression - expected(:))), 'fro');
            reverse = norm(full(getbase(expression + expected(:))), 'fro');
            testCase.verifyLessThanOrEqual(min(forward, reverse), 1e-10);
        end
    end
    testCase.verifyEqual(numel(actual.Constraints), index);
    testCase.verifyEqual(actual.Residual.NumRateRows, 1);
end

function test_equality_entry_wise_by_definition_never(testCase)
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

function test_proven_zero_residual_contributes_no_redundant(testCase)
    % A proven zero residual contributes no redundant equality constraints.
    P = pdvar(2, {[0 1]}, "full");
    C = P == P;

    testCase.verifyEmpty(C.Constraints);
    testCase.verifyEmpty(toYalmip(C));
end

function test_matching_derivative_operands_paired_by_cell(testCase)
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

function test_storage_validator_rejects_mixed_rows_any(testCase)
    % The shared storage validator rejects mixed rows before any algebra.
    testCase.verifyError(@() mixedRowPdvar(false), ...
        "pdbase:InvalidCoefficientRows");
    testCase.verifyError(@() mixedRowPdvar(true), ...
        "pdbase:InvalidCoefficientRows");
end

function test_compatible_fixed_rate_derivatives_assemble_row(testCase)
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

function test_mixed_fixed_varying_directions_distinct_combrows(testCase)
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

function test_any_recognized_certificate_name_rejected_value(testCase)
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

function test_apply_methods_reject_equality_validating_malformed(testCase)
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
                expression = sdpvar(wrapper.Constraints{index});
                target = coeffs{row, k}(:);
                % Identical basis columns can refer to different decision variables.
                testCase.verifyEqual(getvariables(expression), getvariables(target));
                actual = full(getbase(expression));
                expected = full(getbase(target));
                % YALMIP may normalize an equality by reversing its sign.
                testCase.verifyTrue(isequal(actual, expected) || ...
                    isequal(actual, -expected));
            end
        end
    end
    testCase.verifyEqual(index, numel(wrapper.Constraints));
end
