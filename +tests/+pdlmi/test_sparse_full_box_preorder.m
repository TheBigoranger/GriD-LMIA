function tests = test_sparse_full_box_preorder
    %TEST_SPARSE_FULL_BOX_PREORDER Sparse tensor-window certificate contracts.
    tests = functiontests(localfunctions);
end

function setup(~)
    % Gram-variable identities are meaningful only with isolated YALMIP state.
    yalmip("clear");
end

function testConstructorFormsDefaultsAndImmutableSource(testCase)
    P = pdvar(1, {[0 1]}, Degree=4);
    direct = P >= 0;
    bare = pdlmi(P, ">=", "UseSparseFullBoxPreorder");
    named = pdlmi(P, ">=", UseSparseFullBoxPreorder=true);
    paired = pdlmi(P, ">=", "UseSparseFullBoxPreorder", true, ...
        "BandWidth", 2, "SparseFullBoxOrder", 3);
    widthOnly = pdlmi(P, ">=", BandWidth=2);
    orderOnly = pdlmi(P, ">=", SparseFullBoxOrder=3);
    applied = direct.applySparseFullBoxPreorder();
    tensorP = pdvar(1, {[0 1], [0 1]}, Degree=3);
    tensorDefault = pdlmi(tensorP, ">=", ...
        UseSparseFullBoxPreorder=true);

    verifySparse(testCase, bare, 2, 2, [2 2 2], 5);
    verifySparse(testCase, named, 2, 2, [2 2 2], 5);
    verifySparse(testCase, paired, 3, 2, 2 * ones(1, 5), 7);
    verifySparse(testCase, widthOnly, 2, 2, [2 2 2], 5);
    verifySparse(testCase, orderOnly, 3, 2, 2 * ones(1, 5), 7);
    verifySparse(testCase, applied, 2, 2, [2 2 2], 5);
    verifySparse(testCase, tensorDefault, 2, 2, 4 * ones(1, 9), 25);
    verifyInactive(testCase, direct);
    testCase.verifyTrue(isequal(applied.Residual, P));
end

function testCanonicalDirectAndFullBoxEndpoints(testCase)
    P = pdvar(1, {[0 1]}, Degree=4);
    direct = P >= 0;
    widthOne = direct.applySparseFullBoxPreorder(1, 2);
    denseEndpoint = direct.applySparseFullBoxPreorder(3, 2);
    denseReference = direct.applyFullBoxPreorder(2);
    constructorDirect = pdlmi(P, ">=", BandWidth=1, SparseFullBoxOrder=2);
    constructorDense = pdlmi(P, ">=", BandWidth=8, SparseFullBoxOrder=2);

    verifyInactive(testCase, widthOne);
    verifyInactive(testCase, constructorDirect);
    testCase.verifyEqual(numel(widthOne.Constraints), numel(direct.Constraints));
    testCase.verifyEqual(sort(getvariables(toYalmip(widthOne))), ...
        sort(getvariables(toYalmip(direct))));

    verifyDenseEndpoint(testCase, denseEndpoint, 2, [3 2], 5);
    verifyDenseEndpoint(testCase, constructorDense, 2, [3 2], 5);
    testCase.verifyEqual(numel(denseEndpoint.Constraints), ...
        numel(denseReference.Constraints));
    testCase.verifyEqual(psdDimensionsAt(denseEndpoint, 1:2), ...
        psdDimensionsAt(denseReference, 1:2));

    % Endpoint normalization must not bypass validation of an explicit order.
    testCase.verifyError(@() direct.applySparseFullBoxPreorder(1, 1), ...
        "pdlmi:SparseFullBoxOrderTooLow");
    testCase.verifyError(@() pdlmi(P, ">=", BandWidth=1, ...
        SparseFullBoxOrder=1), "pdlmi:SparseFullBoxOrderTooLow");
end

function testWidthOrderAndConflictValidation(testCase)
    P = pdvar(1, {[0 1]}, Degree=4);
    direct = P >= 0;
    malformedWidth = {0, -1, 1.5, Inf, NaN, "two", [1 2], true};
    malformedOrder = {-1, 0.5, Inf, NaN, "two", [1 2], true};

    for k = 1:numel(malformedWidth)
        testCase.verifyError(@() direct.applySparseFullBoxPreorder( ...
            malformedWidth{k}), "pdlmi:InvalidBandWidth");
        testCase.verifyError(@() pdlmi(P, ">=", ...
            BandWidth=malformedWidth{k}), "pdlmi:InvalidBandWidth");
    end
    for k = 1:numel(malformedOrder)
        testCase.verifyError(@() direct.applySparseFullBoxPreorder( ...
            2, malformedOrder{k}), "pdlmi:InvalidSparseFullBoxOrder");
        testCase.verifyError(@() pdlmi(P, ">=", BandWidth=2, ...
            SparseFullBoxOrder=malformedOrder{k}), ...
            "pdlmi:InvalidSparseFullBoxOrder");
    end
    testCase.verifyError(@() direct.applySparseFullBoxPreorder(2, 1), ...
        "pdlmi:SparseFullBoxOrderTooLow");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        UseSparseFullBoxPreorder=false, BandWidth=2), ...
        "pdlmi:ConflictingSparseFullBoxOptions");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        UseSparseFullBoxPreorder=false, SparseFullBoxOrder=2), ...
        "pdlmi:ConflictingSparseFullBoxOptions");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        "BandWidth", 2, "BandWidth", 3), "pdlmi:DuplicateOption");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        "SparseFullBoxOrder", "BandWidth"), "pdlmi:InvalidOptions");

    families = {@() pdlmi(P, ">=", UseSparseFullBoxPreorder=true, ...
            UsePolya=true), ...
        @() pdlmi(P, ">=", UseSparseFullBoxPreorder=true, ...
            UsePutinar=true), ...
        @() pdlmi(P, ">=", UseSparseFullBoxPreorder=true, ...
            UseFullBoxPreorder=true)};
    for k = 1:numel(families)
        testCase.verifyError(families{k}, "pdlmi:ConflictingRelaxations");
    end
end

function testApplyRebuildsAndReplacesEveryFamily(testCase)
    P = pdvar(1, {[0 1]}, Degree=4);
    direct = P >= 0;
    sparse = direct.applySparseFullBoxPreorder(2, 2);
    polya = sparse.applyPolya(1);
    putinar = sparse.applyPutinar(2);
    full = sparse.applyFullBoxPreorder(2);
    fromPolya = polya.applySparseFullBoxPreorder(2, 2);
    fromPutinar = putinar.applySparseFullBoxPreorder(2, 2);
    fromFull = full.applySparseFullBoxPreorder(2, 2);

    verifySparse(testCase, sparse, 2, 2, [2 2 2], 5);
    verifySparse(testCase, fromPolya, 2, 2, [2 2 2], 5);
    verifySparse(testCase, fromPutinar, 2, 2, [2 2 2], 5);
    verifySparse(testCase, fromFull, 2, 2, [2 2 2], 5);
    verifySparseInactive(testCase, polya);
    verifySparseInactive(testCase, putinar);
    verifySparseInactive(testCase, full);
    testCase.verifyTrue(polya.UsePolya);
    testCase.verifyTrue(putinar.UsePutinar);
    testCase.verifyTrue(full.UseFullBoxPreorder);
    testCase.verifyTrue(isequal(fromFull.Residual, P));
end

function testUnivariateTridiagonalAndPentadiagonalCliques(testCase)
    P = pdvar(1, {[0 1]}, Degree=6);
    direct = P >= 0;
    tridiagonal = direct.applySparseFullBoxPreorder(2, 3);
    pentadiagonal = direct.applySparseFullBoxPreorder(3, 3);

    verifySparse(testCase, tridiagonal, 3, 2, 2 * ones(1, 5), 7);
    verifySparse(testCase, pentadiagonal, 3, 3, 3 * ones(1, 3), 7);
    verifyDisjointGramVariables(testCase, tridiagonal, 1:5);
    verifyDisjointGramVariables(testCase, pentadiagonal, 1:3);
end

function testAsymmetricTensorWindowIncidence(testCase)
    % Tensor corners identify both axes without relying on flattened adjacency.
    P = pdvar(1, {[0 1], [0 1]}, Degree=4);
    direct = P >= 0;
    C = direct.applySparseFullBoxPreorder(2, 2);

    verifySparse(testCase, C, 2, 2, 4 * ones(1, 9), 25);
    gramVariables = constraintVariables(C, 1:9);
    cornerLabels = [1 5 21 25];
    expectedEmptyWindows = [1 2 3 4];
    for k = 1:numel(cornerLabels)
        equalityIndex = 9 + cornerLabels(k);
        metadata = struct(C.Constraints{equalityIndex});
        equalityVariables = getvariables(metadata.List{1});
        active = find(cellfun(@(ids) ...
            ~isempty(intersect(ids, equalityVariables)), gramVariables));
        testCase.verifyEqual(active, expectedEmptyWindows(k), ...
            "Each tensor corner must use its coordinate-aligned empty-mask window.");
    end
end

function testMatrixEntryCellAndRateCertificatesAreIndependent(testCase)
    matrixP = pdvar(2, {[0 1]}, "symmetric", Degree=4);
    matrixDirect = matrixP >= 0;
    matrixC = matrixDirect.applySparseFullBoxPreorder(2, 2);
    verifySparse(testCase, matrixC, 2, 2, [4 4 4], 5);

    fullP = pdvar(2, {[0 1]}, "full", Degree=4);
    entrywise = constructWithWarning(testCase, ...
        @() applySparseFullBoxPreorder(fullP >= 0, 2, 2));
    coeffs = fullP.coeffs(1);
    targetIds = cell(4, 5);
    for entry = 1:4
        for label = 1:5
            targetIds{entry, label} = getvariables(coeffs{label}(entry));
        end
    end
    testCase.verifyEqual(numel(entrywise.Constraints), 4 * 8);
    for entry = 1:4
        base = (entry - 1) * 8;
        for label = 1:5
            metadata = struct(entrywise.Constraints{base + 3 + label});
            matched = intersect(getvariables(metadata.List{1}), ...
                [targetIds{:}]);
            testCase.verifyEqual(matched, targetIds{entry, label}, ...
                "Entry-wise targets must follow MATLAB column-major order.");
        end
    end

    rateP = pdvar(2, 1, {[0 1 2]}, "full", Degree=5, ...
        RateBounds=[-1 1]);
    derivative = rhodiff(rateP);
    rateC = constructWithWarning(testCase, ...
        @() applySparseFullBoxPreorder(derivative <= 0, 2, 2));
    % 2 cells * 2 rate rows * 2 entries * (3 PSD + 5 identities).
    testCase.verifyEqual(size(derivative.coeffs(1)), [2 5]);
    testCase.verifyEqual(numel(rateC.Constraints), 64);
    psdIndices = reshape(((0:7)' * 8 + [1 2 3]).', 1, []);
    testCase.verifyEqual(psdDimensionsAt(rateC, psdIndices), ...
        2 * ones(size(psdIndices)));
    verifyDisjointGramVariables(testCase, rateC, psdIndices);
end

function testBenchmarkBandWidthValidation(testCase)
    malformed = {[], 0, -1, 1.5, Inf, NaN, "two", [1 2.5]};
    for k = 1:numel(malformed)
        testCase.verifyError(@() tests.pdlmi.benchmark_relaxations( ...
            2, malformed{k}), "pdlmi:InvalidBenchmarkBandWidths");
    end
end

function verifySparse(testCase, C, order, bandWidth, gramSizes, equalityCount)
    testCase.verifyTrue(C.UseSparseFullBoxPreorder);
    testCase.verifyEqual(C.SparseFullBoxOrder, order);
    testCase.verifyEqual(C.BandWidth, bandWidth);
    testCase.verifyFalse(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, 0);
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, 0);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, 0);
    testCase.verifyEqual(psdDimensionsAt(C, 1:numel(gramSizes)), gramSizes);
    testCase.verifyEqual(numel(C.Constraints), numel(gramSizes) + equalityCount);
end

function verifyInactive(testCase, C)
    testCase.verifyFalse(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, 0);
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, 0);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, 0);
    verifySparseInactive(testCase, C);
end

function verifySparseInactive(testCase, C)
    testCase.verifyFalse(C.UseSparseFullBoxPreorder);
    testCase.verifyEqual(C.SparseFullBoxOrder, 0);
    testCase.verifyEqual(C.BandWidth, 0);
end

function verifyDenseEndpoint(testCase, C, order, gramSizes, equalityCount)
    testCase.verifyTrue(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, order);
    verifySparseInactive(testCase, C);
    testCase.verifyEqual(psdDimensionsAt(C, 1:numel(gramSizes)), gramSizes);
    testCase.verifyEqual(numel(C.Constraints), numel(gramSizes) + equalityCount);
end

function dims = psdDimensionsAt(C, indices)
    dims = zeros(size(indices));
    for k = 1:numel(indices)
        metadata = struct(C.Constraints{indices(k)});
        dims(k) = size(metadata.List{1}, 1);
    end
end

function vars = constraintVariables(C, indices)
    vars = cell(size(indices));
    for k = 1:numel(indices)
        metadata = struct(C.Constraints{indices(k)});
        vars{k} = getvariables(metadata.List{1});
    end
end

function verifyDisjointGramVariables(testCase, C, indices)
    vars = constraintVariables(C, indices);
    for a = 1:numel(vars)
        for b = (a + 1):numel(vars)
            testCase.verifyEmpty(intersect(vars{a}, vars{b}));
        end
    end
end

function out = constructWithWarning(testCase, fun)
    % Capture a successful entry-wise wrapper while asserting public dispatch.
    out = [];
    testCase.verifyWarning(@construct, "pdlmi:ElementwiseInequality");

    function construct
        out = fun();
    end
end
