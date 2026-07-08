function tests = test_matrix_ops
    %TEST_MATRIX_OPS Focused dpvar structural matrix operations.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function testShapeInspectionAndUnaryPlus(testCase)
    % Matrix-like shape methods should report the dpvar payload dimensions.
    P = dpvar(2, 3, {[0 1]}, "full");

    testCase.verifyTrue(isequal(+P, P));
    testCase.verifyEqual(length(P), 3);
    testCase.verifyEqual(height(P), 2);
    testCase.verifyEqual(width(P), 3);
    testCase.verifyEqual(numel(P), 6);
    testCase.verifyEqual(ndims(P), 2);
    testCase.verifyTrue(isequal(squeeze(P), P));
end

function testTransposeCtransposeAndTrace(testCase)
    % Size-changing unary operations should map every coefficient payload.
    P = dpvar(2, 3, {[0 1]}, "full");
    Q = dpvar(2, {[0 1]}, "full");
    cp = P.coeffs(1);
    cq = Q.coeffs(1);

    T = P.';
    H = P';
    Tr = trace(Q);

    testCase.verifyEqual(size(T), [3 2]);
    testCase.verifyEqual(size(H), [3 2]);
    testCase.verifyEqual(size(Tr), [1 1]);
    verifyCoeffExpr(testCase, T.coeffs(1), {cp{1}.', cp{2}.'});
    verifyCoeffExpr(testCase, H.coeffs(1), {cp{1}', cp{2}'});
    verifyCoeffExpr(testCase, Tr.coeffs(1), {trace(cq{1}), trace(cq{2})});
end

function testCommonStructuralMethods(testCase)
    % Common MATLAB structural transforms should map every coefficient payload.
    P = dpvar(2, {[0 1]}, "full");
    cp = P.coeffs(1);

    V = vec(P);
    D = diag(P);
    R = reshape(P, [1 4]);
    L = tril(P);
    U = triu(P, 1);
    S1 = sum(P);
    S2 = sum(P, 2);
    Sa = sum(P, "all");
    M1 = mean(P);
    Ma = mean(P, "all");
    Cs = cumsum(P, 2);
    Fu = flipud(P);
    Fl = fliplr(P);
    Fp = flip(P, 2);
    Q = rot90(P);
    Rp = repmat(P, 1, 2);

    testCase.verifyEqual(size(V), [4 1]);
    testCase.verifyEqual(size(D), [2 1]);
    testCase.verifyEqual(size(R), [1 4]);
    testCase.verifyEqual(size(S1), [1 2]);
    testCase.verifyEqual(size(S2), [2 1]);
    testCase.verifyEqual(size(Sa), [1 1]);
    testCase.verifyEqual(size(M1), [1 2]);
    testCase.verifyEqual(size(Ma), [1 1]);
    testCase.verifyEqual(size(Rp), [2 4]);
    verifyCoeffExpr(testCase, V.coeffs(1), {cp{1}(:), cp{2}(:)});
    verifyCoeffExpr(testCase, D.coeffs(1), {diag(cp{1}), diag(cp{2})});
    verifyCoeffExpr(testCase, R.coeffs(1), {reshape(cp{1}, [1 4]), reshape(cp{2}, [1 4])});
    verifyCoeffExpr(testCase, L.coeffs(1), {tril(cp{1}), tril(cp{2})});
    verifyCoeffExpr(testCase, U.coeffs(1), {triu(cp{1}, 1), triu(cp{2}, 1)});
    verifyCoeffExpr(testCase, S1.coeffs(1), {sum(cp{1}), sum(cp{2})});
    verifyCoeffExpr(testCase, S2.coeffs(1), {sum(cp{1}, 2), sum(cp{2}, 2)});
    verifyCoeffExpr(testCase, Sa.coeffs(1), {sum(cp{1}, "all"), sum(cp{2}, "all")});
    verifyCoeffExpr(testCase, M1.coeffs(1), {mean(cp{1}), mean(cp{2})});
    verifyCoeffExpr(testCase, Ma.coeffs(1), {mean(cp{1}, "all"), mean(cp{2}, "all")});
    verifyCoeffExpr(testCase, Cs.coeffs(1), {cumsum(cp{1}, 2), cumsum(cp{2}, 2)});
    verifyCoeffExpr(testCase, Fu.coeffs(1), {flipud(cp{1}), flipud(cp{2})});
    verifyCoeffExpr(testCase, Fl.coeffs(1), {fliplr(cp{1}), fliplr(cp{2})});
    verifyCoeffExpr(testCase, Fp.coeffs(1), {flip(cp{1}, 2), flip(cp{2}, 2)});
    verifyCoeffExpr(testCase, Q.coeffs(1), {rot90(cp{1}), rot90(cp{2})});
    verifyCoeffExpr(testCase, Rp.coeffs(1), {repmat(cp{1}, 1, 2), repmat(cp{2}, 1, 2)});
    testCase.verifyFalse(isequal(P, D));
end

function testDiagConstructionAndReshapeInference(testCase)
    % Vector diag and one empty reshape dimension should follow MATLAB usage.
    P = dpvar(3, 1, {[0 1]}, "full");
    cp = P.coeffs(1);

    D = diag(P, 1);
    R = reshape(P, [], 1);

    testCase.verifyEqual(size(D), [4 4]);
    testCase.verifyEqual(size(R), [3 1]);
    verifyCoeffExpr(testCase, D.coeffs(1), {diag(cp{1}, 1), diag(cp{2}, 1)});
    verifyCoeffExpr(testCase, R.coeffs(1), {cp{1}, cp{2}});
end

function testConcatenationWithKnownAndNumericBlocks(testCase)
    % cat/horzcat/vertcat should combine compatible coefficient blocks.
    P = dpvar(2, 1, {[0 1]}, "full");
    A = dpmat({[0 1]}, {[10; 20], [30; 40]}, Degree=1);
    cp = P.coeffs(1);

    H = [P, A];
    V = [P; P];
    N = cat(2, P, 5);

    testCase.verifyEqual(size(H), [2 2]);
    testCase.verifyEqual(size(V), [4 1]);
    testCase.verifyEqual(size(N), [2 2]);
    verifyCoeffExpr(testCase, H.coeffs(1), {[cp{1}, [10; 20]], [cp{2}, [30; 40]]});
    verifyCoeffExpr(testCase, V.coeffs(1), {[cp{1}; cp{1}], [cp{2}; cp{2}]});
    verifyCoeffExpr(testCase, N.coeffs(1), {[cp{1}, 5 * ones(2, 1)], [cp{2}, 5 * ones(2, 1)]});
end

function testCatDegreeElevation(testCase)
    % Lower-degree blocks are elevated before coefficient-wise concatenation.
    P = dpvar(1, {[0 1]});
    B = dpmat({[0 1]}, {10, 20, 30}, Degree=2);
    cp = P.coeffs(1);

    C = [P, B];

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyEqual(size(C), [1 2]);
    verifyCoeffExpr(testCase, C.coeffs(1), { ...
        [cp{1}, 10], ...
        [0.5 * cp{1} + 0.5 * cp{2}, 20], ...
        [cp{2}, 30]});
end

function testCatSdpvarBlocks(testCase)
    % Affine sdpvar blocks promote to degree-0 coefficient data.
    P = dpvar(2, 1, {[0 1]}, "full");
    X = sdpvar(2, 1, 'full');
    cp = P.coeffs(1);

    C = [P, X];

    testCase.verifyEqual(size(C), [2 2]);
    verifyCoeffExpr(testCase, C.coeffs(1), {[cp{1}, X], [cp{2}, X]});
end

function testBlkdiagCommonGridAndNumeric(testCase)
    % blkdiag should align grids, elevate degree, and accept numeric blocks.
    P = dpvar(1, {[0 1]});
    B = dpmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    cp = P.coeffs(1);
    pMid = 0.5 * cp{1} + 0.5 * cp{2};

    C = blkdiag(P, 5, B);

    testCase.verifyEqual(size(C), [3 3]);
    testCase.verifyEqual(C.GridInfo.Vectors{1}, [0 0.5 1]);
    verifyCoeffExpr(testCase, C.coeffs(1), { ...
        diag([cp{1}, 5, 10]), ...
        diag([pMid, 5, 20])});
    verifyCoeffExpr(testCase, C.coeffs(2), { ...
        diag([pMid, 5, 20]), ...
        diag([cp{2}, 5, 30])});
end

function testMatrixSlicingAndDotAccess(testCase)
    % Matrix indexing should slice payloads while dot access stays available.
    P = dpvar(2, 3, {[0 1]}, "full");
    cp = P.coeffs(1);

    lastCol = P(:, end);
    topTail = P(1, 2:3);
    firstRow = P([true false], :);
    coeffs = P.coeffs(1);

    testCase.verifyEqual(size(lastCol), [2 1]);
    testCase.verifyEqual(size(topTail), [1 2]);
    testCase.verifyEqual(size(firstRow), [1 3]);
    verifyCoeffExpr(testCase, coeffs, cp);
    verifyCoeffExpr(testCase, lastCol.coeffs(1), {cp{1}(:, 3), cp{2}(:, 3)});
    verifyCoeffExpr(testCase, topTail.coeffs(1), {cp{1}(1, 2:3), cp{2}(1, 2:3)});
    verifyCoeffExpr(testCase, firstRow.coeffs(1), {cp{1}(1, :), cp{2}(1, :)});
end

function testSubsasgnNumericAndDpvarBlocks(testCase)
    % Subscript assignment should accept numeric constants and dpvar blocks.
    P = dpvar(2, {[0 1]}, "full");
    cp = P.coeffs(1);
    P(:, 2) = 5;

    verifyCoeffExpr(testCase, P.coeffs(1), { ...
        [cp{1}(:, 1), 5 * ones(2, 1)], ...
        [cp{2}(:, 1), 5 * ones(2, 1)]});

    B = dpmat({[0 1]}, {[10 20], [30 40], [50 60]}, Degree=2);
    P(1, :) = B;

    testCase.verifyEqual(P.Degree, 2);
    verifyCoeffExpr(testCase, P.coeffs(1), { ...
        [10 20; cp{1}(2, 1), 5], ...
        [30 40; 0.5 * cp{1}(2, 1) + 0.5 * cp{2}(2, 1), 5], ...
        [50 60; cp{2}(2, 1), 5]});
end

function testHigherDimensionalGridStructuralOps(testCase)
    % Three-parameter grids should preserve nested LocalValues traversal.
    grid = {[0 1 2], [10 20], [100 200 300]};
    P = dpvar(2, grid, "full");
    cp = P.coeffs([2 1 2]);

    U = triu(P);
    R = reshape(P, 1, 4);
    S = P(1, :);

    testCase.verifyEqual(P.ncoeff(), 8);
    testCase.verifyEqual(numel(U.LocalValues{2}{1}{2}), 8);
    testCase.verifyEqual(size(R), [1 4]);
    testCase.verifyEqual(size(S), [1 2]);
    verifyCoeffExpr(testCase, U.coeffs([2 1 2]), cellfun(@triu, cp, UniformOutput=false));
    verifyCoeffExpr(testCase, R.coeffs([2 1 2]), ...
        cellfun(@(a) reshape(a, 1, 4), cp, UniformOutput=false));
    verifyCoeffExpr(testCase, S.coeffs([2 1 2]), ...
        cellfun(@(a) a(1, :), cp, UniformOutput=false));
end

function testStructuralOpsPreserveRateMetadata(testCase)
    % Structural transforms should keep RateBounds outside LocalValues.
    rb = [-1 1];
    P = dpvar(2, {[0 1]}, "full", RateBounds=rb);

    U = triu(P);
    S = P(:, 1);
    B = blkdiag(P, 1);

    testCase.verifyTrue(U.HasRateDependence);
    testCase.verifyTrue(S.HasRateDependence);
    testCase.verifyTrue(B.HasRateDependence);
    testCase.verifyEqual(U.RateBounds, rb);
    testCase.verifyEqual(S.RateBounds, rb);
    testCase.verifyEqual(B.RateBounds, rb);
end

function testRejectsInvalidConcatenation(testCase)
    % Unsupported dimensions, source modes, and nonlinear blocks should fail.
    P = dpvar(2, 1, {[0 1]}, "full");
    F = dpmat({[0 1]}, @(rho) [rho; rho]);
    x = sdpvar(1, 1);

    testCase.verifyError(@() cat(3, P, P), "dpvar:UnsupportedCatDimension");
    testCase.verifyError(@() [P, ones(3, 1)], "dpvar:InvalidConcatenation");
    testCase.verifyError(@() [P, F], "dpvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() [P, x * x], "dpvar:InvalidConcatenation");
end

function testIndexingAndAssignmentRejections(testCase)
    % Unsupported indexing and assignment forms should fail with stable IDs.
    P = dpvar(2, {[0 1]}, "full");
    R = dpvar(2, {[0 1]}, "full", RateBounds=[-1 1]);
    x = sdpvar(1, 1);

    testCase.verifyError(@() P(1), "dpvar:InvalidSubscript");
    testCase.verifyError(@() deleteAssign(P), "dpvar:UnsupportedAssignment");
    testCase.verifyError(@() growAssign(P), "dpvar:InvalidAssignment");
    testCase.verifyError(@() badSizeAssign(P), "dpvar:InvalidAssignment");
    testCase.verifyError(@() nonlinearAssign(P, x), "dpvar:InvalidAssignment");
    testCase.verifyError(@() rateAssign(P, R), "dpvar:InvalidAssignment");
end

function testStructuralRejections(testCase)
    % Structural methods should reject malformed dimensions and source modes.
    P = dpvar(2, {[0 1]}, "full");
    F = dpmat({[0 1]}, @(rho) rho * eye(2));

    testCase.verifyError(@() blkdiag(P, F), "dpvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() reshape(P, 3, 3), "dpvar:InvalidReshape");
    testCase.verifyError(@() diag(P, 3), "dpvar:InvalidDiag");
    testCase.verifyError(@() triu(P, 0.5), "dpvar:InvalidTriangularPart");
    testCase.verifyError(@() sum(P, "rows"), "dpvar:InvalidSum");
    testCase.verifyError(@() mean(P, [1 2]), "dpvar:InvalidMean");
    testCase.verifyError(@() cumsum(P, 0.5), "dpvar:InvalidCumsum");
    testCase.verifyError(@() rot90(P, 0.5), "dpvar:InvalidRot90");
    testCase.verifyError(@() repmat(P, [1 2 3]), "dpvar:InvalidRepmat");
end

function deleteAssign(P)
    % Exercise deletion-assignment rejection through a local function handle.
    P(1, :) = [];
end

function growAssign(P)
    % Exercise out-of-bounds growth rejection through a local function handle.
    P(3, :) = 1;
end

function badSizeAssign(P)
    % Exercise block-size mismatch rejection through a local function handle.
    P(1, :) = ones(2);
end

function nonlinearAssign(P, x)
    % Exercise nonlinear sdpvar assignment rejection through a local helper.
    P(1, 1) = x * x;
end

function rateAssign(P, R)
    % Exercise rate-dependent assignment rejection through a local helper.
    P(:, :) = R;
end

function verifyCoeffExpr(testCase, actual, expected)
    % Compare numeric or affine coefficient expressions without solving them.
    testCase.verifyEqual(numel(actual), numel(expected));
    for k = 1:numel(expected)
        diff = actual{k} - expected{k};
        if isa(diff, "sdpvar")
            base = full(getbase(diff));
            testCase.verifyEqual(base, zeros(size(base)), AbsTol=1e-10);
        else
            testCase.verifyEqual(diff, zeros(size(diff)), AbsTol=1e-10);
        end
    end
end
