function tests = test_constructor
    % Behavioral regressions for pdlmi.constructor.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    yalmip("clear");
end

function test_rhodiff_stores_row_rate_vertex_pdlmi(testCase)
    % rhodiff stores one row per rate vertex; pdlmi constrains every row.
    P = pdvar(2, {[0 1 2]}, "symmetric", RateBounds=[-1 1]);
    D = rhodiff(P);

    C = D <= 0;

    testCase.verifyClass(C, "pdlmi");
    testCase.verifyEqual(numel(C.Constraints), 4);
    veriConCel(testCase, C);
end

function test_fixed_rate_contributes_direct_constraint_without(testCase)
    % A fixed rate contributes one direct constraint without duplicate rows.
    P = pdvar(2, {[0 1]}, "symmetric", RateBounds=[2 2]);
    D = rhodiff(P);

    C = D <= 0;

    testCase.verifyEqual(size(D.coeffs(1)), [1 1]);
    testCase.verifyEqual(D.NumRateRows, 1);
    testCase.verifyEqual(numel(C.Constraints), 1);
    veriConCel(testCase, C);
end

function test_tensor_rate_bounds_create_constraint_rate(testCase)
    % Tensor rate bounds create one constraint per rate vertex and coefficient.
    rb = [-1 1; -2 2];
    P = pdvar(2, {[0 1], [0 1]}, "symmetric", RateBounds=rb);
    D = rhodiff(P);

    C = D <= 0;

    testCase.verifyEqual(D.NumRateRows, 4);
    testCase.verifyEqual(size(D.coeffs([1 1])), [4 4]);
    testCase.verifyEqual(numel(C.Constraints), 16);
    veriConCel(testCase, C);
end

function test_fixed_tensor_direction_contributes_two_distinct(testCase)
    % One fixed tensor direction contributes two distinct assembly rows.
    rb = [1 1; -3 5];
    P = pdvar(2, {[0 1], [10 12]}, "symmetric", ...
        Degree=[1 1], RateBounds=rb);
    D = rhodiff(P);

    C = D <= 0;

    testCase.verifyEqual(D.NumRateRows, 2);
    testCase.verifyEqual(size(D.coeffs([1 1])), [2 4]);
    testCase.verifyEqual(numel(C.Constraints), 8);
    veriConCel(testCase, C);
end

function test_residual_assembly_constrain_elevated_derivative_rate(testCase)
    % Residual assembly should constrain every elevated derivative rate row.
    P = pdvar(2, {[0 1]}, "symmetric");
    A = pdmat({[0 1]}, {[-1 0; 0 -2], [-2 0; 0 -3]}, Degree=1);
    R = A' * P + P * A + rhodiff(P, [-1 1]);

    C = R <= 0;

    testCase.verifyEqual(R.RateBounds, [-1 1]);
    testCase.verifyEqual(R.Degree, 2);
    testCase.verifyEqual(size(R.coeffs(1)), [2 3]);
    testCase.verifyEqual(numel(C.Constraints), 6);
    veriConCel(testCase, C);
end

function test_direct_assembly_constrains_rate_row_cubic(testCase)
    % Direct assembly constrains every rate row of a cubic residual.
    P = pdvar(2, {[0 1]}, "symmetric", Degree=2);
    A = pdmat({[0 1]}, {[-1 0; 0 -2], [-2 0; 0 -3]}, Degree=1);
    R = A' * P + P * A + rhodiff(P, [-1 1]);

    C = R <= 0;

    testCase.verifyEqual(R.Degree, 3);
    testCase.verifyEqual(size(R.coeffs(1)), [2 4]);
    testCase.verifyEqual(numel(C.Constraints), 8);
    veriConCel(testCase, C);
end

function test_rectangular_structurally_full_square_residuals(testCase)
    % Rectangular and structurally full square residuals use vector inequalities.
    rectangular = pdvar(3, 2, {[0 1]}, "full", Degree=0);
    rect = consWitSinWar(testCase, @() rectangular >= 0);
    testCase.verifyEqual(numel(rect.Constraints), 1);
    veriVecCon(testCase, rect, 6);

    fullSquare = pdvar(2, {[0 1]}, "full", Degree=0);
    square = consWitSinWar(testCase, @() fullSquare <= 0);
    fullCoeffs = fullSquare.coeffs(1);
    assign(fullCoeffs{1}, [-1 -2; -3 -4]);
    testCase.verifyGreaterThan(check(square.Constraints{1}), 0);
    veriVecCon(testCase, square, 4);

    symmetric = pdvar(2, {[0 1]}, "symmetric");
    testCase.verifyWarningFree(@() symmetric >= 0);
    symmetricLmi = symmetric >= 0;
    symmetricMeta = struct(symmetricLmi.Constraints{1});
    testCase.verifySize(symmetricMeta.List{1}, [2 2]);

    % The numeric tolerance is inclusive at exactly 1e-10.
    atTol = internalPdvar({[0 1]}, [2 2], 0, ...
        {{[0 1e-10; 0 0]}}, [], "test-at-tolerance");
    aboveTol = internalPdvar({[0 1]}, [2 2], 0, ...
        {{[0 1.0001e-10; 0 0]}}, [], "test-above-tolerance");
    testCase.verifyWarningFree(@() pdlmi(atTol, ">="));
    consWitSinWar(testCase, @() pdlmi(aboveTol, ">="));
end

function test_later_offending_coefficient_changes_constraint(testCase)
    % A later offending coefficient changes every constraint in the wrapper.
    first = sdpvar(2, 2, 'symmetric');
    later = sdpvar(2, 2, 'full');
    acrossCells = internalPdvar({[0 1 2]}, [2 2], 0, ...
        {{first}, {later}}, [], "test-later-cell");
    cellwise = consWitSinWar(testCase, @() acrossCells >= 0);
    assign(first, [1 2; 2 1]);
    assign(later, [1 2; 3 4]);

    testCase.verifyEqual(numel(cellwise.Constraints), 2);
    testCase.verifyGreaterThan(check(cellwise.Constraints{1}), 0, ...
        "The earlier indefinite coefficient must be constrained entry-wise.");
    veriVecCon(testCase, cellwise, 4);

    earlyRow = sdpvar(2, 2, 'symmetric');
    lateRow = sdpvar(2, 2, 'full');
    acrossRows = internalPdvar({[0 1]}, [2 2], 0, ...
        {{earlyRow; lateRow}}, [-1 1], "test-later-rate-row");
    ratewise = consWitSinWar(testCase, @() acrossRows >= 0);
    assign(earlyRow, [1 2; 2 1]);
    assign(lateRow, [1 2; 3 4]);

    testCase.verifyEqual(numel(ratewise.Constraints), 2);
    testCase.verifyGreaterThan(check(ratewise.Constraints{1}), 0);
    veriVecCon(testCase, ratewise, 4);
end

function test_direct_elevated_paths_cell_entry_derivative(testCase)
    % Direct and elevated paths retain every cell, entry, and derivative row.
    V = pdvar(3, 2, {[0 1 2]}, "full", Degree=1);
    direct = consWitSinWar(testCase, @() V >= 0);
    polya = consWitSinWar(testCase, @() direct.usePolya(2));
    D = rhodiff(V, [-1 1]);
    rate = consWitSinWar(testCase, @() D <= 0);
    ratePolya = consWitSinWar(testCase, @() rate.usePolya());

    testCase.verifyEqual(numel(direct.Constraints), 2 * 2);
    testCase.verifyEqual(numel(polya.Constraints), 2 * 4);
    testCase.verifyEqual(size(D.coeffs(1)), [2 1]);
    testCase.verifyEqual(numel(rate.Constraints), 2 * 2);
    testCase.verifyEqual(numel(ratePolya.Constraints), 2 * 2 * 2);
    veriVecCon(testCase, direct, 6);
    veriVecCon(testCase, polya, 6);
    veriVecCon(testCase, rate, 6);
    veriVecCon(testCase, ratePolya, 6);

    % Option validation precedes classification, so failed construction is silent.
    lastwarn("");
    testCase.verifyError(@() pdlmi(V, ">=", ...
        UsePutinar=true, PutinarOrder=-1), "pdlmi:InvalidPutinarOrder");
    [~, warnId] = lastwarn;
    testCase.verifyEmpty(warnId);
end

function test_full_variable_can_still_form_lmi(testCase)
    % A full variable can still form an LMI after explicit symmetrization.
    P = pdvar(2, {[0 1]}, "full");

    C = (P + P') <= 0;

    testCase.verifyClass(C, "pdlmi");
    testCase.verifyEqual(numel(C.Constraints), 2);
    veriConCel(testCase, C);
end

function test_supplying_only_degree_accepted_but_make(testCase)
    % Supplying only the degree is accepted but must make the implicit mode visible.
    P = pdvar(1, {[0 1]});
    warnId = "pdlmi:ImplicitUsePolya";

    testCase.verifyWarning(@() pdlmi(P, "<=", PolyaDegree=2), warnId);
    testCase.verifyWarning(@() pdlmi(P, "<=", "PolyaDegree", 2), warnId);
    testCase.verifyWarning(@() pdlmi(P, "<=", PolyaDegree=0), warnId);

    named = callWarningOff(@() pdlmi(P, "<=", PolyaDegree=2), warnId);
    paired = callWarningOff(@() pdlmi(P, "<=", "PolyaDegree", 2), warnId);
    zero = callWarningOff(@() pdlmi(P, "<=", PolyaDegree=0), warnId);
    verifyPolya(testCase, named, 2, 4);
    verifyPolya(testCase, paired, 2, 4);
    verifyPolya(testCase, zero, 0, 2);
end

function test_retired_names_out_source_text_while(testCase)
    % Keep the retired names out of source text while guarding the API boundary.
    P = pdvar(1, {[0 1]}, Degree=1);
    C = P >= 0;
    oldOption = "Use" + "Relax" + "Lemma";
    oldMethod = "apply" + "Relax" + "Lemma";

    testCase.verifyError(@() pdlmi(P, "<=", oldOption, true), ...
        "pdlmi:UnknownOption");
    testCase.verifyFalse(isprop(C, oldOption));
    testCase.verifyFalse(any(string(methods(C)) == oldMethod));
end


function test_relation_validation(testCase)
    P = pdvar(1, {[0 1]});

    lower = pdlmi(P, '<=');
    upper = pdlmi(P, ">=");

    testCase.verifyEqual(lower.Relation, "<=");
    testCase.verifyEqual(upper.Relation, ">=");
    testCase.verifyError(@() pdlmi(P, char('<=', '>=')), ...
        "pdlmi:InvalidRelation");
    testCase.verifyError(@() pdlmi(P, "="), "pdlmi:InvalidRelation");
end

function test_parser_errors_distinguish_malformed_syntax(testCase)
    % Parser errors distinguish malformed syntax, duplicates, and unknown names.
    P = pdvar(1, {[0 1]});
    charMatrix = char('UsePolya', 'Unknown');

    testCase.verifyError(@() pdlmi(P, "<=", charMatrix), ...
        "pdlmi:InvalidOptions");
    testCase.verifyError(@() pdlmi(P, "<=", "Unknown", 1), ...
        "pdlmi:UnknownOption");
    testCase.verifyError(@() pdlmi(P, "<=", "UsePolya", "Unknown"), ...
        "pdlmi:UnknownOption");
    testCase.verifyError(@() pdlmi(P, "<=", ...
        "UsePolya", true, "UsePolya"), "pdlmi:DuplicateOption");
    testCase.verifyError(@() pdlmi(P, "<=", ...
        "PolyaDegree", "UsePolya"), "pdlmi:InvalidOptions");
end

function test_direct_assembly_has_same_public_structure(testCase)
    % Direct assembly has the same public structure in all validation modes.
    P = pdvar(2, [0 1], "symmetric", Degree=1);

    implicit = pdlmi(P, ">=");
    fast = pdlmi(P, ">=", ValidationMode="FAST");
    strict = pdlmi(P, ">=", ValidationMode='Strict');

    veriSamPubAss(testCase, implicit, fast);
    veriSamPubAss(testCase, fast, strict);
    testCase.verifyFalse(isprop(implicit, "ValidationMode"));
end

function test_constructor_mode_failures_owned_by_pdlmi(testCase)
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

function test_apply_method_parses_own_trailing_mode(testCase)
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

function test_apply_calls_reject_missing_malformed_transient(testCase)
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

function test_constructor_selectors_apply_methods_reject_malformed(testCase)
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

function test_later_cell_or_rate_row_selects(testCase)
    % A later cell or rate row selects entry-wise mode for the whole wrapper.
    first = sdpvar(2, 2, 'symmetric');
    later = sdpvar(2, 2, 'full');
    acrossCells = validation_mode_internalPdvar({{first}, {later}}, [], ...
        "test-later-cell");
    for mode = ["fast", "strict"]
        C = constructElementwise(@() pdlmi(acrossCells, ">=", ...
            ValidationMode=mode));
        veriAllVecCon(testCase, C, 4);
    end

    earlyRow = sdpvar(2, 2, 'symmetric');
    lateRow = sdpvar(2, 2, 'full');
    acrossRows = validation_mode_internalPdvar({{earlyRow; lateRow}}, [-1 1], ...
        "test-later-rate-row");
    for mode = ["fast", "strict"]
        C = constructElementwise(@() pdlmi(acrossRows, ">=", ...
            ValidationMode=mode));
        veriAllVecCon(testCase, C, 4);
    end
end

function test_strict_assembly_diagnoses_later_cell_tensor(testCase)
    % Strict assembly diagnoses later-cell tensor, rate-row, and payload drift.
    first = sdpvar(2, 2, 'symmetric');
    later = sdpvar(2, 2, 'symmetric');

    wrongCount = validation_mode_internalPdvar({{first}, {later, later}}, [], ...
        "test-wrong-count", "fast");
    testCase.verifyError(@() pdlmi(wrongCount, ">=", ...
        ValidationMode="strict"), "pdlmi:InvalidAssemblyData");

    mixedRows = validation_mode_internalPdvar({{first}, {later; later}}, [-1 1], ...
        "test-mixed-rate-layout", "fast");
    testCase.verifyError(@() pdlmi(mixedRows, ">=", ...
        ValidationMode="strict"), "pdlmi:InvalidAssemblyData");

    wrongSize = validation_mode_internalPdvar({{first}, {sdpvar(1, 1)}}, [], ...
        "test-wrong-payload-size", "fast");
    testCase.verifyError(@() pdlmi(wrongSize, ">=", ...
        ValidationMode="strict"), "pdlmi:InvalidAssemblyData");
end

function verifyPolya(testCase, C, degree, count)
    degree = expandExpected(degree, C.Residual.npar());
    zero = zeros(1, C.Residual.npar());
    testCase.verifyTrue(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, degree);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, zero);
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, zero);
    testCase.verifyEqual(numel(C.Constraints), count);
    veriConCel(testCase, C);
end

function out = callWarningOff(fun, warnId)
    % Construct once without duplicating the warning already asserted above.
    state = warning("query", warnId);
    cleanup = onCleanup(@() warning(state.state, warnId)); %#ok<NASGU>
    warning("off", warnId);
    out = fun();
end

function out = consWitSinWar(testCase, fun)
    % Capture the successful wrapper and assert one emitted dispatch warning.
    lastwarn("");
    txt = evalc('out = fun();');
    [~, warnId] = lastwarn;
    testCase.verifyEqual(string(warnId), "pdlmi:ElementwiseInequality");
    testCase.verifyEqual(count(string(txt), ...
        "The residual is non-square or has a non-Hermitian coefficient"), 1);
end

function veriVecCon(testCase, C, nEntry)
    % Entry-wise assembly stores one column-vector inequality per coefficient.
    for k = 1:numel(C.Constraints)
        metadata = struct(C.Constraints{k});
        testCase.verifySize(metadata.List{1}, [nEntry 1]);
    end
end

function obj = internalPdvar(grid, matrixSize, degree, vals, rb, summary)
    % Build targeted coefficient trees that public continuous allocation cannot express.
    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {grid}, ...
        "MatrixSize", matrixSize, ...
        "Degree", degree, ...
        "LocalValues", {vals}, ...
        "IsContinuous", false, ...
        "ContainsDecision", any(cellfun(@(x) isa(x, "sdpvar"), flatten(vals))), ...
        "RateBounds", rb, ...
        "SourceSummary", summary);
    obj = pdvar(init);
end

function veriConCel(testCase, C)
    testCase.verifyTrue(iscell(C.Constraints));
    testCase.verifySize(C.Constraints, [numel(C.Constraints), 1]);
    for k = 1:numel(C.Constraints)
        testCase.verifyTrue(isa(C.Constraints{k}, "constraint"));
    end
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

function obj = validation_mode_internalPdvar(vals, rb, summary, validationMode)
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
function value = expandExpected(value, nPar)
    % Expand scalar shorthand only in test expectations.
    if isscalar(value)
        value = repmat(value, 1, nPar);
    else
        value = reshape(value, 1, []);
    end
end

function out = flatten(vals)
    % Return nested coefficient payloads as a flat cell for fixture metadata.
    out = {};
    for k = 1:numel(vals)
        if iscell(vals{k})
            out = [out, flatten(vals{k})]; %#ok<AGROW>
        else
            out{end + 1} = vals{k}; %#ok<AGROW>
        end
    end
end

function test_complete_direct_constraint_expression_order(testCase)
    P=pdvar(2,[0 2 5],Degree=2,RateBounds=[-2 3]);
    R=rhodiff(P);
    for sign=[-1 1]
        if sign==1, wrapper=R>=0; else, wrapper=R<=0; end
        testCase.verifyEqual(numel(wrapper.Constraints),8);
        index=0;
        for cellIndex=1:2
            c=R.coeffs(cellIndex);
            for row=1:2
                for k=1:2
                    index=index+1;
                    if index>numel(wrapper.Constraints), continue; end
                    testCase.verifyEqual(is(wrapper.Constraints{index},'sdp'),1);
                    tests.infrastructure.verify_expr(testCase,sdpvar(wrapper.Constraints{index}),sign*c{row,k});
                end
            end
        end
        testCase.verifyEqual(numel(wrapper.Constraints),index);
    end
end
