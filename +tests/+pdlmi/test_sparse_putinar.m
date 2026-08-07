function tests = test_sparse_putinar
    %TEST_SPARSE_PUTINAR Tensor-window Putinar certificate contracts.
    tests = functiontests(localfunctions);
end

function setup(~)
    % Gram-variable identities are meaningful only with isolated YALMIP state.
    yalmip("clear");
end

function testConAppDefAndImm(testCase)
    P = pdvar(1, {[0 1]}, Degree=4);
    direct = P >= 0;
    bare = pdlmi(P, ">=", "UseSparsePutinar");
    named = pdlmi(P, ">=", UseSparsePutinar=true);
    paired = pdlmi(P, ">=", CliqueSize=2, SparsePutinarOrder=3);
    sizeOnly = pdlmi(P, ">=", CliqueSize=2);
    orderOnly = pdlmi(P, ">=", SparsePutinarOrder=3);
    applied = direct.useSpPut();

    verifySparse(testCase, bare, 2, 2, [2 2 2], 5);
    verifySparse(testCase, named, 2, 2, [2 2 2], 5);
    verifySparse(testCase, paired, 3, 2, 2 * ones(1, 5), 7);
    verifySparse(testCase, sizeOnly, 2, 2, [2 2 2], 5);
    verifySparse(testCase, orderOnly, 3, 2, 2 * ones(1, 5), 7);
    verifySparse(testCase, applied, 2, 2, [2 2 2], 5);
    verifyAllInactive(testCase, direct);
    testCase.verifyTrue(isequal(applied.Residual, P));

    tensor = pdvar(1, {[0 1], [0 1]}, Degree=[3 4]);
    tensorDefault = pdlmi(tensor, ">=", UseSparsePutinar=true);
    testCase.verifyEqual(tensorDefault.SparsePutinarOrder, [2 2]);
    testCase.verifyEqual(tensorDefault.CliqueSize, 2);
end

function testCanEndAndOneDim(testCase)
    evenP = pdvar(1, {[0 1]}, Degree=4);
    evenDirect = evenP >= 0;
    sizeOne = evenDirect.useSpPut(1, 2);
    dense = evenDirect.useSpPut(3, 2);
    denseReference = evenDirect.usePutinar(2);

    verifyAllInactive(testCase, sizeOne);
    testCase.verifyEqual(numel(sizeOne.Constraints), ...
        numel(evenDirect.Constraints));
    verifyDense(testCase, dense, 2, [3 2], 5);
    testCase.verifyEqual(psdDimensionsAt(dense, 1:2), ...
        psdDimensionsAt(denseReference, 1:2));

    oddP = pdvar(1, {[0 1]}, Degree=3);
    oddDirect = oddP >= 0;
    oddSparse = oddDirect.useSpPut(2, 2);
    verifySparse(testCase, oddSparse, 2, 2, 2 * ones(1, 4), 6);

    % Endpoint normalization must not bypass explicit-order validation.
    testCase.verifyError(@() evenDirect.useSpPut(1, 1), ...
        "pdlmi:SparsePutinarOrderTooLow");
end

function testMulSizOneAndTen(testCase)
    P = pdvar(1, {[0 1], [0 1]}, Degree=[4 4]);
    direct = P >= 0;
    sizeOne = direct.useSpPut(1, [2 2]);
    sparse = direct.useSpPut(2, [2 2]);
    dense = direct.useSpPut(3, [2 2]);

    verifySparse(testCase, sizeOne, [2 2], 1, ones(1, 21), 25);
    verifySparse(testCase, sparse, [2 2], 2, 4 * ones(1, 8), 25);
    verifyDense(testCase, dense, [2 2], [9 6 6], 25);
    veriDisGraVar(testCase, sparse, 1:8);

    gramVariables = constraintVariables(sparse, 1:8);
    cornerLabels = [1 5 21 25];
    for k = 1:numel(cornerLabels)
        metadata = struct(sparse.Constraints{8 + cornerLabels(k)});
        equalityVariables = getvariables(metadata.List{1});
        active = find(cellfun(@(ids) ...
            ~isempty(intersect(ids, equalityVariables)), gramVariables));
        testCase.verifyEqual(active(1), k, ...
            "Empty-mask corner windows must follow tensor label order.");
    end
end

function testAniOrdAndZerDeg(testCase)
    grid = {[0 1], [10 20]};
    P = pdvar(1, grid, Degree=[0 4]);
    direct = P >= 0;
    sparse = direct.useSpPut(2, [0 2]);
    dense = direct.useSpPut(3, [0 2]);

    verifySparse(testCase, sparse, [0 2], 2, [2 2 2], 5);
    verifyDense(testCase, dense, [0 2], [3 2], 5);

    reversed = pdlmi(pdvar(1, grid, Degree=[4 0]), ">=", ...
        UseSparsePutinar=true);
    verifySparse(testCase, reversed, [2 0], 2, [2 2 2], 5);

    anisotropic = pdlmi(pdvar(1, grid, Degree=[2 6]), ">=", ...
        CliqueSize=2, SparsePutinarOrder=[1; 3]);
    testCase.verifyEqual(anisotropic.SparsePutinarOrder, [1 3]);
    testCase.verifyEqual(psdDimensionsAt(anisotropic, 1:8), ...
        [4 4 4 2 2 2 4 4]);
end

function testValConAndParPre(testCase)
    P = pdvar(1, {[0 1]}, Degree=4);
    direct = P >= 0;
    malformedSize = {0, -1, 1.5, Inf, NaN, "two", [1 2], true};
    malformedOrder = {-1, 0.5, Inf, NaN, "two", [1 2], true};

    for k = 1:numel(malformedSize)
        testCase.verifyError(@() direct.useSpPut( ...
            malformedSize{k}), "pdlmi:InvalidCliqueSize");
        testCase.verifyError(@() pdlmi(P, ">=", ...
            CliqueSize=malformedSize{k}), "pdlmi:InvalidCliqueSize");
    end
    for k = 1:numel(malformedOrder)
        testCase.verifyError(@() direct.useSpPut( ...
            2, malformedOrder{k}), "pdlmi:InvalidSparsePutinarOrder");
        testCase.verifyError(@() pdlmi(P, ">=", ...
            SparsePutinarOrder=malformedOrder{k}), ...
            "pdlmi:InvalidSparsePutinarOrder");
    end
    testCase.verifyError(@() direct.useSpPut(2, 1), ...
        "pdlmi:SparsePutinarOrderTooLow");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        UseSparsePutinar=false, CliqueSize=2), ...
        "pdlmi:ConflictingSparsePutinarOptions");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        UseSparsePutinar=false, SparsePutinarOrder=2), ...
        "pdlmi:ConflictingSparsePutinarOptions");
    testCase.verifyError(@() pdlmi(P, ">=", UseSparsePutinar=1), ...
        "pdlmi:InvalidUseSparsePutinar");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        "CliqueSize", 2, "CliqueSize", 3), "pdlmi:DuplicateOption");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        "SparsePutinarOrder", "CliqueSize"), "pdlmi:InvalidOptions");

    familyOptions = {"UsePolya", "UsePutinar", ...
        "UseSparseFullBoxPreorder", "UseFullBoxPreorder"};
    for k = 1:numel(familyOptions)
        testCase.verifyError(@() pdlmi(P, ">=", ...
            "UseSparsePutinar", true, familyOptions{k}, true), ...
            "pdlmi:ConflictingRelaxations");
    end
end

function testAppRepEveFamAnd(testCase)
    P = pdvar(1, {[0 1]}, Degree=4);
    direct = P >= 0;
    sources = {direct.usePolya(1), direct.usePutinar(2), ...
        direct.useSpBox(2, 2), ...
        direct.useFullBox(2)};
    for k = 1:numel(sources)
        sparse = sources{k}.useSpPut(2, 2);
        verifySparse(testCase, sparse, 2, 2, [2 2 2], 5);
        testCase.verifyTrue(isequal(sparse.Residual, P));
    end

    sparse = direct.useSpPut(2, 2);
    replacements = {sparse.usePolya(1), sparse.usePutinar(2), ...
        sparse.useSpBox(2, 2), ...
        sparse.useFullBox(2)};
    for k = 1:numel(replacements)
        testCase.verifyFalse(replacements{k}.UseSparsePutinar);
        testCase.verifyEqual(replacements{k}.SparsePutinarOrder, 0);
        testCase.verifyEqual(replacements{k}.CliqueSize, 0);
    end
end

function testSigMatEntCelAnd(testCase)
    P = pdvar(1, {[0 1]}, Degree=4);
    lowerDirect = P >= 0;
    upperDirect = P <= 0;
    lower = lowerDirect.useSpPut(2, 2);
    upper = upperDirect.useSpPut(2, 2);
    coeffIds = getvariables(P.coeffs(1));
    lowerTarget = equaTarCoe(lower, 4:8, coeffIds);
    upperTarget = equaTarCoe(upper, 4:8, coeffIds);
    testCase.verifyEqual(lowerTarget, -upperTarget, AbsTol=0);

    matrixP = pdvar(2, {[0 1]}, "symmetric", Degree=4);
    matrixDirect = matrixP >= 0;
    matrixC = matrixDirect.useSpPut(2, 2);
    verifySparse(testCase, matrixC, 2, 2, [4 4 4], 5);

    fullP = pdvar(2, {[0 1]}, "full", Degree=4);
    entrywise = constructWithWarning(testCase, ...
        @() useSpPut(fullP >= 0, 2, 2));
    testCase.verifyEqual(numel(entrywise.Constraints), 4 * 8);
    psdIndices = reshape(((0:3)' * 8 + [1 2 3]).', 1, []);
    veriDisGraVar(testCase, entrywise, psdIndices);

    rateP = pdvar(2, 1, {[0 1 2]}, "full", Degree=5, ...
        RateBounds=[-1 1]);
    derivative = rhodiff(rateP);
    rateC = constructWithWarning(testCase, ...
        @() useSpPut(derivative <= 0, 2, 2));
    % Differentiation lowers the degree: 8 local certificates, each 3+5.
    testCase.verifyEqual(numel(rateC.Constraints), 64);
    psdIndices = reshape(((0:7)' * 8 + [1 2 3]).', 1, []);
    testCase.verifyEqual(psdDimensionsAt(rateC, psdIndices), ...
        2 * ones(size(psdIndices)));
    veriDisGraVar(testCase, rateC, psdIndices);
end

function verifySparse(testCase, C, order, cliqueSize, gramSizes, equalityCount)
    order = expandExpected(order, C.Residual.npar());
    zero = zeros(1, C.Residual.npar());
    testCase.verifyTrue(C.UseSparsePutinar);
    testCase.verifyEqual(C.SparsePutinarOrder, order);
    testCase.verifyEqual(C.CliqueSize, cliqueSize);
    testCase.verifyFalse(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, zero);
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, zero);
    testCase.verifyFalse(C.UseSparseFullBoxPreorder);
    testCase.verifyEqual(C.SparseFullBoxOrder, zero);
    testCase.verifyEqual(C.BandWidth, 0);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, zero);
    testCase.verifyEqual(psdDimensionsAt(C, 1:numel(gramSizes)), gramSizes);
    testCase.verifyEqual(numel(C.Constraints), numel(gramSizes) + equalityCount);
end

function verifyDense(testCase, C, order, gramSizes, equalityCount)
    order = expandExpected(order, C.Residual.npar());
    testCase.verifyTrue(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, order);
    testCase.verifyFalse(C.UseSparsePutinar);
    testCase.verifyEqual(C.SparsePutinarOrder, zeros(size(order)));
    testCase.verifyEqual(C.CliqueSize, 0);
    testCase.verifyEqual(psdDimensionsAt(C, 1:numel(gramSizes)), gramSizes);
    testCase.verifyEqual(numel(C.Constraints), numel(gramSizes) + equalityCount);
end

function verifyAllInactive(testCase, C)
    zero = zeros(1, C.Residual.npar());
    testCase.verifyFalse(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, zero);
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, zero);
    testCase.verifyFalse(C.UseSparsePutinar);
    testCase.verifyEqual(C.SparsePutinarOrder, zero);
    testCase.verifyEqual(C.CliqueSize, 0);
    testCase.verifyFalse(C.UseSparseFullBoxPreorder);
    testCase.verifyEqual(C.SparseFullBoxOrder, zero);
    testCase.verifyEqual(C.BandWidth, 0);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, zero);
end

function value = expandExpected(value, nPar)
    value = reshape(value, 1, []);
    if isscalar(value)
        value = repmat(value, 1, nPar);
    end
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

function veriDisGraVar(testCase, C, indices)
    vars = constraintVariables(C, indices);
    for a = 1:numel(vars)
        for b = (a + 1):numel(vars)
            testCase.verifyEmpty(intersect(vars{a}, vars{b}));
        end
    end
end

function coefficients = equaTarCoe(C, indices, variableIds)
    coefficients = zeros(numel(indices), numel(variableIds));
    for k = 1:numel(indices)
        metadata = struct(C.Constraints{indices(k)});
        basis = full(getbase(metadata.List{1}));
        coefficients(k, :) = basis(variableIds + 1);
    end
end

function out = constructWithWarning(testCase, fun)
    out = [];
    testCase.verifyWarning(@construct, "pdlmi:ElementwiseInequality");

    function construct
        out = fun();
    end
end
