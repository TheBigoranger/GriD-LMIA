function tests = test_rate_rows_integration
    % Behavioral regressions for pdmat.rate_rows_integration.
    tests = functiontests(localfunctions);
end
function test_fixed_and_moving_rates_survive_ordered_products_and_assignment(testCase)
    % Products, transpose, and replacement retain row identity across every cell.
    f = @(x,y) [x^2+y, x*y; 3*x-y, y^2+1];
    grid = {[0 .5 2], [-1 0 3]};
    rb = [2 2; -3 5];
    A = pdmat(grid, f, Degree=[2 2], RateBounds=rb);
    D = rhodiff(A);
    left = [1 2; -3 4]; right = [2 -1; 5 3];
    C = (left*D*right).';
    C(:,2) = [11;13];
    testCase.verifyEqual(C.NumRateRows, 2);
    testCase.verifyEqual(C.RateBounds, rb);
    for x = [0 .25 .5 1.25 2]
        for y = [-1 -.5 0 1.5 3]
            values = C.evaluate([x y]);
            for row = 1:2
                rate = [-3 5];
                derivative = [4*x+rate(row), 2*y+x*rate(row); ...
                    6-rate(row), 2*y*rate(row)];
                expected = (left*derivative*right).';
                expected(:,2) = [11;13];
                testCase.verifyEqual(values{row}, expected, AbsTol=1e-9);
            end
        end
    end
end

function test_ratebounds_alone_metadata_existing_public_source(testCase)
    % RateBounds alone is metadata for every existing public source family.
    rb = [-2 3];
    values = {
        pdmat([0 1], @(rho) rho, RateBounds=rb), ...
        pdmat([0 1], @(rho) rho, Degree=1, RateBounds=rb), ...
        pdmat([0 1], {0, 1}, Degree=1, RateBounds=rb), ...
        pdmat([0 1], {{0, 1}}, Degree=1, RateBounds=rb)
        };

    for k = 1:numel(values)
        A = values{k};
        testCase.verifyEqual(A.RateBounds, rb);
        testCase.verifyEqual(size(A.coeffs(1), 1), 1);
    end
end

function test_mismatch_confined_second_rate_row_mark(testCase)
    % A mismatch confined to the second rate row must mark the object discontinuous.
    rb = [-1 2];
    aligned = pdmat([0 1], {{1, 3; 10, 14}}, ...
        Degree=1, RateBounds=rb);
    vals = {
        {1, 2; 10, 20}, ...
        {2, 3; 999, 30}
        };

    broken = constructWithWarning(testCase, ...
        @() pdmat([0 1 2], vals, Degree=1, RateBounds=rb), ...
        "pdmat:DiscontinuousLocalValues");

    testCase.verifyTrue(aligned.IsContinuous);
    testCase.verifyFalse(broken.IsContinuous);
    testCase.verifyEqual(size(aligned.coeffs(1)), [2 2]);
    testCase.verifyEqual(aligned.evaluate(0.25), {1.5, 11}, ...
        AbsTol=1e-12);
end

function test_explicit_rows_require_exact_grids_matching(testCase)
    % Explicit rows require exact grids and matching nonempty rate bounds.
    R = rateScalar();
    otherGrid = pdmat([0 0.5 1], {1, 2, 3}, ...
        Degree=1, RateBounds=[-1 2]);
    otherBounds = pdmat([0 1], {1, 2}, ...
        Degree=1, RateBounds=[0 2]);

    testCase.verifyError(@() R + otherGrid, "pdmat:InvalidAddition");
    testCase.verifyError(@() R + otherBounds, "pdmat:InvalidAddition");

    Z = R - R;
    testCase.verifyEqual(Z.Degree, 0);
    testCase.verifyEqual(Z.coeffs(1), {0});
    testCase.verifyEmpty(Z.RateBounds);
end

function test_leaf_touching_operations_both_rows_metadata(testCase)
    % Leaf-touching operations must retain both rows and their metadata.
    leaf = {
        [1 2; 3 4], [5 6; 7 8]
        [10 20; 30 40], [50 60; 70 80]
        };
    R = pdmat([0 1], {leaf}, Degree=1, RateBounds=[-1 2]);
    A = pdmat([0 1], {eye(2), 2 * eye(2)}, ...
        Degree=1, RateBounds=[-1 2]);

    T = R.';
    S = sum(R, 2);
    H = [R, A];
    B = blkdiag(R, A);
    C = R(:, 1);
    R(1, :) = pdmat([0 1], {{[9 8], [7 6]; [5 4], [3 2]}}, ...
        Degree=1, RateBounds=[-1 2]);

    verifyRateMeta(testCase, T, [2 2]);
    verifyRateMeta(testCase, S, [2 1]);
    verifyRateMeta(testCase, H, [2 4]);
    verifyRateMeta(testCase, B, [4 4]);
    verifyRateMeta(testCase, C, [2 1]);
    verifyRateMeta(testCase, R, [2 2]);
    tCoeff = T.coeffs(1);
    sCoeff = S.coeffs(1);
    hCoeff = H.coeffs(1);
    bCoeff = B.coeffs(1);
    cCoeff = C.coeffs(1);
    rCoeff = R.coeffs(1);
    testCase.verifyEqual(tCoeff{2, 2}, [50 70; 60 80]);
    testCase.verifyEqual(sCoeff{2, 1}, [30; 70]);
    testCase.verifyEqual(hCoeff{2, 1}, [10 20 1 0; 30 40 0 1]);
    testCase.verifyEqual(bCoeff{2, 2}, ...
        blkdiag([50 60; 70 80], 2 * eye(2)));
    testCase.verifyEqual(cCoeff{2, 1}, [10; 30]);
    testCase.verifyEqual(rCoeff{2, 2}, [3 2; 70 80]);
end

function test_inspection_plotting_preserve_deterministic_rate_row(testCase)
    % Inspection and plotting preserve deterministic rate-row order.
    R = rateScalar();
    elevated = R.elevate(1);
    tbl = bernTable(R);
    short = evalc("disp(R)");
    detail = evalc("display(R)");

    testCase.verifyEqual(elevated.coeffs(1), ...
        {1, 2, 3; 10, 12, 14});
    testCase.verifyEqual(tbl.RateVertexIndex, [1; 1; 2; 2]);
    testCase.verifyEqual(tbl.RateVertex, {-1; -1; 2; 2});
    testCase.verifyTrue(contains(short, "rate rows true"));
    testCase.verifyTrue(contains(detail, "Explicit rate rows: true"));

    fig = figure(Visible="off");
    cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
    h1 = plot(R, SamplesPerCell=2, LineWidth=2);
    y1 = h1.YData;
    h2 = plot(R, SamplesPerCell=2, RateVertex=2, LineWidth=3);
    testCase.verifyEqual(y1, [1 2 3], AbsTol=1e-12);
    testCase.verifyEqual(h2.YData, [10 12 14], AbsTol=1e-12);
    testCase.verifyEqual(h2.LineWidth, 3);
    testCase.verifyError(@() plot(R, RateVertex=3), ...
        "pdmat:InvalidRateVertex");
    ordinary = pdmat([0 1], {1, 2}, Degree=1);
    testCase.verifyError(@() plot(ordinary, RateVertex=1), ...
        "pdmat:InvalidRateVertex");
end

function R = rateScalar()
    % A two-row scalar fixture with one physical cell.
    R = pdmat([0 1], {{1, 3; 10, 14}}, ...
        Degree=1, RateBounds=[-1 2]);
end

function verifyRateMeta(testCase, obj, sz)
    % Explicit rows remain rate-dependent and preserve their matrix shape.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.RateBounds, [-1 2]);
    testCase.verifyEqual(size(obj.coeffs(1), 1), 2);
end

function obj = constructWithWarning(testCase, fcn, warningId)
    % Capture one expected construction warning and retain the object.
    obj = [];
    testCase.verifyWarning(@construct, warningId);

    function construct
        obj = fcn();
    end
end
