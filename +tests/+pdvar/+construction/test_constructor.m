function tests = test_constructor
    % Behavioral regressions for pdvar.constructor.
    tests = functiontests(localfunctions);
end

function test_rectangular_decisions_share_both_zero_degree_axes(testCase)
    % Only the middle tensor axis allocates new controls; faces reuse full matrices.
    P = pdvar(2,3,{[0 2 5],[-3 1 6],[7 8 12]},'full',Degree=[0 3 0]);
    vars = [];
    for j = 1:2
        ref = P.coeffs([1 j 1]);
        for i = 1:2
            for k = 1:2
                tests.infrastructure.verify_expr(testCase,P.coeffs([i j k]),ref);
            end
        end
        for k = 1:4
            testCase.verifyEqual(size(ref{k}),[2 3]);
            vars = [vars getvariables(ref{k})]; %#ok<AGROW>
        end
    end
    left = P.coeffs([1 1 1]); right = P.coeffs([2 2 2]);
    tests.infrastructure.verify_expr(testCase,left{4},right{1});
    testCase.verifyEqual(numel(unique(vars)),6*7);
end

function setupOnce(~)
    yalmip("clear");
end

function test_square_forms_follow_sdpvar_s_symmetric(testCase)
    % Square forms follow sdpvar's symmetric default; rectangular is full.
    Ps = pdvar(2, {[0 1]});
    Pss = pdvar(2, 2, {[0 1]});
    Pf = pdvar(2, 3, {[0 1]});

    testCase.verifyEqual(size(Ps), [2 2]);
    testCase.verifyEqual(size(Pss), [2 2]);
    testCase.verifyEqual(size(Pf), [2 3]);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Ps))), 3);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Pss))), 3);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Pf))), 6);
end

function test_explicit_flags_let_square_matrices_choose(testCase)
    % Explicit flags let square matrices choose full or symmetric payloads.
    Pf = pdvar(2, 2, {[0 1]}, "full");
    Ps = pdvar(2, 2, {[0 1]}, "symmetric");

    testCase.verifyEqual(numel(getvariables(firstCoeff(Pf))), 4);
    testCase.verifyEqual(numel(getvariables(firstCoeff(Ps))), 3);
    testCase.verifyError(@() pdvar(2, 3, {[0 1]}, "symmetric"), ...
        "pdvar:InvalidStructure");
end

function test_public_constructor_original_degree_default(testCase)
    % The public constructor keeps the original degree-one default.
    P = pdvar(2, {[0 1 2]});
    Q = pdvar(2, {[0 1 2]}, Degree=1);

    testCase.verifyEqual(P.Degree, 1);
    testCase.verifyEqual(Q.Degree, 1);
    testCase.verifyTrue(P.IsContinuous);
    testCase.verifyTrue(P.ContainsDecision);
    testCase.verifyEqual(P.SourceSummary, "decision");
end

function test_degree_zero_variables_parameter_independent_stored(testCase)
    % Degree-zero variables are parameter-independent on the stored grid.
    P = pdvar(1, {[0 1 2 3]}, Degree=0);
    c1 = P.coeffs(1);
    c2 = P.coeffs(2);
    c3 = P.coeffs(3);

    testCase.verifyEqual(P.Degree, 0);
    testCase.verifyEqual(numel(c1), 1);
    verifySameVars(testCase, c1{1}, c2{1});
    verifySameVars(testCase, c1{1}, c3{1});
end

function test_constructor_created_decisions_support_nonnegative(testCase)
    % Constructor-created decisions support every nonnegative scalar degree.
    P2 = pdvar(1, {[0 1]}, Degree=2);
    P4 = pdvar(1, {[0 1]}, Degree=4);

    testCase.verifyEqual(P2.Degree, 2);
    testCase.verifyEqual(P2.ncoeff(), 3);
    testCase.verifyEqual(numel(P2.coeffs(1)), 3);
    testCase.verifyEqual(P4.Degree, 4);
    testCase.verifyEqual(P4.ncoeff(), 5);
    testCase.verifyEqual(numel(P4.coeffs(1)), 5);
end

function test_plain_numeric_vector_accepted_as_parameter(testCase)
    % A plain numeric vector is accepted as the one-parameter grid.
    P = pdvar(2, [0 1], Degree=0);

    testCase.verifyEqual(P.Degree, 0);
    testCase.verifyEqual(P.GridInfo.Vectors, {[0 1]});
    testCase.verifyEqual(P.npar(), 1);
end

function test_degree_accepts_ell_vectors_reports_owner(testCase)
    % Degree accepts ell-vectors and reports owner-specific shape failures.
    grid = {[0 1], [10 20]};
    row = pdvar(1, grid, Degree=[0 2]);
    column = pdvar(1, grid, Degree=[0; 2]);
    testCase.verifyEqual(row.Degree, [0 2]);
    testCase.verifyEqual(column.Degree, [0 2]);

    bad = {[], [1 2 3], [1 2; 3 4], -1, 1.5, NaN, Inf, "two"};
    for k = 1:numel(bad)
        testCase.verifyError(@() pdvar(2, grid, Degree=bad{k}), ...
            "pdvar:InvalidDegree");
    end

    try
        pdvar(2, grid, Degree=[1 2 3]);
        error("tests:ExpectedError", "The invalid degree did not fail.");
    catch err
    end
    testCase.verifyEqual(string(err.identifier), "pdvar:InvalidDegree");
    testCase.verifyEqual(string(err.message), ...
        "Degree must be a finite nonnegative integer scalar or an ell-element vector.");
end

function test_explicit_multidimensional_scalar_shorthand_warns(testCase)
    % Explicit multidimensional scalar shorthand warns; defaults and 1-D do not.
    grid = {[0 1], [10 20]};
    explicit = constructWithWarning(testCase, ...
        @() pdvar(1, grid, Degree=1), ...
        "pdvar:ScalarDegreeExpansion");
    default = constructWarningFree(testCase, @() pdvar(1, grid));
    oneDimensional = constructWarningFree(testCase, ...
        @() pdvar(1, [0 1], Degree=1));

    testCase.verifyEqual(explicit.Degree, [1 1]);
    testCase.verifyEqual(default.Degree, [1 1]);
    testCase.verifyEqual(oneDimensional.Degree, 1);
end

function test_adjacent_scalar_cells_share_same_boundary(testCase)
    % Adjacent scalar cells share the same boundary coefficient handle.
    P = pdvar(1, {[0 1 2]});
    left = P.coeffs(1);
    right = P.coeffs(2);

    verifySameVars(testCase, left{2}, right{1});
end

function test_two_quadratic_cells_share_only_common(testCase)
    % Two quadratic cells share only their common endpoint control handle.
    P = pdvar(1, {[0 1 2]}, Degree=2);
    left = P.coeffs(1);
    right = P.coeffs(2);
    leftIds = cellfun(@getvariables, left);
    rightIds = cellfun(@getvariables, right);

    testCase.verifyEqual(numel(left), 3);
    testCase.verifyEqual(numel(right), 3);
    testCase.verifyEqual(numel(unique(leftIds)), 3);
    testCase.verifyEqual(numel(unique(rightIds)), 3);
    testCase.verifyEqual(numel(unique([leftIds rightIds])), 5);
    verifySameVars(testCase, left{3}, right{1});
    testCase.verifyEmpty(intersect(leftIds(1:2), rightIds(2:3)));
end

function test_tensor_labels_combrows_order_0_0(testCase)
    % Tensor labels use combRows order: [0 0], [0 1], [1 0], [1 1].
    P = pdvar(1, {[0 1 2], [10 20]});
    c11 = P.coeffs([1 1]);
    c21 = P.coeffs([2 1]);

    testCase.verifyEqual(numel(c11), 4);
    verifySameVars(testCase, c11{3}, c21{1});
    verifySameVars(testCase, c11{4}, c21{2});
end

function test_adjacent_quadratic_tensor_cells_reuse_control(testCase)
    % Adjacent quadratic tensor cells reuse every control on their full face.
    P = pdvar(1, {[0 1 2], [10 20 30]}, Degree=[2 2]);
    c11 = P.coeffs([1 1]);
    c21 = P.coeffs([2 1]);
    c12 = P.coeffs([1 2]);
    lbls = helper.combRows({0:2, 0:2});

    testCase.verifyEqual(P.ncoeff(), 9);
    testCase.verifyEqual(numel(c11), 9);
    for q = 0:2
        verifySameVars(testCase, c11{labelIndex(lbls, [2 q])}, ...
            c21{labelIndex(lbls, [0 q])});
        verifySameVars(testCase, c11{labelIndex(lbls, [q 2])}, ...
            c12{labelIndex(lbls, [q 0])});
    end

    center = getvariables(c11{labelIndex(lbls, [1 1])});
    testCase.verifyNotEqual(center, getvariables(c21{labelIndex(lbls, [1 1])}));
    testCase.verifyNotEqual(center, getvariables(c12{labelIndex(lbls, [1 1])}));
end

function test_degree_0_2_shares_complete_constant(testCase)
    % Degree [0 2] shares the complete constant axis and quadratic faces.
    P = pdvar(1, {[0 1 2], [10 20 30]}, Degree=[0 2]);
    c11 = P.coeffs([1 1]);
    c21 = P.coeffs([2 1]);
    c12 = P.coeffs([1 2]);
    c22 = P.coeffs([2 2]);

    testCase.verifyEqual(P.Degree, [0 2]);
    testCase.verifyEqual(P.ncoeff(), 3);
    for k = 1:3
        verifySameVars(testCase, c11{k}, c21{k});
        verifySameVars(testCase, c12{k}, c22{k});
    end
    verifySameVars(testCase, c11{3}, c12{1});

    vars = cellfun(@getvariables, [c11, c21, c12, c22]);
    testCase.verifyEqual(numel(unique(vars)), 5);
end

function test_constructor_ratebounds_metadata_outside_localvalues(testCase)
    % Constructor RateBounds remain metadata outside LocalValues.
    rb = [-1 2; -3 4];
    P = pdvar(1, {[0 1], [10 20]}, RateBounds=rb);

    testCase.verifyEqual(P.RateBounds, rb);
    testCase.verifyError(@() pdvar(1, {[0 1]}, RateBounds=[0 1; -1 1]), ...
        "pdbase:InvalidRateBounds");
    testCase.verifyError(@() pdvar(1, {[0 1]}, RateBounds=[1 -1]), ...
        "pdbase:InvalidRateBounds");
end

function test_public_parsing_rejects_missing_grids_malformed(testCase)
    % Public parsing rejects missing grids and malformed option sequences.
    testCase.verifyError(@() pdvar(1), "pdvar:InvalidInput");
    testCase.verifyError(@() pdvar(1, 2), "pdvar:InvalidInput");
    testCase.verifyError(@() pdvar(1, 2, 3), "pdvar:InvalidInput");
    testCase.verifyError(@() pdvar(1, [0 1], 7), ...
        "pdvar:InvalidOptions");
    testCase.verifyError(@() pdvar(1, [0 1], "Degree"), ...
        "pdvar:InvalidOptions");
    testCase.verifyError(@() pdvar(1, [0 1], ...
        "ValidationMode", "fast", "ValidationMode", "strict"), ...
        "pdvar:InvalidValidationMode");
    testCase.verifyError(@() pdvar(1, [0 1], ...
        "IsContinuous", true), "pdvar:UnsupportedOption");
    testCase.verifyError(@() pdvar(1, [0 1], "Unknown", 1), ...
        "pdvar:UnknownOption");
end

function test_mode_builds_same_shape_grid_degree(testCase)
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

function test_pdvar_owns_missing_malformed_validationmode(testCase)
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

function test_exact_recomputation_recognizes_continuous_slice(testCase)
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

function verifySameVars(testCase, lhs, rhs)
    % Shared coefficient handles should expose identical YALMIP variable IDs.
    testCase.verifyEqual(getvariables(lhs), getvariables(rhs));
end

function val = firstCoeff(obj)
    % Pull the first scalar-cell coefficient for compact constructor checks.
    coeffs = obj.coeffs(1);
    val = coeffs{1};
end

function idx = labelIndex(lbls, label)
    % Locate one tensor Bernstein label in the package-wide combRows order.
    idx = find(all(lbls == label, 2), 1);
end

function obj = constructWithWarning(testCase, fcn, warningId)
    % Capture the public scalar-expansion warning and retain the result.
    obj = [];
    testCase.verifyWarning(@construct, warningId);

    function construct
        obj = fcn();
    end
end

function obj = constructWarningFree(testCase, fcn)
    % Defaults and one-dimensional shorthand must remain warning-free.
    obj = [];
    testCase.verifyWarningFree(@construct);

    function construct
        obj = fcn();
    end
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
function test_anisotropic_face_edge_and_corner_identity(testCase)
    P=pdvar(2,{[0 2 5],[-3 1 7],[4 9 11]},'full',Degree=[2 3 2]);
    labels=tests.infrastructure.labels([2 3 2]);
    controls=containers.Map('KeyType','char','ValueType','any');
    allIds=[];
    cells=tests.infrastructure.labels([1 1 1])+1;
    for cellIndex=1:8
        subs=cells(cellIndex,:); c=P.coeffs(subs);
        for k=1:size(labels,1)
            key=sprintf('%d,%d,%d',(subs-1).*[2 3 2]+labels(k,:));
            ids=getvariables(c{k});
            testCase.verifyEqual(numel(ids),4);
            if isKey(controls,key)
                testCase.verifyEqual(ids,controls(key));
            else
                testCase.verifyEmpty(intersect(ids,allIds));
                controls(key)=ids;
                allIds=[allIds ids]; %#ok<AGROW>
            end
        end
    end
    testCase.verifyEqual(double(controls.Count),5*7*5);
    testCase.verifyEqual(numel(unique(allIds)),4*5*7*5);
end
