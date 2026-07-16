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
    tensor = pdlmi(pdvar(2, {[0 1], [0 1]}, Degree=2), ...
        ">=", UsePutinar=true);

    % Order zero omits both nominal negative-degree multiplier blocks.
    verifyPutinar(testCase, constant, 0, 2, 1);
    % One-dimensional odd targets use the Markov-Lukacs endpoint facets.
    verifyPutinar(testCase, odd, 1, [4 4], 4);
    verifyPutinar(testCase, tensor, 1, [8 4 4], 9);
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

function testMatrixValidationIdentifiers(testCase)
    rectangular = pdvar(2, 1, {[0 1]}, "full");
    nonsymmetric = pdvar(2, {[0 1]}, "full");

    testCase.verifyError(@() pdlmi(rectangular, "<=", ...
        UsePutinar=true), "pdlmi:InvalidMatrixSize");
    testCase.verifyError(@() pdlmi(nonsymmetric, "<=", ...
        UsePutinar=true), "pdlmi:NonSymmetricExpression");
end

function verifyInactive(testCase, C)
    testCase.verifyFalse(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, 0);
end

function verifyPutinar(testCase, C, order, gramSizes, equalityCount)
    testCase.verifyTrue(C.UsePutinar);
    testCase.verifyEqual(C.PutinarOrder, order);
    testCase.verifyFalse(C.UsePolya);
    testCase.verifyEqual(C.PolyaDegree, 0);
    testCase.verifyFalse(C.UseFullBoxPreorder);
    testCase.verifyEqual(C.FullBoxOrder, 0);
    testCase.verifyEqual(psdDimensions(C, numel(gramSizes)), gramSizes);
    testCase.verifyEqual(numel(C.Constraints), numel(gramSizes) + equalityCount);
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
