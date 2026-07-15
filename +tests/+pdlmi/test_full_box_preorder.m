function tests = test_full_box_preorder
    %TEST_FULL_BOX_PREORDER Public full-box selection and validation behavior.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep YALMIP decision state local to this suite.
    yalmip("clear");
end

function testDefaultOrderThroughConstructorAndApply(testCase)
    % One-dimensional and tensor defaults use their documented formulas.
    intervalExpr = pdvar(1, {[0 1]}, "symmetric", Degree=3);
    interval = pdlmi(intervalExpr, ">=", UseFullBoxPreorder=true);
    direct = pdlmi(intervalExpr, ">=");
    reapplied = direct.applyFullBoxPreorder();

    testCase.verifyTrue(interval.UseFullBoxPreorder);
    testCase.verifyEqual(interval.FullBoxOrder, 1);
    testCase.verifyEqual(reapplied.FullBoxOrder, 1);
    testCase.verifyFalse(reapplied.UsePolya);
    testCase.verifyFalse(reapplied.UsePutinar);
    testCase.verifyFalse(direct.UseFullBoxPreorder, ...
        "Applying a certificate must not mutate the source wrapper.");

    boxExpr = pdvar(1, {[0 1], [2 3]}, "symmetric", Degree=3);
    box = pdlmi(boxExpr, ">=", UseFullBoxPreorder=true);
    boxApplied = pdlmi(boxExpr, ">=").applyFullBoxPreorder();

    testCase.verifyEqual(box.FullBoxOrder, 2);
    testCase.verifyEqual(boxApplied.FullBoxOrder, 2);
end

function testExplicitOrderAndMinimumValidation(testCase)
    % Explicit absolute orders are retained, while insufficient orders fail.
    expr = pdvar(1, {[0 1]}, "symmetric", Degree=4);
    explicit = pdlmi(expr, ">=", FullBoxOrder=3);
    applied = pdlmi(expr, ">=").applyFullBoxPreorder(2);

    testCase.verifyTrue(explicit.UseFullBoxPreorder);
    testCase.verifyEqual(explicit.FullBoxOrder, 3);
    testCase.verifyEqual(applied.FullBoxOrder, 2);
    testCase.verifyError(@() pdlmi(expr, ">=", FullBoxOrder=1), ...
        "pdlmi:FullBoxOrderTooLow");
    base = pdlmi(expr, ">=");
    testCase.verifyError(@() base.applyFullBoxPreorder(1), ...
        "pdlmi:FullBoxOrderTooLow");
    testCase.verifyError(@() base.applyFullBoxPreorder(1.5), ...
        "pdlmi:InvalidFullBoxOrder");
end

function testEveryAssemblerPreservesMatrixValidationIds(testCase)
    % Direct, Polya, and Gram paths enforce the same semidefinite shape gate.
    rectangular = pdvar(2, 1, {[0 1]}, "full");
    nonsymmetric = pdvar(2, {[0 1]}, "full");

    verifyAllModesFail(testCase, rectangular, "pdlmi:InvalidMatrixSize");
    verifyAllModesFail(testCase, nonsymmetric, ...
        "pdlmi:NonSymmetricExpression");
end

function verifyAllModesFail(testCase, expr, errorId)
    testCase.verifyError(@() pdlmi(expr, "<="), errorId);
    testCase.verifyError(@() pdlmi(expr, "<=", UsePolya=true), errorId);
    testCase.verifyError(@() pdlmi(expr, "<=", ...
        UseFullBoxPreorder=true), errorId);
    testCase.verifyError(@() pdlmi(expr, "<=", UsePutinar=true), errorId);
end
