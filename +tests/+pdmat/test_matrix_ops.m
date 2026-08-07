function tests = test_matrix_ops
    %TEST_MATRIX_OPS pdmat structural matrix operations and indexing.
    tests = functiontests(localfunctions);
end

function testTraAndCtr(testCase)
    % Transpose variants should transpose every local matrix coefficient.
    A = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);

    T = A.';
    H = A';

    testCase.verifyEqual(size(T), [2 2]);
    verifyCoeff(testCase, T, 1, {[1 3; 2 4], [5 7; 6 8]});
    verifyCoeff(testCase, H, 1, {[1 3; 2 4], [5 7; 6 8]});
end

function testInhOpeCleExaFun(testCase)
    % A coefficient operation must not retain the untransformed exact handle.
    A = pdmat([0 1], @(rho) [rho, 2 * rho], Degree=1);

    T = A.';

    testCase.verifyClass(T, "pdmat");
    testCase.verifyEqual(size(T), [2 1]);
    testCase.verifyEmpty(T.FunctionHandle);
    testCase.verifyEqual(T.SourceSummary, "coefficient-backed");
    testCase.verifyEqual(evaluate(T, 0.25), [0.25; 0.5], AbsTol=1e-12);
end

function testShaInsAndUnaPlu(testCase)
    % Matrix-like shape methods should report the pdmat payload dimensions.
    A = pdmat({[0 1]}, {zeros(2, 3), ones(2, 3)}, Degree=1);

    testCase.verifyEqual(+A, A);
    testCase.verifyEqual(length(A), 3);
    testCase.verifyEqual(height(A), 2);
    testCase.verifyEqual(width(A), 3);
    testCase.verifyEqual(numel(A), 6);
    testCase.verifyEqual(ndims(A), 2);
    testCase.verifyEqual(squeeze(A), A);
end

function testComStrMet(testCase)
    % Common MATLAB structural transforms should map every coefficient payload.
    A = pdmat({[0 1]}, {
        [1 2; 3 4], ...
        [10 20; 30 40]
        }, Degree=1);

    V = vec(A);
    D = diag(A);
    R = reshape(A, [1 4]);
    L = tril(A);
    U = triu(A, 1);
    T = trace(A);
    S1 = sum(A);
    S2 = sum(A, 2);
    Sa = sum(A, "all");
    M1 = mean(A);
    Ma = mean(A, "all");
    Cs = cumsum(A, 2);
    Sv = sum(A, [1 2 3]);
    Mv = mean(A, [2 3]);
    Cr = cumsum(A, 2, "reverse");
    Fu = flipud(A);
    Fl = fliplr(A);
    Fp = flip(A, 2);
    Q = rot90(A);
    Rp = repmat(A, 1, 2);

    testCase.verifyEqual(size(V), [4 1]);
    testCase.verifyEqual(size(D), [2 1]);
    testCase.verifyEqual(size(R), [1 4]);
    testCase.verifyEqual(size(T), [1 1]);
    testCase.verifyEqual(size(S1), [1 2]);
    testCase.verifyEqual(size(S2), [2 1]);
    testCase.verifyEqual(size(Sa), [1 1]);
    testCase.verifyEqual(size(M1), [1 2]);
    testCase.verifyEqual(size(Ma), [1 1]);
    testCase.verifyEqual(size(Rp), [2 4]);
    verifyCoeff(testCase, V, 1, {[1; 3; 2; 4], [10; 30; 20; 40]});
    verifyCoeff(testCase, D, 1, {[1; 4], [10; 40]});
    verifyCoeff(testCase, R, 1, {[1 3 2 4], [10 30 20 40]});
    verifyCoeff(testCase, L, 1, {[1 0; 3 4], [10 0; 30 40]});
    verifyCoeff(testCase, U, 1, {[0 2; 0 0], [0 20; 0 0]});
    verifyCoeff(testCase, T, 1, {5, 50});
    verifyCoeff(testCase, S1, 1, {[4 6], [40 60]});
    verifyCoeff(testCase, S2, 1, {[3; 7], [30; 70]});
    verifyCoeff(testCase, Sa, 1, {10, 100});
    verifyCoeff(testCase, M1, 1, {[2 3], [20 30]});
    verifyCoeff(testCase, Ma, 1, {2.5, 25});
    verifyCoeff(testCase, Cs, 1, {[1 3; 3 7], [10 30; 30 70]});
    verifyCoeff(testCase, Sv, 1, {10, 100});
    verifyCoeff(testCase, Mv, 1, {[1.5; 3.5], [15; 35]});
    verifyCoeff(testCase, Cr, 1, {[3 2; 7 4], [30 20; 70 40]});
    verifyCoeff(testCase, Fu, 1, {[3 4; 1 2], [30 40; 10 20]});
    verifyCoeff(testCase, Fl, 1, {[2 1; 4 3], [20 10; 40 30]});
    verifyCoeff(testCase, Fp, 1, {[2 1; 4 3], [20 10; 40 30]});
    verifyCoeff(testCase, Q, 1, {[2 4; 1 3], [20 40; 10 30]});
    verifyCoeff(testCase, Rp, 1, {
        [1 2 1 2; 3 4 3 4], ...
        [10 20 10 20; 30 40 30 40]
        });
    testCase.verifyTrue(isequal(A, A));
    testCase.verifyFalse(isequal(A, D));
end

function testIseComNorBerEvi(testCase)
    % Equality should compare coefficient evidence after grid/degree alignment.
    grid = [0 1];
    A = pdmat([0, 1], @(x) [-1, 0.5; -1, -2] + ...
        x * [-1.3, -20; 2, -10], Degree=1);
    A1 = pdmat(grid, {[-1, 0.5; -1, -2], ...
        [-1, 0.5; -1, -2] + [-1.3, -20; 2, -10]});
    B = pdmat({[0 0.5 1]}, {0, 0.5, 1}, Degree=1);
    C = pdmat({[0 1]}, {0, 0.5, 1}, Degree=2);
    D = pdmat({[0 1]}, {0, 1}, Degree=1);
    E = pdmat({[0 1]}, {0, 2}, Degree=1);
    F = pdmat({[0 2]}, {0, 2}, Degree=1);
    G = pdmat({[0 1]}, {zeros(2), ones(2)}, Degree=1);

    testCase.verifyTrue(isequal(A, A1));
    testCase.verifyTrue(isequal(B, C));
    testCase.verifyTrue(isequal(C, D));
    testCase.verifyFalse(isequal(D, E));
    testCase.verifyFalse(isequal(D, F));
    testCase.verifyFalse(isequal(D, G));

    testCase.verifyTrue(isequal(A));
    testCase.verifyFalse(isequal(1, A));
    fh = @(x) x;
    exactA = pdmat([0 1], fh);
    exactB = pdmat([0 1], fh);
    exactC = pdmat([0 1], @(x) x);
    testCase.verifyTrue(isequal(exactA, exactB));
    testCase.verifyFalse(isequal(exactA, exactC));
end

function testDiaConAndResInf(testCase)
    % Vector diag and one empty reshape dimension should follow MATLAB usage.
    A = pdmat({[0 1]}, {[1; 2; 3], [4; 5; 6]}, Degree=1);

    D = diag(A, 1);
    R = reshape(A, [], 1);

    testCase.verifyEqual(size(D), [4 4]);
    testCase.verifyEqual(size(R), [3 1]);
    verifyCoeff(testCase, D, 1, {
        [0 1 0 0; 0 0 2 0; 0 0 0 3; 0 0 0 0], ...
        [0 4 0 0; 0 0 5 0; 0 0 0 6; 0 0 0 0]
        });
    verifyCoeff(testCase, R, 1, {[1; 2; 3], [4; 5; 6]});
end

function testConcatenation(testCase)
    % Parent forwarding should dispatch for object-first and numeric-first forms.
    A = pdmat({[0 1]}, {[1; 2], [3; 4]}, Degree=1);
    B = pdmat({[0 1]}, {[10 20; 30 40], [50 60; 70 80]}, Degree=1);

    H = [A, B];
    V = [A; A];
    Nleft = [zeros(2, 1), A];
    Ntop = [0; A];
    scalar = pdmat({[0 1]}, {1, 2}, Degree=1);
    scalarRow = [scalar, 3, 4];
    scalarCol = [scalar; 3; 4];

    testCase.verifyEqual(size(H), [2 3]);
    testCase.verifyEqual(size(V), [4 1]);
    testCase.verifyEqual(size(Nleft), [2 2]);
    testCase.verifyEqual(size(Ntop), [3 1]);
    testCase.verifyEqual(size(scalarRow), [1 3]);
    testCase.verifyEqual(size(scalarCol), [3 1]);
    verifyCoeff(testCase, H, 1, {
        [1 10 20; 2 30 40], ...
        [3 50 60; 4 70 80]
        });
    verifyCoeff(testCase, V, 1, {
        [1; 2; 1; 2], ...
        [3; 4; 3; 4]
        });
    verifyCoeff(testCase, Nleft, 1, {
        [0 1; 0 2], ...
        [0 3; 0 4]
        });
    verifyCoeff(testCase, Ntop, 1, {
        [0; 1; 2], ...
        [0; 3; 4]
        });
end

function testCatDegEleAndDim(testCase)
    % cat should elevate degrees for dim 1/2 and reject unsupported dimensions.
    A = pdmat({[0 1]}, {[1; 3], [2; 4]}, Degree=1);
    B = pdmat({[0 1]}, {[10; 10], [20; 20], [30; 30]}, Degree=2);

    C = cat(2, A, B);

    testCase.verifyEqual(C.Degree, 2);
    verifyCoeff(testCase, C, 1, {
        [1 10; 3 10], ...
        [1.5 20; 3.5 20], ...
        [2 30; 4 30]
        });
    testCase.verifyError(@() cat(3, A, A), "pdmat:UnsupportedCatDimension");
end

function testBlkComGriAndNum(testCase)
    % blkdiag should align grids, elevate degree, and accept numeric blocks.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);
    B = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);

    C = blkdiag(A, 5, B);

    testCase.verifyEqual(size(C), [3 3]);
    testCase.verifyEqual(C.GridInfo.Vectors{1}, [0 0.5 1]);
    verifyCoeff(testCase, C, 1, {
        diag([1 5 10]), ...
        diag([1.5 5 20])
        });
    verifyCoeff(testCase, C, 2, {
        diag([1.5 5 20]), ...
        diag([2 5 30])
        });
end

function testMatSliAndDotAcc(testCase)
    % Matrix indexing should slice payloads while dot access stays available.
    A = pdmat({[0 1]}, {
        [1 2 3; 4 5 6], ...
        [10 20 30; 40 50 60]
        }, Degree=1);

    lastCol = A(:, end);
    topTail = A(1, 2:3);
    firstRow = A([true false], :);
    coeffs = A.coeffs(1);
    nestedDegree = A(:, 1).Degree;

    testCase.verifyEqual(size(lastCol), [2 1]);
    testCase.verifyEqual(size(topTail), [1 2]);
    testCase.verifyEqual(size(firstRow), [1 3]);
    testCase.verifyEqual(coeffs{1}, [1 2 3; 4 5 6]);
    testCase.verifyEqual(nestedDegree, 1);
    verifyCoeff(testCase, lastCol, 1, {[3; 6], [30; 60]});
    verifyCoeff(testCase, topTail, 1, {[2 3], [20 30]});
    verifyCoeff(testCase, firstRow, 1, {[1 2 3], [10 20 30]});
end

function testSubNumAndPdmBlo(testCase)
    % Subscript assignment should accept numeric constants and pdmat blocks.
    A = pdmat({[0 1]}, {zeros(2), 2 * ones(2)}, Degree=1);
    A(:, 2) = 5;

    verifyCoeff(testCase, A, 1, {
        [0 5; 0 5], ...
        [2 5; 2 5]
        });

    B = pdmat({[0 1]}, {[10 20], [30 40], [50 60]}, Degree=2);
    A(1, :) = B;

    testCase.verifyEqual(A.Degree, 2);
    verifyCoeff(testCase, A, 1, {
        [10 20; 0 5], ...
        [30 40; 1 5], ...
        [50 60; 2 5]
        });
end

function testAniCatBlkAssAnd(testCase)
    % Structural composition aligns each degree axis on a common refinement.
    gridA = {[0 1], [10 20]};
    gridB = {[0 0.5 1], [10 20]};
    A = pdmat(gridA, repmat({[1; 2]}, 2, 4), Degree=[1 3]);
    B = pdmat(gridB, repmat({[3; 4]}, 5, 2), Degree=[2 1]);

    horizontal = [A, B];
    diagonal = blkdiag(A, B);
    assigned = A;
    assigned(:, 1) = B;

    testCase.verifyEqual(horizontal.Degree, [2 3]);
    testCase.verifyEqual(diagonal.Degree, [2 3]);
    testCase.verifyEqual(assigned.Degree, [2 3]);
    testCase.verifyEqual(horizontal.GridInfo.Vectors, gridB);
    testCase.verifyEqual(diagonal.GridInfo.Vectors, gridB);
    testCase.verifyEqual(assigned.GridInfo.Vectors, gridB);
    verifyCoeff(testCase, horizontal, [1 1], ...
        repmat({[1 3; 2 4]}, 1, 12));
    verifyCoeff(testCase, diagonal, [1 1], ...
        repmat({blkdiag([1; 2], [3; 4])}, 1, 12));
    verifyCoeff(testCase, assigned, [1 1], ...
        repmat({[3; 4]}, 1, 12));
end

function testIndAndAssRej(testCase)
    % Unsupported indexing and assignment forms should fail with stable IDs.
    A = pdmat({[0 1]}, {zeros(2), ones(2)}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho * eye(2));

    testCase.verifyError(@() A(1), "pdmat:InvalidSubscript");
    testCase.verifyError(@() F(:, 1), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() deleteAssign(A), "pdmat:UnsupportedAssignment");
    testCase.verifyError(@() growAssign(A), "pdmat:InvalidAssignment");
    testCase.verifyError(@() badSizeAssign(A), "pdmat:InvalidAssignment");
    testCase.verifyError(@() nestedAssign(A), "pdmat:UnsupportedAssignment");
    testCase.verifyError(@() assignFunction(F), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() setSummary(A), "MATLAB:class:SetProhibited");
end

function testCatInvDimAndBloSha(testCase)
    % Concatenation validates its dimension and non-scalar block extents.
    A = pdmat({[0 1]}, {zeros(2, 1), ones(2, 1)}, Degree=1);
    B = pdmat({[0 1]}, {zeros(3, 1), ones(3, 1)}, Degree=1);
    C = pdmat({[0 1]}, {zeros(1, 2), ones(1, 2)}, Degree=1);
    D = pdmat({[0 1]}, {zeros(1, 3), ones(1, 3)}, Degree=1);

    testCase.verifyError(@() cat("bad", A, A), ...
        "pdmat:InvalidConcatenation");
    testCase.verifyError(@() [A, B], "pdmat:InvalidConcatenation");
    testCase.verifyError(@() [C; D], "pdmat:InvalidConcatenation");
end

function testStrRej(testCase)
    % Coefficient-structural methods should reject unsupported source shapes.
    A = pdmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho * eye(2));

    testCase.verifyError(@() vec(F), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() tril(F), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() trace(F), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() sum(F), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() blkdiag(A, F), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() reshape(A, 3, 3), "pdmat:InvalidReshape");
    testCase.verifyError(@() diag(A, 3), "pdmat:InvalidDiag");
    testCase.verifyError(@() triu(A, 0.5), "pdmat:InvalidTriangularPart");
    testCase.verifyError(@() sum(A, "rows"), "pdmat:InvalidSum");
    testCase.verifyError(@() mean(A, [1 1]), "pdmat:InvalidMean");
    testCase.verifyError(@() cumsum(A, 0.5), "pdmat:InvalidCumsum");
    testCase.verifyError(@() cumsum(A, 1, "backward"), ...
        "pdmat:InvalidCumsum");
    testCase.verifyError(@() rot90(A, 0.5), "pdmat:InvalidRot90");
    testCase.verifyError(@() repmat(A, [1 2 3]), "pdmat:InvalidRepmat");
end

function deleteAssign(A)
    % Exercise deletion-assignment rejection through a local function handle.
    A(1, :) = [];
end

function growAssign(A)
    % Exercise out-of-bounds growth rejection through a local function handle.
    A(3, :) = 1;
end

function badSizeAssign(A)
    % Exercise block-size mismatch rejection through a local function handle.
    A(1, :) = ones(2);
end

function nestedAssign(A)
    % Nested assignment is outside the coefficient-block contract.
    S = substruct("()", {1, 1}, ".", "field");
    subsasgn(A, S, 1);
end

function assignFunction(F)
    % Function-only data cannot acquire coefficient blocks by assignment.
    F(1, 1) = 0;
end

function setSummary(A)
    % Dot assignment reaches MATLAB's private-set property guard.
    A.SourceSummary = "changed";
end

function verifyCoeff(testCase, obj, cellSubs, expected)
    % Compare one physical cell's coefficients against numeric expectations.
    coeffs = obj.coeffs(cellSubs);
    testCase.verifyEqual(numel(coeffs), numel(expected));
    for k = 1:numel(expected)
        testCase.verifyEqual(coeffs{k}, expected{k}, AbsTol=1e-10);
    end
end
