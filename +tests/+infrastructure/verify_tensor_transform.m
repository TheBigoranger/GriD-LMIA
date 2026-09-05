function verify_tensor_transform(testCase, owner, transform, mode, reference, expectedContinuity)
    %VERIFY_TENSOR_TRANSFORM Check rectangular maps on nonuniform tensor cells.
    % Mode selects ordinary, one fixed derivative row, or mixed-rate rows.
    % Native matrix operations are the oracle; no transformed package object
    % contributes expected values. Derivative correctness has separate tests.
    if nargin < 5, reference = transform; end
    grid = {[0 2 5], [-3 1 6]};
    bounds = [3 3; -2 5];
    if mode == "fixed", bounds = [3 3; -2 -2]; end
    if owner == "pdvar"
        source = pdvar(2, 3, grid, 'full', Degree=[0 2], RateBounds=bounds);
    elseif owner == "pdmat"
        source = pdmat(grid, @(x,y) [y^2, 3*y+7, -y; ...
            2*y^2+1, y-4, 5-y^2], ...
            Degree=[0 2], RateBounds=bounds);
    else
        values = cell(1,2);
        for i = 1:2
            values{i} = cell(1,2);
            for j = 1:2
                leaf = cell(1,3);
                for k = 1:3
                    t = 100*i + 10*j + k;
                    leaf{k} = [t, -k*t, j+t^2; i-k, 3*t, -t^2];
                end
                values{i}{j} = leaf;
            end
        end
        source = pdbase(grid, [2 3], [0 2], values, RateBounds=bounds);
    end
    if mode ~= "ordinary", source = rhodiff(source); end
    % Callers may specify independently known continuity after reconstruction;
    % pdmat maps reclassify the global polynomial fixture, unlike identity maps.
    if nargin < 6, expectedContinuity = source.IsContinuous; end
    saved = source.LocalValues;
    actual = transform(source);
    for i = 1:2
        for j = 1:2
            input = source.coeffs([i j]);
            expected = cellfun(reference, input, 'UniformOutput', false);
            tests.infrastructure.verify_expr(testCase, actual.coeffs([i j]), expected);
        end
    end
    testCase.verifyEqual(actual.MatrixSize, size(expected{1}));
    testCase.verifyEqual(source.LocalValues, saved);
    testCase.verifyEqual(actual.GridInfo, source.GridInfo);
    testCase.verifyEqual(actual.Degree, source.Degree);
    testCase.verifyEqual(actual.RateBounds, source.RateBounds);
    testCase.verifyEqual(actual.NumRateRows, source.NumRateRows);
    testCase.verifyEqual(actual.ContainsDecision, source.ContainsDecision);
    testCase.verifyEqual(actual.IsContinuous, expectedContinuity);
    testCase.verifyClass(actual, owner);
end
