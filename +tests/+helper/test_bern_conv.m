function tests = test_bern_conv
    %TEST_BERN_CONV Check stable Bernstein convolution weights and ratios.
    tests = functiontests(localfunctions);
end

function testWeightsMatchDirectFormula(testCase)
    % Moderate degrees retain the independently computed binomial values.
    for degree = [0 1 2 7 16 32]
        labels = (0:degree).';
        actual = helper.bernConvWeights(labels, degree);
        expected = arrayfun(@(k) nchoosek(degree, k), labels) ./ 2 ^ degree;
        verifyScaled(testCase, actual, expected, 128);
    end

    degree = [4 3];
    labels = helper.combRows({0:degree(1), 0:degree(2)});
    actual = helper.bernConvWeights(labels, degree);
    expected = arrayfun(@(k) nchoosek(degree(1), k), labels(:, 1)) ...
        .* arrayfun(@(k) nchoosek(degree(2), k), labels(:, 2)) ...
        ./ 2 ^ sum(degree);
    verifyScaled(testCase, actual, expected, 128);
end

function testRatiosMatchDirectFormula(testCase)
    % Four arguments cover ordinary product and elevation ratios.
    lhsDegree = [4 2];
    rhsDegree = [3 1];
    lhsLabels = [0 0; 1 2; 2 1; 4 2];
    rhsLabels = [0 1; 2 0; 3 1; 1 0];
    outputLabels = lhsLabels + rhsLabels;
    actual = helper.bernConvRatios( ...
        lhsLabels, lhsDegree, rhsLabels, rhsDegree);
    expected = directRatios(lhsLabels, lhsDegree, rhsLabels, ...
        rhsDegree, outputLabels, lhsDegree + rhsDegree);
    verifyScaled(testCase, actual, expected, 128);

    % Six arguments cover Gram generator shifts in numerator labels/degrees.
    outputDegree = [9 5];
    outputLabels = lhsLabels + rhsLabels + [1 2];
    actual = helper.bernConvRatios(lhsLabels, lhsDegree, ...
        rhsLabels, rhsDegree, outputLabels, outputDegree);
    expected = directRatios(lhsLabels, lhsDegree, rhsLabels, ...
        rhsDegree, outputLabels, outputDegree);
    verifyScaled(testCase, actual, expected, 128);
end

function testDegree1030RemainsFinite(testCase)
    % Degree 1030 is the first required range where central nchoosek overflows.
    degree = 1030;
    weights = helper.bernConvWeights((0:degree).', degree);

    testCase.verifyTrue(all(isfinite(weights)));
    testCase.verifyGreaterThanOrEqual(weights, zeros(size(weights)));
    testCase.verifyGreaterThan(weights([1 end]), zeros(2, 1));
    testCase.verifyEqual(weights, flipud(weights));
    testCase.verifyLessThanOrEqual(abs(sum(weights) - 1), 256 * eps);

    labels = [0; 257; 515];
    ratios = helper.bernConvRatios(labels, 515, labels, 515);
    shiftedLabels = [0; 257; 514];
    shifted = helper.bernConvRatios(shiftedLabels, 514, ...
        shiftedLabels, 514, 2 * shiftedLabels + 1, 1030);
    testCase.verifyTrue(all(isfinite(ratios)));
    testCase.verifyTrue(all(isfinite(shifted)));
    testCase.verifyGreaterThanOrEqual(ratios, zeros(size(ratios)));
    testCase.verifyGreaterThanOrEqual(shifted, zeros(size(shifted)));
end

function testInvalidLabelsFailClearly(testCase)
    % Shared helpers reject misaligned or out-of-range internal label tables.
    testCase.verifyError(@() helper.bernConvWeights([0 1], 2), ...
        "helper:InvalidBernConvWeights");
    testCase.verifyError(@() helper.bernConvWeights([-1; 0], 1), ...
        "helper:InvalidBernConvWeights");
    testCase.verifyError(@() helper.bernConvRatios([0; 1], 1, 0, 1), ...
        "helper:InvalidBernConvRatios");
    testCase.verifyError(@() helper.bernConvRatios([0; 1], 1, ...
        [0; 1; 0], 1), "helper:InvalidBernConvRatios");
    testCase.verifyError(@() helper.bernConvRatios(0, 1, 0, 1, 3, 2), ...
        "helper:InvalidBernConvRatios");
end

function ratios = directRatios(lhsLabels, lhsDegree, rhsLabels, ...
        rhsDegree, outputLabels, outputDegree)
    %DIRECTRATIOS Keep the low-degree oracle independent of production code.
    ratios = ones(size(lhsLabels, 1), 1);
    for dim = 1:numel(lhsDegree)
        ratios = ratios ...
            .* arrayfun(@(k) nchoosek(lhsDegree(dim), k), lhsLabels(:, dim)) ...
            .* arrayfun(@(k) nchoosek(rhsDegree(dim), k), rhsLabels(:, dim)) ...
            ./ arrayfun(@(k) nchoosek(outputDegree(dim), k), ...
                outputLabels(:, dim));
    end
end

function verifyScaled(testCase, actual, expected, factor)
    %VERIFYSCALED Compare formulas at a scale-aware machine tolerance.
    scale = max(1, norm(expected, inf));
    testCase.verifyLessThanOrEqual(norm(actual - expected, inf), ...
        factor * eps(scale));
end
