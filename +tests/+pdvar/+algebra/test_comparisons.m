function tests = test_comparisons
    % Behavioral regressions for pdvar.comparisons.
    tests = functiontests(localfunctions);
end

function test_rectangular_residual_warns_and_preserves_last_entry(testCase)
    % Comparison switches the complete nonsquare residual to entry-wise semantics.
    P = pdvar(2,3,{[0 2 5],[-3 1 6]},'full',Degree=[0 1]);
    testCase.verifyWarning(@() P<=0,'pdlmi:ElementwiseInequality');
    state = warning('off','pdlmi:ElementwiseInequality');
    cleanup = onCleanup(@() warning(state));
    C = P>=0;
    for subs = [1 1;1 2;2 1;2 2]'
        tests.infrastructure.verify_expr(testCase,C.Residual.coeffs(subs'),P.coeffs(subs'));
    end
    testCase.verifyEqual(C.Relation,">=");
    clear cleanup
end

function test_function_only_equality_rejected_in_both_orders(testCase)
    % Equality shares the same coefficient-evidence boundary as subtraction.
    P = pdvar(1,[0 2 5]);
    F = pdmat([0 2 5],@(r) r);
    testCase.verifyError(@() P==F,'pdvar:FunctionOnlyAlgebra');
    testCase.verifyError(@() F==P,'pdvar:FunctionOnlyAlgebra');
end

function setupOnce(~)
    % Clear YALMIP global state so constraint IDs stay local to this suite.
    yalmip("clear");
end

function test_pdvar_comparisons_return_inspectable_pdlmi_wrappers(testCase)
    % pdvar comparisons should return inspectable pdlmi wrappers.
    P = pdvar(2, {[0 0.5 1]}, "symmetric");

    Cneg = P <= 0;
    Cpos = P >= 0;

    testCase.verifyClass(Cneg, "pdlmi");
    testCase.verifyClass(Cpos, "pdlmi");
    verifyDefaults(testCase, Cneg);
    verifyDefaults(testCase, Cpos);
    testCase.verifyEqual(numel(Cneg.Constraints), 4);
    testCase.verifyEqual(numel(Cpos.Constraints), 4);
    testCase.verifyTrue(isequal(Cneg.Residual, P));
    testCase.verifyTrue(isequal(Cpos.Residual, P));
    testCase.verifyEqual(Cneg.Relation, "<=");
    testCase.verifyEqual(Cpos.Relation, ">=");
    veriConCel(testCase, Cneg);
    veriConCel(testCase, Cpos);
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

function veriConCel(testCase, C)
    testCase.verifyTrue(iscell(C.Constraints));
    testCase.verifySize(C.Constraints, [numel(C.Constraints), 1]);
    for k = 1:numel(C.Constraints)
        testCase.verifyTrue(isa(C.Constraints{k}, "constraint"));
    end
end
