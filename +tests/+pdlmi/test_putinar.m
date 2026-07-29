function tests = test_putinar
    %TEST_PUTINAR Public Putinar selection, order, and assembly behavior.
    tests = functiontests(localfunctions);
end

function setup(~)
    % Isolate YALMIP decision state between Gram-assembly checks.
    yalmip("clear");
end

function testConstructorFormsAndInactiveDefaults(testCase)
    P = pdvar(1, {[0 1]}, Degree=2);
    direct = P >= 0;
    bare = pdlmi(P, ">=", "UsePutinar");
    named = pdlmi(P, ">=", UsePutinar=true);
    paired = pdlmi(P, ">=", "UsePutinar", true, "PutinarOrder", 2);
    orderNamed = pdlmi(P, ">=", PutinarOrder=2);
    orderPaired = pdlmi(P, ">=", "PutinarOrder", 2);

    verifyInactive(testCase, direct);
    verifyPutinar(testCase, bare, 1, [2 1], 3);
    verifyPutinar(testCase, named, 1, [2 1], 3);
    verifyPutinar(testCase, paired, 2, [3 2], 5);
    verifyPutinar(testCase, orderNamed, 2, [3 2], 5);
    verifyPutinar(testCase, orderPaired, 2, [3 2], 5);
end

function testDefaultOrderAcrossResidualDegrees(testCase)
    expected = [0 0 1 1 2 2 3];
    for degree = 0:6
        P = pdvar(1, {[0 1]}, Degree=degree);
        constructor = pdlmi(P, ">=", UsePutinar=true);
        direct = P >= 0;
        applied = direct.applyPutinar();
        testCase.verifyEqual(constructor.PutinarOrder, expected(degree + 1));
        testCase.verifyEqual(applied.PutinarOrder, expected(degree + 1));
    end
end

function testOneDimensionalPutinarMatchesFullBoxParityForm(testCase)
    % The interval selector intentionally shares FullBox's exact parity form.
    for degree = 0:5
        P = pdvar(2, {[0 1]}, Degree=degree);
        putinar = pdlmi(P, ">=", UsePutinar=true);
        fullBox = pdlmi(P, ">=", UseFullBoxPreorder=true);
        nPsd = 1 + (degree > 0);

        testCase.verifyEqual(putinar.PutinarOrder, fullBox.FullBoxOrder);
        testCase.verifyEqual(numel(putinar.Constraints), ...
            numel(fullBox.Constraints));
        testCase.verifyEqual(psdDimensions(putinar, nPsd), ...
            psdDimensions(fullBox, nPsd));
    end
end

function testOrderValidationAndExplicitFalseConflict(testCase)
    P = pdvar(1, {[0 1]}, Degree=4);
    direct = P >= 0;
    malformed = {-1, 0.5, Inf, NaN, "one", [1 2], true};

    for k = 1:numel(malformed)
        testCase.verifyError(@() direct.applyPutinar(malformed{k}), ...
            "pdlmi:InvalidPutinarOrder");
        testCase.verifyError(@() pdlmi(P, ">=", ...
            PutinarOrder=malformed{k}), "pdlmi:InvalidPutinarOrder");
    end
    testCase.verifyError(@() direct.applyPutinar(1), ...
        "pdlmi:PutinarOrderTooLow");
    testCase.verifyError(@() pdlmi(P, ">=", PutinarOrder=1), ...
        "pdlmi:PutinarOrderTooLow");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        UsePutinar=false, PutinarOrder=0), ...
        "pdlmi:ConflictingPutinarOptions");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        "UsePutinar", false, "PutinarOrder", 2), ...
        "pdlmi:ConflictingPutinarOptions");
end

function testMalformedAndConflictingOptions(testCase)
    P = pdvar(1, {[0 1]}, Degree=2);

    testCase.verifyError(@() pdlmi(P, ">=", ...
        "PutinarOrder", "UsePutinar"), "pdlmi:InvalidOptions");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        "UsePutinar", true, "UsePutinar"), "pdlmi:DuplicateOption");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        "PutinarOrder", 1, "PutinarOrder", 2), "pdlmi:DuplicateOption");
    testCase.verifyError(@() pdlmi(P, ">=", UsePutinar=1), ...
        "pdlmi:InvalidUsePutinar");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        UsePutinar=true, UsePolya=true), "pdlmi:ConflictingRelaxations");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        UsePutinar=true, UseFullBoxPreorder=true), ...
        "pdlmi:ConflictingRelaxations");
    testCase.verifyError(@() pdlmi(P, ">=", ...
        PutinarOrder=1, UsePolya=true), "pdlmi:ConflictingRelaxations");
end

function testApplyRebuildsAndReplacesOtherFamilies(testCase)
    P = pdvar(1, {[0 1]}, Degree=2);
    direct = P >= 0;
    putinar1 = direct.applyPutinar();
    putinar2 = putinar1.applyPutinar(2);
    polya = putinar2.applyPolya(2);
    full = putinar2.applyFullBoxPreorder(1);
    fromPolya = polya.applyPutinar(1);
    fromFull = full.applyPutinar(1);

    verifyInactive(testCase, direct);
    verifyPutinar(testCase, putinar1, 1, [2 1], 3);
    verifyPutinar(testCase, putinar2, 2, [3 2], 5);
    testCase.verifyTrue(polya.UsePolya);
    testCase.verifyFalse(polya.UsePutinar);
    testCase.verifyTrue(full.UseFullBoxPreorder);
    testCase.verifyFalse(full.UsePutinar);
    testCase.verifyTrue(isequal(fromPolya.Residual, P));
    testCase.verifyTrue(isequal(fromFull.Residual, P));
    verifyPutinar(testCase, fromPolya, 1, [2 1], 3);
    verifyPutinar(testCase, fromFull, 1, [2 1], 3);
end

function testDegreeZeroOddAndTensorBlockDimensions(testCase)
    constant = pdlmi(pdvar(2, {[0 1]}, Degree=0), ">=", UsePutinar=true);
    odd = pdlmi(pdvar(2, {[0 1]}, Degree=3), ">=", UsePutinar=true);
    tensor = pdlmi(pdvar(2, {[0 1], [0 1]}, Degree=[2 2]), ...
        ">=", UsePutinar=true);

    % Order zero omits both nominal negative-degree multiplier blocks.
    verifyPutinar(testCase, constant, 0, 2, 1);
    % One-dimensional odd targets use the Markov-Lukacs endpoint facets.
    verifyPutinar(testCase, odd, 1, [4 4], 4);
    verifyPutinar(testCase, tensor, 1, [8 4 4], 9);
end

function testAnisotropicOrdersAndGramDimensions(testCase)
    % Putinar keeps only empty and admissible singleton masks per direction.
    grid = {[0 1], [10 20]};
    P = pdvar(2, grid, "symmetric", Degree=[1 4]);
    default = pdlmi(P, ">=", UsePutinar=true);
    explicit = pdlmi(P, ">=", PutinarOrder=[2; 3]);

    verifyPutinar(testCase, default, [1 2], [12 6 8], 15);
    verifyPutinar(testCase, explicit, [2 3], [24 16 18], 35);

    direct = P >= 0;
    testCase.verifyError(@() direct.applyPutinar([0 2]), ...
        "pdlmi:PutinarOrderTooLow");
    bad = {[], [1 2 3], [1 2; 3 4], -1, 0.5, Inf, NaN};
    for k = 1:numel(bad)
        testCase.verifyError(@() direct.applyPutinar(bad{k}), ...
            "pdlmi:InvalidPutinarOrder");
    end
end

function testZeroOrderAxisOmitsUnavailableSingleton(testCase)
    % A singleton multiplier is absent when its axis order is exactly zero.
    grid = {[0 1], [10 20]};
    firstConstant = pdlmi(pdvar(1, grid, Degree=[0 4]), ...
        ">=", UsePutinar=true);
    secondConstant = pdlmi(pdvar(1, grid, Degree=[4 0]), ...
        ">=", UsePutinar=true);

    verifyPutinar(testCase, firstConstant, [0 2], [3 2], 5);
    verifyPutinar(testCase, secondConstant, [2 0], [3 2], 5);
end

function testSignsEveryCellAndRateRow(testCase)
    P = pdvar(1, {[0 1]}, Degree=2);
    lower = P >= 0;
    upper = P <= 0;
    lower = lower.applyPutinar(2);
    upper = upper.applyPutinar(2);

    verifyPutinar(testCase, lower, 2, [3 2], 5);
    verifyPutinar(testCase, upper, 2, [3 2], 5);
    testCase.verifyEqual(lower.Relation, ">=");
    testCase.verifyEqual(upper.Relation, "<=");

    rateP = pdvar(1, {[0 1 2]}, Degree=2, RateBounds=[-1 1]);
    derivative = rhodiff(rateP);
    rate = derivative >= 0;
    rate = rate.applyPutinar();
    testCase.verifyEqual(size(derivative.coeffs(1)), [2 2]);
    % Degree-one interval targets use two endpoint PSD blocks plus two equalities.
    testCase.verifyEqual(numel(rate.Constraints), 2 * 2 * 4);
    psdIdx = reshape(((1:4:13)' + [0 1]).', 1, []);
    testCase.verifyEqual(psdDimensionsAt(rate, psdIdx), repmat([1 1], 1, 4));
end

function testEntrywiseScalarBlocksAndColumnMajorTargets(testCase)
    % One independent scalar certificate follows each MATLAB matrix entry.
    P = pdvar(2, {[0 1]}, "full", Degree=0);
    C = constructWithWarning(testCase, @() pdlmi(P, ">=", ...
        UsePutinar=true));
    coeffs = P.coeffs(1);
    targetIds = arrayfun(@(k) getvariables(coeffs{1}(k)), 1:4);

    testCase.verifyEqual(numel(C.Constraints), 4 * 2);
    testCase.verifyEqual(psdDimensionsAt(C, 1:2:8), ones(1, 4));
    verifyDisjointGramVariables(testCase, C, 1:2:8);
    for entry = 1:4
        metadata = struct(C.Constraints{2 * entry});
        matchedTargets = intersect(getvariables(metadata.List{1}), targetIds);
        testCase.verifyEqual(matchedTargets, targetIds(entry), ...
            "Coefficient identities must follow column-major entry order.");
    end
end

function testEntrywiseEveryCellAndRateRow(testCase)
    % Rectangular derivative rows receive independent scalar certificates.
    P = pdvar(2, 1, {[0 1 2]}, "full", RateBounds=[-1 1]);
    D = rhodiff(P);
    C = constructWithWarning(testCase, @() pdlmi(D, "<=", ...
        UsePutinar=true));

    % 2 cells * 2 rate rows * 2 entries * (1 PSD + 1 identity).
    testCase.verifyEqual(size(D.coeffs(1)), [2 1]);
    testCase.verifyEqual(numel(C.Constraints), 16);
    psdIdx = 1:2:16;
    testCase.verifyEqual(psdDimensionsAt(C, psdIdx), ones(1, 8));
    verifyDisjointGramVariables(testCase, C, psdIdx);
end

function verifyInactive(testCase, C)
    zero = zeros(1, C.Residual.npar());
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, zero);
end

function verifyPutinar(testCase, C, order, gramSizes, equalityCount)
    order = expandExpected(order, C.Residual.npar());
    zero = zeros(1, C.Residual.npar());
    testCase.verifyTrue(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, order);
    testCase.verifyFalse(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, zero);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, zero);
    testCase.verifyEqual(psdDimensions(C, numel(gramSizes)), gramSizes);
    testCase.verifyEqual(numel(C.Constraints), numel(gramSizes) + equalityCount);
end

function value = expandExpected(value, nPar)
    % Expand scalar shorthand only for expected public vector state.
    if isscalar(value)
        value = repmat(value, 1, nPar);
    else
        value = reshape(value, 1, []);
    end
end

function dims = psdDimensions(C, count)
    dims = zeros(1, count);
    for k = 1:count
        metadata = struct(C.Constraints{k});
        dims(k) = size(metadata.List{1}, 1);
    end
end

function dims = psdDimensionsAt(C, indices)
    dims = zeros(size(indices));
    for k = 1:numel(indices)
        metadata = struct(C.Constraints{indices(k)});
        dims(k) = size(metadata.List{1}, 1);
    end
end

function verifyDisjointGramVariables(testCase, C, indices)
    % Independent scalar certificates cannot share Gram decision handles.
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
