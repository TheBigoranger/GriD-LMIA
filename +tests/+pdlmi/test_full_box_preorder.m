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

function testEntrywiseScalarBlocksAndColumnMajorTargets(testCase)
    % Odd interval certificates repeat scalar endpoint blocks per matrix entry.
    P = pdvar(3, 2, {[0 1]}, "full", Degree=1);
    C = constructWithWarning(testCase, @() pdlmi(P, ">=", ...
        UseFullBoxPreorder=true));
    coeffs = P.coeffs(1);

    testCase.verifyEqual(numel(C.Constraints), 6 * 4);
    psdIdx = reshape((0:5)' * 4 + [1 2], 1, []);
    testCase.verifyEqual(psdDimensionsAt(C, psdIdx), ones(1, 12));
    verifyDisjointGramVariables(testCase, C, psdIdx);
    for entry = 1:6
        base = (entry - 1) * 4;
        targetIds = [getvariables(coeffs{1, 1}(entry)), ...
            getvariables(coeffs{1, 2}(entry))];
        for label = 1:2
            metadata = struct(C.Constraints{base + 2 + label});
            matched = intersect(getvariables(metadata.List{1}), targetIds);
            testCase.verifyEqual(matched, targetIds(label));
        end
    end
end

function testEntrywiseEveryCellAndRateRow(testCase)
    % Each cell/rate-row/entry owns its two scalar odd-degree Gram blocks.
    P = pdvar(2, 1, {[0 1 2]}, "full", Degree=2, ...
        RateBounds=[-1 1]);
    D = rhodiff(P);
    C = constructWithWarning(testCase, @() pdlmi(D, "<=", ...
        UseFullBoxPreorder=true));

    % 2 cells * 2 rows * 2 entries * (2 PSD + 2 identities).
    testCase.verifyEqual(size(D.coeffs(1)), [2 2]);
    testCase.verifyEqual(numel(C.Constraints), 32);
    psdIdx = reshape((0:7)' * 4 + [1 2], 1, []);
    testCase.verifyEqual(psdDimensionsAt(C, psdIdx), ones(1, 16));
    verifyDisjointGramVariables(testCase, C, psdIdx);
end

function testSymmetricMatrixGramDimensionsRemainUnchanged(testCase)
    % Semidefinite mode still lifts the matrix dimension into each Gram block.
    P = pdvar(2, {[0 1]}, "symmetric", Degree=2);
    C = pdlmi(P, ">=", UseFullBoxPreorder=true);

    testCase.verifyEqual(numel(C.Constraints), 5);
    testCase.verifyEqual(psdDimensionsAt(C, [1 2]), [4 2]);
end

function dims = psdDimensionsAt(C, indices)
    dims = zeros(size(indices));
    for k = 1:numel(indices)
        metadata = struct(C.Constraints{indices(k)});
        dims(k) = size(metadata.List{1}, 1);
    end
end

function verifyDisjointGramVariables(testCase, C, indices)
    % Scalar certificate blocks remain independent across every target slice.
    vars = cell(size(indices));
    for k = 1:numel(indices)
        metadata = struct(C.Constraints{indices(k)});
        vars{k} = getvariables(metadata.List{1});
    end
    for a = 1:numel(vars)
        for b = (a + 1):numel(vars)
            testCase.verifyEmpty(intersect(vars{a}, vars{b}));
        end
    end
end

function out = constructWithWarning(testCase, fun)
    % Retain the wrapper while asserting entry-wise dispatch is visible.
    out = [];
    testCase.verifyWarning(@construct, "pdlmi:ElementwiseInequality");

    function construct
        out = fun();
    end
end
