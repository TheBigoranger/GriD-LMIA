function tests = test_matrix_ops
    %TEST_MATRIX_OPS pdbase-owned structural matrix operations.
    tests = functiontests(localfunctions);
end

function testAllUnaMatMapTra(testCase)
    % Every unary family must preserve rate-row and Bernstein order.
    vals = {
        [1 2 3; 4 5 6], [11 12 13; 14 15 16]; ...
        [21 22 23; 24 25 26], [31 32 33; 34 35 36]
        };
    obj = makeRateObject(vals);

    verifyMapped(testCase, obj, obj.', @(a) a.', [3 2]);
    verifyMapped(testCase, obj, obj', @(a) a', [3 2]);
    verifyMapped(testCase, obj, -obj, @(a) -a, [2 3]);
    verifyMapped(testCase, obj, flip(obj, 2), @(a) flip(a, 2), [2 3]);
    verifyMapped(testCase, obj, fliplr(obj), @fliplr, [2 3]);
    verifyMapped(testCase, obj, flipud(obj), @flipud, [2 3]);
    verifyMapped(testCase, obj, rot90(obj), @rot90, [3 2]);
    verifyMapped(testCase, obj, trace(obj), @mainTrace, [1 1]);
    verifyMapped(testCase, obj, tril(obj, -1), @(a) tril(a, -1), [2 3]);
    verifyMapped(testCase, obj, triu(obj, 1), @(a) triu(a, 1), [2 3]);
    verifyMapped(testCase, obj, vec(obj), @(a) a(:), [6 1]);
end

function testLegAffStrMapCon(testCase)
    % Legacy affine payloads retain their fields and parameter-rate order.
    first = struct( ...
        Constant=[1 2 3; 4 5 6], ...
        Rate={{[7 8 9; 10 11 12]}});
    second = struct( ...
        Constant=[13 14 15; 16 17 18], ...
        Rate={{[19 20 21; 22 23 24]}});
    obj = pdbase({[0 1]}, [2 3], 1, {{first, second}}, ...
        RateBounds=[-3 5], SourceSummary="legacy-affine");

    actual = rot90(obj, -1);
    coeffs = actual.coeffs(1);

    testCase.verifyClass(actual, "pdbase");
    testCase.verifyEqual(size(actual), [3 2]);
    testCase.verifyEqual(size(coeffs), [1 2]);
    testCase.verifyEqual(coeffs{1}.Constant, rot90(first.Constant, -1));
    testCase.verifyEqual(coeffs{1}.Rate{1}, rot90(first.Rate{1}, -1));
    testCase.verifyEqual(coeffs{2}.Constant, rot90(second.Constant, -1));
    testCase.verifyEqual(coeffs{2}.Rate{1}, rot90(second.Rate{1}, -1));
    verifyMetadata(testCase, obj, actual);
end

function testSumAndMeaVecDim(testCase)
    % Vecdim reductions map each rate row and reject malformed dimensions.
    vals = {
        [1 2 3; 4 5 6], [10 20 30; 40 50 60]; ...
        [7 8 9; 10 11 12], [70 80 90; 100 110 120]
        };
    obj = makeRateObject(vals);

    summed = sum(obj, [1 2 3]);
    averaged = mean(obj, [1 3]);
    verifyMapped(testCase, obj, summed, @(a) sum(a, "all"), [1 1]);
    verifyMapped(testCase, obj, averaged, @(a) mean(a, 1), [1 3]);

    testCase.verifyError(@() sum(obj, [1 1]), "pdbase:InvalidSum");
    testCase.verifyError(@() sum(obj, []), "pdbase:InvalidSum");
    testCase.verifyError(@() mean(obj, [2 2]), "pdbase:InvalidMean");
    testCase.verifyError(@() mean(obj, 0), "pdbase:InvalidMean");
    testCase.verifyError(@() mean(obj, "rows"), "pdbase:InvalidMean");
end

function testCumRevAndHigDim(testCase)
    % Reverse accumulation is coefficient-local; dim > 2 is a matrix no-op.
    vals = {
        [1 2 3; 4 5 6], [10 20 30; 40 50 60]; ...
        [7 8 9; 10 11 12], [70 80 90; 100 110 120]
        };
    obj = makeRateObject(vals);

    reversed = cumsum(obj, 2, "reverse");
    defaultReverse = cumsum(obj, "reverse");
    higherDim = cumsum(obj, 4, "reverse");
    defaultForward = cumsum(obj);
    scalarReverse = cumsum(pdbase({[0 1]}, [1 1], 0), "reverse");
    verifyMapped(testCase, obj, reversed, ...
        @(a) flip(cumsum(flip(a, 2), 2), 2), [2 3]);
    verifyMapped(testCase, obj, defaultReverse, ...
        @(a) flip(cumsum(flip(a, 1), 1), 1), [2 3]);
    verifyMapped(testCase, obj, higherDim, @(a) a, [2 3]);
    verifyMapped(testCase, obj, defaultForward, @cumsum, [2 3]);
    testCase.verifyEqual(scalarReverse.coeffs(1), {0});

    testCase.verifyError(@() cumsum(obj, 0), "pdbase:InvalidCumsum");
    testCase.verifyError(@() cumsum(obj, 1, "backward"), ...
        "pdbase:InvalidCumsum");
    testCase.verifyError(@() cumsum(obj, 1, "reverse", "omitmissing"), ...
        "pdbase:InvalidCumsum");
    testCase.verifyError(@() cumsum(obj, 1, struct()), ...
        "pdbase:InvalidCumsum");
end

function testResAndRepMapPay(testCase)
    % Valid 2-D transforms preserve order; N-D requests remain unsupported.
    vals = {
        [1 2 3; 4 5 6], [10 20 30; 40 50 60]; ...
        [7 8 9; 10 11 12], [70 80 90; 100 110 120]
        };
    obj = makeRateObject(vals);

    reshaped = reshape(obj, 3, []);
    repeated = repmat(obj, [2 1]);
    repeatedScalar = repmat(obj, 2);
    flippedDefault = flip(obj);
    verifyMapped(testCase, obj, reshaped, @(a) reshape(a, 3, 2), [3 2]);
    verifyMapped(testCase, obj, repeated, @(a) repmat(a, 2, 1), [4 3]);
    verifyMapped(testCase, obj, repeatedScalar, @(a) repmat(a, 2), [4 6]);
    verifyMapped(testCase, obj, flippedDefault, @flip, [2 3]);

    testCase.verifyError(@() reshape(obj, 1, 2, 3), ...
        "pdbase:InvalidReshape");
    testCase.verifyError(@() reshape(obj, [1 2 3]), ...
        "pdbase:InvalidReshape");
    testCase.verifyError(@() reshape(obj, [], []), ...
        "pdbase:InvalidReshape");
    testCase.verifyError(@() reshape(obj, 4, []), ...
        "pdbase:InvalidReshape");
    testCase.verifyError(@() repmat(obj, 1, 1, 1), ...
        "pdbase:InvalidRepmat");
    testCase.verifyError(@() repmat(obj, [1 1 1]), ...
        "pdbase:InvalidRepmat");
end

function testIndEndLogAndGriDim(testCase)
    % MATLAB end contexts and logical shapes reach the shared index guards.
    A = pdmat({[0 1]}, {reshape(1:6, 2, 3), zeros(2, 3)}, Degree=1);
    B = pdmat({[0 1], [10 20]}, @(x, y) x + 0 * y, Degree=[1 1]);

    testCase.verifyError(@() linearEnd(A), "pdmat:InvalidSubscript");
    testCase.verifyError(@() higherEnd(A), "pdmat:InvalidSubscript");
    testCase.verifyError(@() A([true false; false true], :), ...
        "pdmat:InvalidSubscript");
    testCase.verifyError(@() A + B, "pdmat:MixedGrid");
end

function linearEnd(A)
    % One-subscript syntax evaluates end before pdmat rejects linear indexing.
    A(end);
end

function higherEnd(A)
    % A trailing subscript evaluates the singleton higher-dimensional end.
    A(1, 1, end);
end

function testDiaMapEvePayAnd(testCase)
    % Matrix diagonals map directly, while empty results are unrepresentable.
    vals = {
        [1 2 3; 4 5 6], [10 20 30; 40 50 60]; ...
        [7 8 9; 10 11 12], [70 80 90; 100 110 120]
        };
    obj = makeRateObject(vals);

    diagonal = diag(obj, 1);
    verifyMapped(testCase, obj, diagonal, @(a) diag(a, 1), [2 1]);

    testCase.verifyError(@() diag(obj, 3), "pdbase:InvalidDiag");
    testCase.verifyError(@() diag(obj, -2), "pdbase:InvalidDiag");
    testCase.verifyError(@() diag(obj, 0.5), "pdbase:InvalidDiag");
end

function testTraVecIsScaAnd(testCase)
    % Shared trace is scalar for vectors; unsupported reduction flags fail.
    obj = pdbase({[0 1]}, [1 3], 1, {{[1 2 3], [4 5 6]}});

    actual = trace(obj);

    testCase.verifyEqual(size(actual), [1 1]);
    testCase.verifyEqual(actual.coeffs(1), {1, 4});
    testCase.verifyError(@() sum(obj, 1, "native"), "pdbase:InvalidSum");
    testCase.verifyError(@() mean(obj, 1, "omitmissing"), ...
        "pdbase:InvalidMean");
end

function obj = makeRateObject(vals)
    %MAKERATEOBJECT One cell with two rate rows and two coefficients.
    obj = pdbase({[0 1]}, [2 3], 1, {vals}, ...
        IsContinuous=true, ContainsDecision=true, ...
        RateBounds=[-2 4], SourceSummary="matrix-ops-fixture");
end

function verifyMapped(testCase, source, actual, fcn, expectedSize)
    %VERIFYMAPPED Assert every rate-row-by-coefficient payload directly.
    before = source.coeffs(1);
    after = actual.coeffs(1);

    testCase.verifyClass(actual, "pdbase");
    testCase.verifyEqual(size(actual), expectedSize);
    testCase.verifyEqual(size(after), size(before));
    for rateRow = 1:size(before, 1)
        for coeff = 1:size(before, 2)
            testCase.verifyEqual(after{rateRow, coeff}, ...
                fcn(before{rateRow, coeff}));
        end
    end
    verifyMetadata(testCase, source, actual);
end

function verifyMetadata(testCase, source, actual)
    %VERIFYMETADATA Structural maps must not reorder or drop base metadata.
    testCase.verifyEqual(actual.GridInfo, source.GridInfo);
    testCase.verifyEqual(actual.Degree, source.Degree);
    testCase.verifyEqual(actual.IsContinuous, source.IsContinuous);
    testCase.verifyEqual(actual.ContainsDecision, source.ContainsDecision);
    testCase.verifyEqual(actual.RateBounds, source.RateBounds);
    testCase.verifyEqual(actual.SourceSummary, source.SourceSummary);
end

function val = mainTrace(val)
    %MAINTRACE Sum the main diagonal of a possibly rectangular matrix.
    n = min(size(val));
    idx = 1:(size(val, 1) + 1):(1 + (n - 1) * (size(val, 1) + 1));
    val = sum(val(idx));
end
