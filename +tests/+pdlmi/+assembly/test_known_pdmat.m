function tests = test_known_pdmat
    % Behavioral regressions for pdlmi.known_pdmat.
    tests = functiontests(localfunctions);
end

function setup(~)
    % Keep warning and YALMIP state local to each known-certificate test.
    yalmip("clear");
    lastwarn("");
end

function test_numeric_pdmat_comparisons_return_wrappers_equality(testCase)
    % Numeric and pdmat comparisons return wrappers; equality remains excluded.
    A = pdmat([0 1], {1, 2}, Degree=1);
    testCase.verifyClass(A >= 0, "pdlmi");
    testCase.verifyClass(3 >= A, "pdlmi");
    testCase.verifyClass(A <= 3, "pdlmi");
    testCase.verifyError(@() pdlmi(A, "=="), ...
        "pdlmi:UnsupportedPdmatEquality");

    exactOnly = pdmat([0 1], @(rho) rho);
    testCase.verifyError(@() pdlmi(exactOnly, ">="), ...
        "pdlmi:MissingCoefficientEvidence");
end

function test_direct_p_lya_reduce_all_known(testCase)
    % Direct and Pólya reduce all known coefficients and rate rows to one logical.
    positive = pdmat([0 1], {{1, 2; 3, 4}}, ...
        Degree=1, RateBounds=[-1 2]);
    negative = -positive;

    testCase.verifyTrue(toYalmip(positive >= 0));
    testCase.verifyTrue(toYalmip(negative <= 0));
    positiveLmi = positive >= 0;
    negativeLmi = negative <= 0;
    testCase.verifyTrue(toYalmip(positiveLmi.usePolya(2)));
    testCase.verifyTrue(toYalmip(negativeLmi.usePolya(1)));
end

function test_single_false_tensor_rate_coefficient_fail(testCase)
    % A single false tensor/rate coefficient must fail the reduced certificate.
    rb = [-1 2; -3 4];
    leaf = repmat({eye(2)}, 4, 4);
    A = pdmat({[0 1], [10 20]}, {{leaf}}, ...
        Degree=[1 1], RateBounds=rb);

    testCase.verifyTrue(toYalmip(A >= 0));
    leaf{4, 4} = -eye(2);
    B = pdmat({[0 1], [10 20]}, {{leaf}}, ...
        Degree=[1 1], RateBounds=rb);
    verifyInconclusive(testCase, @() toYalmip(B >= 0));
end

function test_helper_observe_deferred_warning_even_if(testCase)
    % The helper should observe the deferred warning even if callers mute it.
    warnId = "pdlmi:InconclusiveCertificate";
    state = warning("query", warnId);
    cleanup = onCleanup(@() warning(state.state, warnId)); %#ok<NASGU>
    warning("off", warnId);

    verifyInconclusive(testCase, @() toYalmip(constantPdmat(-1) >= 0));

    testCase.verifyEqual(string(warning("query", warnId).state), "off");
end

function test_known_tensor_coefficients_vector_degree_state(testCase)
    % Known tensor coefficients retain vector degree state through Pólya.
    grid = {[0 1], [10 20]};
    values = repmat({eye(2)}, 2, 4);
    A = pdmat(grid, values, Degree=[1 3]);

    direct = A >= 0;
    polya = direct.usePolya([1 0]);

    testCase.verifyTrue(toYalmip(direct));
    testCase.verifyTrue(toYalmip(polya));
    testCase.verifyEqual(direct.PolyaDegree, [0 0]);
    testCase.verifyEqual(polya.PolyaDegree, [1 0]);
    testCase.verifyTrue(isequal(polya.Residual, A));
end

function test_absolute_1_e_10_boundary_inclusive(testCase)
    % The absolute 1e-10 boundary is inclusive in both scalar directions.
    testCase.verifyTrue(toYalmip(constantPdmat(-1e-10) >= 0));
    testCase.verifyTrue(toYalmip(constantPdmat(1e-10) <= 0));
    verifyInconclusive(testCase, @() toYalmip( ...
        constantPdmat(-1.0001e-10) >= 0));
    verifyInconclusive(testCase, @() toYalmip( ...
        constantPdmat(1.0001e-10) <= 0));

    % A harmless skew below classification tolerance is symmetrized for eig.
    M = [1, 0.75e-10; 0, 1];
    A = pdmat([0 1], {{M}}, Degree=0);
    testCase.verifyWarningFree(@() pdlmi(A, ">="));
    testCase.verifyTrue(toYalmip(A >= 0));

    state = warning("query", "pdlmi:ElementwiseInequality");
    cleanup = onCleanup(@() warning(state.state, ...
        "pdlmi:ElementwiseInequality")); %#ok<NASGU>
    warning("off", "pdlmi:ElementwiseInequality");
    atTolRow = pdmat([0 1], {{[-1e-10, 2]}}, Degree=0);
    outsideRow = pdmat([0 1], {{[-1.0001e-10, 2]}}, Degree=0);
    testCase.verifyTrue(toYalmip(atTolRow >= 0));
    outsideCert = outsideRow >= 0;
    verifyInconclusive(testCase, @() toYalmip(outsideCert));
end

function test_rectangular_known_residual_exercises_successful(testCase)
    % A rectangular known residual exercises the successful entry-wise <= path.
    A = pdmat([0 1], {{[-1 -2]}}, Degree=0);
    warnId = "pdlmi:ElementwiseInequality";

    testCase.verifyWarning(@() A <= 0, char(warnId));
    state = warning("query", warnId);
    cleanup = onCleanup(@() warning(state.state, warnId)); %#ok<NASGU>
    warning("off", warnId);
    testCase.verifyTrue(toYalmip(A <= 0));
end

function test_polynomial_stays_positive_although_middle_bernstein(testCase)
    % The polynomial stays positive although its middle Bernstein coefficient fails.
    A = pdmat([0 1], {1, -0.1, 1}, Degree=2);
    testCase.verifyWarningFree(@() A >= 0);
    direct = A >= 0;
    testCase.verifyGreaterThan(A.evaluate(0.5), 0);

    verifyInconclusive(testCase, @() toYalmip(direct));
    testCase.verifyTrue(toYalmip(direct.usePolya(1)));

    trueCert = constantPdmat(1) >= 0;
    testCase.verifyWarningFree(@() toYalmip(trueCert));
    testCase.verifyTrue(toYalmip(trueCert));
end

function test_scalar_matrix_logical_coefficients_class_gated(testCase)
    % Scalar and matrix logical coefficients remain class-gated as pdvar.
    values = {1, eye(2)};
    for k = 1:numel(values)
        P = internalNumericPdvar(values{k});
        C = pdlmi(P, ">=");

        lastwarn("");
        F = toYalmip(C);
        [~, warnId] = lastwarn;

        testCase.verifyNotEqual(class(F), "missing");
        testCase.verifyEmpty(warnId);
    end
end

function test_known_gram_routes_produce_yalmip_constraints(testCase)
    % Known Gram routes produce YALMIP constraints with auxiliary decisions.
    A = pdmat([0 1], @(rho) 1 + 0 * rho, Degree=4);
    direct = A >= 0;
    putinar = direct.usePutinar(2);
    sparsePutinar = direct.useSpPut(2, 2);
    sparse = direct.useSpBox(2, 2);
    full = direct.useFullBox(2);
    widthOne = direct.useSpBox(1, 2);
    dense = direct.useSpBox(3, 2);
    sparsePutinarDense = direct.useSpPut(3, 2);

    verifyGram(testCase, putinar);
    verifyGram(testCase, sparsePutinar);
    verifyGram(testCase, sparse);
    verifyGram(testCase, full);
    testCase.verifyTrue(islogical(toYalmip(widthOne)));
    testCase.verifyFalse(widthOne.UseSparseFullBoxPreorder);
    testCase.verifyTrue(dense.UseFullBoxPreorder);
    testCase.verifyFalse(dense.UseSparseFullBoxPreorder);
    verifyGram(testCase, dense);
    testCase.verifyTrue(sparsePutinarDense.UsePutinar);
    testCase.verifyFalse(sparsePutinarDense.UseSparsePutinar);
    verifyGram(testCase, sparsePutinarDense);
end

function A = constantPdmat(value)
    % Build one coefficient-backed scalar constant without a function handle.
    A = pdmat([0 1], {{value}}, Degree=0);
end

function verifyInconclusive(testCase, fcn)
    % A false export should issue the dedicated warning in every test runner.
    warnId = "pdlmi:InconclusiveCertificate";
    state = warning("query", warnId);
    cleanup = onCleanup(@() warning(state.state, warnId)); %#ok<NASGU>
    warning("on", warnId);

    tf = [];
    testCase.verifyWarning(@captureResult, char(warnId));
    testCase.verifyFalse(tf);

    function captureResult
        tf = fcn();
    end
end

function P = internalNumericPdvar(value)
    % Construct decision-free pdvar evidence for the class-gating regression.
    sz = size(value);
    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {{[0 1]}}, ...
        "MatrixSize", sz, ...
        "Degree", 0, ...
        "LocalValues", {{{value}}}, ...
        "IsContinuous", true, ...
        "ContainsDecision", false, ...
        "RateBounds", [], ...
        "SourceSummary", "numeric-regression");
    P = pdvar(init);
end

function verifyGram(testCase, C)
    % Gram certificates must export constraints with auxiliary variables.
    F = toYalmip(C);
    testCase.verifyTrue(isa(F, "lmi") || isa(F, "constraint"));
    testCase.verifyNotEmpty(getvariables(F));
end
