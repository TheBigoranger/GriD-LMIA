function tests = test_use_polya
    % Behavioral regressions for pdlmi.use_polya.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so constraint IDs stay local to this suite.
    yalmip("clear");
end

function test_bare_flags_name_value_forms_select(testCase)
    % Bare flags and Name=Value forms select the same elevation semantics.
    P = pdvar(2, {[0 1]}, "symmetric");

    bare = pdlmi(P, "<=", "UsePolya");
    named = pdlmi(P, "<=", UsePolya=true);
    mixed = pdlmi(P, "<=", "UsePolya", PolyaDegree=2);
    paired = pdlmi(P, "<=", "UsePolya", true, "PolyaDegree", 2);
    zero = pdlmi(P, "<=", UsePolya=true, PolyaDegree=0);

    verifyPolya(testCase, bare, 1, 3);
    verifyPolya(testCase, named, 1, 3);
    verifyPolya(testCase, mixed, 2, 4);
    verifyPolya(testCase, paired, 2, 4);
    verifyPolya(testCase, zero, 0, 2);
    testCase.verifyWarningFree(@() pdlmi(P, "<=", UsePolya=true));
end

function test_polya_option_interactions(testCase)
    P = pdvar(2, {[0 1]}, "symmetric");

    direct = pdlmi(P, "<=", UsePolya=false, PolyaDegree=0);

    verifyDefaults(testCase, direct);
    testCase.verifyEqual(numel(direct.Constraints), 2);
    testCase.verifyError(@() pdlmi(P, "<=", ...
        UsePolya=false, PolyaDegree=1), ...
        "pdlmi:ConflictingPolyaOptions");
end

function test_counts_include_cell_elevated_tensor_label(testCase)
    % Counts include every cell, elevated tensor label, and derivative rate row.
    grid = {[0 1 2], [10 20]};
    P = pdvar(1, grid, Degree=[1 1], RateBounds=[-1 1; -2 2]);

    tensor = pdlmi(P, ">=", "UsePolya", PolyaDegree=2);
    D = rhodiff(P);
    rate = pdlmi(D, "<=", "UsePolya");

    testCase.verifyEqual(tensor.Relation, ">=");
    testCase.verifyEqual(numel(tensor.Constraints), 2 * 1 * 4 ^ 2);
    testCase.verifyEqual(size(D.coeffs([1 1])), [4 4]);
    testCase.verifyEqual(numel(rate.Constraints), 2 * 4 * 3 ^ 2);
    veriConCel(testCase, tensor);
    veriConCel(testCase, rate);
end

function test_reapplying_degree_replaces_selection_rather_than(testCase)
    % Reapplying a degree replaces the selection rather than compounding it.
    P = pdvar(1, {[0 1]}, Degree=1);
    direct = P >= 0;

    one = direct.usePolya();
    two = one.usePolya(2);
    zero = two.usePolya(0);

    verifyDefaults(testCase, direct);
    verifyPolya(testCase, one, 1, 3);
    verifyPolya(testCase, two, 2, 4);
    verifyPolya(testCase, zero, 0, 2);
    testCase.verifyEqual(numel(one.Constraints), 3);
    testCase.verifyTrue(isequal(two.Residual, P));
    testCase.verifyEqual(two.Relation, ">=");
end


function test_elevation_can_certify_positive_polynomial_whose(testCase)
    % Elevation can certify a positive polynomial whose original middle coefficient is negative.
    P = pdvar(1, {[0 1]}, Degree=2);
    coeffs = P.coeffs(1);
    assigned = [1, -0.1, 1];
    for k = 1:numel(coeffs)
        assign(coeffs{k}, assigned(k));
    end

    direct = P >= 0;
    polya = direct.usePolya(1);
    elevatedObj = P.elevate(1);
    elevated = cellfun(@value, elevatedObj.LocalValues{1});
    directCheck = check(toYalmip(direct));
    polyaCheck = check(toYalmip(polya));

    testCase.verifyEqual(elevated, [1, 0.266666666666667, ...
        0.266666666666667, 1], AbsTol=1e-12);
    testCase.verifyLessThan(min(directCheck), 0);
    testCase.verifyGreaterThan(min(polyaCheck), 0);
end

function test_polya_degree_validation(testCase)
    P = pdvar(1, {[0 1]});
    C = P >= 0;
    badMethod = {-1, 0.5, Inf, NaN, "one", [1 2]};
    badConstructor = {-1, 0.5, Inf, NaN, [1 2]};

    for k = 1:numel(badMethod)
        testCase.verifyError(@() C.usePolya(badMethod{k}), ...
            "pdlmi:InvalidPolyaDegree");
    end
    for k = 1:numel(badConstructor)
        testCase.verifyError(@() pdlmi(P, "<=", ...
            UsePolya=true, PolyaDegree=badConstructor{k}), ...
            "pdlmi:InvalidPolyaDegree");
    end
    testCase.verifyError(@() pdlmi(P, "<=", ...
        UsePolya=true, PolyaDegree="one"), "pdlmi:UnknownOption");
end

function test_direction_wise_increments_tensor_counts_replace(testCase)
    % Direction-wise increments use tensor counts and replace prior levels.
    grid = {[0 1], [10 20]};
    P = pdvar(1, grid, Degree=[1 3], RateBounds=[-1 2; -3 5]);
    direct = P >= 0;
    vector = direct.usePolya([1 0]);
    bare = direct.usePolya();
    replaced = vector.usePolya([0 2]);

    verifyDefaults(testCase, direct);
    verifyPolya(testCase, vector, [1 0], prod([2 3] + 1));
    verifyPolya(testCase, bare, [1 1], prod([2 4] + 1));
    verifyPolya(testCase, replaced, [0 2], prod([1 5] + 1));
    testCase.verifyTrue(isequal(replaced.Residual, P));

    D = rhodiff(P);
    rateDirect = D <= 0;
    ratePolya = rateDirect.usePolya([0 1]);
    testCase.verifyEqual(D.Degree, [1 3]);
    testCase.verifySize(D.coeffs([1 1]), [4 8]);
    testCase.verifyEqual(numel(rateDirect.Constraints), 4 * 8);
    testCase.verifyEqual(numel(ratePolya.Constraints), 4 * 2 * 5);
end

function test_tensor_p_lya_accepts_ell_vectors(testCase)
    % Tensor Pólya accepts ell-vectors and rejects every other shape.
    P = pdvar(1, {[0 1], [10 20]}, Degree=[1 2]);
    direct = P >= 0;
    accepted = direct.usePolya([0; 2]);
    testCase.verifyEqual(accepted.PolyaDegree, [0 2]);

    bad = {[], [1 2 3], [1 2; 3 4], -1, 0.5, Inf, NaN};
    for k = 1:numel(bad)
        testCase.verifyError(@() direct.usePolya(bad{k}), ...
            "pdlmi:InvalidPolyaDegree");
        testCase.verifyError(@() pdlmi(P, ">=", ...
            UsePolya=true, PolyaDegree=bad{k}), ...
            "pdlmi:InvalidPolyaDegree");
    end
    testCase.verifyError(@() direct.usePolya("one"), ...
        "pdlmi:InvalidPolyaDegree");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        UsePolya=true, PolyaDegree="one"), "pdlmi:UnknownOption");
end

function verifyDefaults(testCase, C)
    zero = zeros(1, C.Residual.npar());
    testCase.verifyFalse(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, zero);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, zero);
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, zero);
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

function veriConCel(testCase, C)
    testCase.verifyTrue(iscell(C.Constraints));
    testCase.verifySize(C.Constraints, [numel(C.Constraints), 1]);
    for k = 1:numel(C.Constraints)
        testCase.verifyTrue(isa(C.Constraints{k}, "constraint"));
    end
end
function value = expandExpected(value, nPar)
    % Expand scalar shorthand only in test expectations.
    if isscalar(value)
        value = repmat(value, 1, nPar);
    else
        value = reshape(value, 1, []);
    end
end

function test_complete_elevated_expression_order(testCase)
    P=pdvar(2,[0 2 5],Degree=2,RateBounds=[-2 3]);
    R=rhodiff(P);
    direct=R<=0;
    wrapper=direct.usePolya(2);
    index=0;
    for cellIndex=1:2
        expected=tests.infrastructure.elevate(R.coeffs(cellIndex),1,3);
        for row=1:2
            for k=1:4
                index=index+1;
                tests.infrastructure.verify_expr(testCase,sdpvar(wrapper.Constraints{index}),-expected{row,k});
            end
        end
    end
    testCase.verifyEqual(numel(wrapper.Constraints),index);
end

function test_anisotropic_tensor_fixed_rate_complete_expression_order(testCase)
    % Independent elevation checks every rectangular entry and fixed-rate cell.
    state = warning('off', 'pdlmi:ElementwiseInequality');
    cleanup = onCleanup(@() warning(state)); %#ok<NASGU>
    P = pdvar(2, 1, {[0 1 4], [-2 0 3]}, 'full', ...
        Degree=[0 2], RateBounds=[2 2; -1 -1]);
    R = [2 -1; 3 4] * rhodiff(P) + [5; -7];
    wrapper = usePolya(R <= 0, [1 2]);
    index = 0;
    for i = 1:2
        for j = 1:2
            expected = tests.infrastructure.elevate(R.coeffs([i j]), [0 2], [1 4]);
            for k = 1:10
                index = index + 1;
                tests.infrastructure.verify_expr(testCase, ...
                    sdpvar(wrapper.Constraints{index}), -expected{k}(:));
            end
        end
    end
    testCase.verifyEqual(numel(wrapper.Constraints), index);
    testCase.verifyEqual(wrapper.Residual.NumRateRows, 1);
end
