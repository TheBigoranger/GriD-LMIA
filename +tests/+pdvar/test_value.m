function tests = test_value
    %TEST_VALUE Assigned pdvar conversion to coefficient-backed pdmat data.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP assignments so unassigned-value checks stay deterministic.
    yalmip("clear");
end

function testAssHigDegMatCon(testCase)
    % Ordinary assigned decisions retain their complete Bernstein contract.
    grid = {[0 2]};
    P = pdvar(2, grid, "full", Degree=2);
    cp = P.coeffs(1);
    expected = {
        [1 2; 3 4], ...
        [5 6; 7 8], ...
        [9 10; 11 12]
    };
    assignCoeffs(cp, expected);

    A = value(P);

    testCase.verifyClass(A, "pdmat");
    testCase.verifyEqual(A.GridInfo.Vectors, grid);
    testCase.verifyEqual(size(A), [2 2]);
    testCase.verifyEqual(A.Degree, 2);
    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyFalse(A.ContainsDecision);
    testCase.verifyEmpty(A.RateBounds);
    testCase.verifyEqual(A.SourceSummary, "coefficient-backed");
    testCase.verifyEmpty(A.FunctionHandle);
    verifyNumericCoeffs(testCase, A.coeffs(1), expected);
    testCase.verifyEqual(A.evaluate(0), expected{1}, AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(1), ...
        0.25 * expected{1} + 0.5 * expected{2} + 0.25 * expected{3}, ...
        AbsTol=1e-12);
    testCase.verifyEqual(A.evaluate(2), expected{3}, AbsTol=1e-12);
end

function testNumAndProZerCon(testCase)
    % Proven symbolic cancellations become ordinary numeric coefficient data.
    P = pdvar(2, {[0 1]}, "full", Degree=3);
    Z = P - P;

    A = value(Z);

    testCase.verifyClass(A, "pdmat");
    testCase.verifyEqual(A.Degree, 0);
    testCase.verifyEqual(A.coeffs(1), {zeros(2)});
    testCase.verifyEqual(A.evaluate(0.37), zeros(2));
end

function testUnaCoeFaiCle(testCase)
    % Unsolved YALMIP decisions must not leak NaN payloads into pdmat.
    P = pdvar(1, {[0 1]}, Degree=2);

    testCase.verifyError(@() value(P), "pdvar:UnassignedValue");
end

function testOrdRatMetStiRet(testCase)
    % RateBounds metadata alone does not make ordinary coefficients rate rows.
    P = pdvar(1, {[0 1]}, Degree=2, RateBounds=[-1 2]);
    cp = P.coeffs(1);
    assignCoeffs(cp, {1, 2, 4});

    A = value(P);

    testCase.verifyClass(A, "pdmat");
    testCase.verifyEqual(A.coeffs(1), {1, 2, 4});
    testCase.verifyEmpty(A.RateBounds);
end

function testScaDerRetOrdPdm(testCase)
    % Scalar rate rows split into lower/upper pdmat outputs without warnings.
    P = pdvar(1, {[0 2]}, Degree=2);
    assignCoeffs(P.coeffs(1), {1, 4, 9});
    D = rhodiff(P, [-2 3]);

    lastwarn("");
    rows = value(D);
    [warnMsg, ~] = lastwarn;

    testCase.verifyEmpty(warnMsg);
    testCase.verifySize(rows, [1 2]);
    verifyRatePdmat(testCase, rows{1}, 1, [-6, -10]);
    verifyRatePdmat(testCase, rows{2}, 1, [9, 15]);
end

function testFixRatRetOnePdm(testCase)
    % A fixed rate exports one pdmat while preserving the derivative row kind.
    P = pdvar(1, {[0 2]}, Degree=2);
    assignCoeffs(P.coeffs(1), {1, 4, 9});
    D = rhodiff(P, [3 3]);

    rows = value(D);

    testCase.verifySize(rows, [1 1]);
    verifyRatePdmat(testCase, rows{1}, 1, [9, 15]);
end

function testTenDerRetComRow(testCase)
    % Tensor rate cells retain helper.combRows lower/upper vertex order.
    grid = {[0 2], [10 14]};
    rb = [-1 2; -3 5];
    P = pdvar(1, grid, Degree=[2 2]);
    cp = P.coeffs([1 1]);
    lbls = helper.combRows({0:2, 0:2});
    expectedP = arrayfun(@(k) 5 + 2 * lbls(k, 1) + 3 * lbls(k, 2), ...
        1:size(lbls, 1), UniformOutput=false);
    assignCoeffs(cp, expectedP);
    D = rhodiff(P, rb);

    lastwarn("");
    rows = value(D);
    [warnMsg, ~] = lastwarn;

    verts = helper.combRows(num2cell(rb, 2).');
    expectedRows = 2 * verts(:, 1) + 1.5 * verts(:, 2);
    testCase.verifyEmpty(warnMsg);
    testCase.verifySize(rows, [1 4]);
    for k = 1:4
        verifyRatePdmat(testCase, rows{k}, [2 2], ...
            repmat(expectedRows(k), 1, 9));
        testCase.verifyEqual(rows{k}.GridInfo.Vectors, grid);
    end
end

function testAssAniMulConIs(testCase)
    % Assigned values, not stale source metadata, determine exported continuity.
    degree = [0 2];
    grid = {[0 1 2], [10 20]};
    continuous = internalNumericPdvar(grid, degree, ...
        helper.mkNest([2 1], @(~) num2cell([1, 2, 3])));
    discontinuousValues = continuous.LocalValues;
    discontinuousValues{2}{1}{1} = 20;
    discontinuous = internalNumericPdvar(grid, degree, discontinuousValues);

    A = value(continuous);
    B = value(discontinuous);

    testCase.verifyEqual(A.Degree, degree);
    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyFalse(B.IsContinuous);
    secondCell = B.coeffs([2 1]);
    testCase.verifyEqual(secondCell{1}, 20);
end

function testAssCanRecComFacCon(testCase)
    % Assigned cancellation can recover continuity from symbolic face mismatch.
    x = sdpvar(1, 1);
    y = sdpvar(1, 1);
    vals = {{0, x - y}, {0, 1}};
    P = internalNumericPdvar({[0 1 2]}, 1, vals);
    assign(x, 3);
    assign(y, 3);

    A = value(P);

    testCase.verifyFalse(P.IsContinuous);
    testCase.verifyTrue(A.IsContinuous);
    testCase.verifyTrue(helper.chkCont(A.LocalValues, [2], 1));
end

function testAssTenFacAndTolMatHel(testCase)
    % value uses the shared full-tensor, scale-aware continuity classifier.
    grid = {[0 1 2], [10 20 30]};
    degree = [1 1];
    vals = helper.mkNest([2 2], @continuousTensorLeaf);

    within = vals;
    within{2}{2}{1} = within{2}{2}{1} + 5e-4;
    outside = vals;
    outside{2}{2}{1} = outside{2}{2}{1} + 2e-3;

    expectedWithin = helper.chkCont(within, [2 2], degree);
    expectedOutside = helper.chkCont(outside, [2 2], degree);
    A = value(internalNumericPdvar(grid, degree, within));
    B = value(internalNumericPdvar(grid, degree, outside));

    testCase.verifyTrue(expectedWithin);
    testCase.verifyFalse(expectedOutside);
    testCase.verifyEqual(A.IsContinuous, expectedWithin);
    testCase.verifyEqual(B.IsContinuous, expectedOutside);
end

function assignCoeffs(coeffs, vals)
    % Assign deterministic numeric matrices to one ordinary coefficient row.
    for k = 1:numel(coeffs)
        assign(coeffs{k}, vals{k});
    end
end

function verifyNumericCoeffs(testCase, actual, expected)
    % Numeric pdmat coefficients should retain local order and payload values.
    testCase.verifyEqual(size(actual), size(expected));
    for k = 1:numel(expected)
        testCase.verifyEqual(actual{k}, expected{k}, AbsTol=1e-12);
    end
end

function verifyRatePdmat(testCase, obj, degree, expected)
    % Converted derivative rows are known, discontinuous, and rate-metadata free.
    testCase.verifyClass(obj, "pdmat");
    testCase.verifyEqual(obj.Degree, degree);
    testCase.verifyFalse(obj.IsContinuous);
    testCase.verifyFalse(obj.ContainsDecision);
    testCase.verifyEmpty(obj.RateBounds);
    testCase.verifyEqual(obj.SourceSummary, "coefficient-backed");
    testCase.verifyEmpty(obj.FunctionHandle);
    verifyNumericCoeffs(testCase, obj.coeffs(ones(1, obj.npar())), ...
        num2cell(expected));
end

function obj = internalNumericPdvar(grid, degree, vals)
    % Build assigned numeric cells whose face agreement is independently controlled.
    init = struct( ...
        "PdvarInternal", true, ...
        "Grid", {grid}, ...
        "MatrixSize", [1 1], ...
        "Degree", degree, ...
        "LocalValues", {vals}, ...
        "IsContinuous", false, ...
        "ContainsDecision", false, ...
        "RateBounds", [], ...
        "SourceSummary", "test-assigned-continuity", ...
        "ValidationMode", "strict");
    obj = pdvar(init);
end

function leaf = continuousTensorLeaf(subs)
    % Global tensor labels make every shared face agree at a large scale.
    labels = helper.combRows({0:1, 0:1});
    leaf = cell(1, size(labels, 1));
    for k = 1:size(labels, 1)
        globalLabel = subs - 1 + labels(k, :);
        leaf{k} = 1e6 + 100 * globalLabel(1) + globalLabel(2);
    end
end
