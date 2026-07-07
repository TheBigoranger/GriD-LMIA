function tests = test_matrix_ops
    %TEST_MATRIX_OPS dpmat structural matrix operations and indexing.
    tests = functiontests(localfunctions);
end

function testTransposeAndCtranspose(testCase)
    % Transpose variants should transpose every local matrix coefficient.
    A = dpmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);

    T = A.';
    H = A';

    testCase.verifyEqual(size(T), [2 2]);
    verifyCoeff(testCase, T, 1, {[1 3; 2 4], [5 7; 6 8]});
    verifyCoeff(testCase, H, 1, {[1 3; 2 4], [5 7; 6 8]});
end

function testShapeInspectionAndUnaryPlus(testCase)
    % Matrix-like shape methods should report the dpmat payload dimensions.
    A = dpmat({[0 1]}, {zeros(2, 3), ones(2, 3)}, Degree=1);

    testCase.verifyEqual(+A, A);
    testCase.verifyEqual(length(A), 3);
    testCase.verifyEqual(height(A), 2);
    testCase.verifyEqual(width(A), 3);
    testCase.verifyEqual(numel(A), 6);
    testCase.verifyEqual(ndims(A), 2);
    testCase.verifyEqual(squeeze(A), A);
end

function testCommonStructuralMethods(testCase)
    % Common MATLAB structural transforms should map every coefficient payload.
    A = dpmat({[0 1]}, {
        [1 2; 3 4], ...
        [10 20; 30 40]
        }, Degree=1);

    V = vec(A);
    D = diag(A);
    R = reshape(A, [1 4]);
    L = tril(A);
    U = triu(A, 1);

    testCase.verifyEqual(size(V), [4 1]);
    testCase.verifyEqual(size(D), [2 1]);
    testCase.verifyEqual(size(R), [1 4]);
    verifyCoeff(testCase, V, 1, {[1; 3; 2; 4], [10; 30; 20; 40]});
    verifyCoeff(testCase, D, 1, {[1; 4], [10; 40]});
    verifyCoeff(testCase, R, 1, {[1 3 2 4], [10 30 20 40]});
    verifyCoeff(testCase, L, 1, {[1 0; 3 4], [10 0; 30 40]});
    verifyCoeff(testCase, U, 1, {[0 2; 0 0], [0 20; 0 0]});
    testCase.verifyTrue(isequal(A, A));
    testCase.verifyFalse(isequal(A, D));
end

function testDiagConstructionAndReshapeInference(testCase)
    % Vector diag and one empty reshape dimension should follow MATLAB usage.
    A = dpmat({[0 1]}, {[1; 2; 3], [4; 5; 6]}, Degree=1);

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
    % Horizontal and vertical concatenation should combine coefficient blocks.
    A = dpmat({[0 1]}, {[1; 2], [3; 4]}, Degree=1);
    B = dpmat({[0 1]}, {[10 20; 30 40], [50 60; 70 80]}, Degree=1);

    H = [A, B];
    V = [A; A];

    testCase.verifyEqual(size(H), [2 3]);
    testCase.verifyEqual(size(V), [4 1]);
    verifyCoeff(testCase, H, 1, {
        [1 10 20; 2 30 40], ...
        [3 50 60; 4 70 80]
        });
    verifyCoeff(testCase, V, 1, {
        [1; 2; 1; 2], ...
        [3; 4; 3; 4]
        });
end

function testCatDegreeElevationAndDimRejection(testCase)
    % cat should elevate degrees for dim 1/2 and reject unsupported dimensions.
    A = dpmat({[0 1]}, {[1; 3], [2; 4]}, Degree=1);
    B = dpmat({[0 1]}, {[10; 10], [20; 20], [30; 30]}, Degree=2);

    C = cat(2, A, B);

    testCase.verifyEqual(C.Degree, 2);
    verifyCoeff(testCase, C, 1, {
        [1 10; 3 10], ...
        [1.5 20; 3.5 20], ...
        [2 30; 4 30]
        });
    testCase.verifyError(@() cat(3, A, A), "dpmat:UnsupportedCatDimension");
end

function testBlkdiagCommonGridAndNumeric(testCase)
    % blkdiag should align grids, elevate degree, and accept numeric blocks.
    A = dpmat({[0 1]}, {1, 2}, Degree=1);
    B = dpmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);

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

function testMatrixSlicingAndDotAccess(testCase)
    % Matrix indexing should slice payloads while dot access stays available.
    A = dpmat({[0 1]}, {
        [1 2 3; 4 5 6], ...
        [10 20 30; 40 50 60]
        }, Degree=1);

    lastCol = A(:, end);
    topTail = A(1, 2:3);
    firstRow = A([true false], :);
    coeffs = A.coeffs(1);

    testCase.verifyEqual(size(lastCol), [2 1]);
    testCase.verifyEqual(size(topTail), [1 2]);
    testCase.verifyEqual(size(firstRow), [1 3]);
    testCase.verifyEqual(coeffs{1}, [1 2 3; 4 5 6]);
    verifyCoeff(testCase, lastCol, 1, {[3; 6], [30; 60]});
    verifyCoeff(testCase, topTail, 1, {[2 3], [20 30]});
    verifyCoeff(testCase, firstRow, 1, {[1 2 3], [10 20 30]});
end

function testSubsasgnNumericAndDpmatBlocks(testCase)
    % Subscript assignment should accept numeric constants and dpmat blocks.
    A = dpmat({[0 1]}, {zeros(2), 2 * ones(2)}, Degree=1);
    A(:, 2) = 5;

    verifyCoeff(testCase, A, 1, {
        [0 5; 0 5], ...
        [2 5; 2 5]
        });

    B = dpmat({[0 1]}, {[10 20], [30 40], [50 60]}, Degree=2);
    A(1, :) = B;

    testCase.verifyEqual(A.Degree, 2);
    verifyCoeff(testCase, A, 1, {
        [10 20; 0 5], ...
        [30 40; 1 5], ...
        [50 60; 2 5]
        });
end

function testIndexingAndAssignmentRejections(testCase)
    % Unsupported indexing and assignment forms should fail with stable IDs.
    A = dpmat({[0 1]}, {zeros(2), ones(2)}, Degree=1);
    F = dpmat({[0 1]}, @(rho) rho * eye(2));

    testCase.verifyError(@() A(1), "dpmat:InvalidSubscript");
    testCase.verifyError(@() F(:, 1), "dpmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() deleteAssign(A), "dpmat:UnsupportedAssignment");
    testCase.verifyError(@() growAssign(A), "dpmat:InvalidAssignment");
    testCase.verifyError(@() badSizeAssign(A), "dpmat:InvalidAssignment");
end

function testStructuralRejections(testCase)
    % Coefficient-structural methods should reject unsupported source shapes.
    A = dpmat({[0 1]}, {eye(2), 2 * eye(2)}, Degree=1);
    F = dpmat({[0 1]}, @(rho) rho * eye(2));

    testCase.verifyError(@() vec(F), "dpmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() tril(F), "dpmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() blkdiag(A, F), "dpmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() reshape(A, 3, 3), "dpmat:InvalidReshape");
    testCase.verifyError(@() diag(A, 3), "dpmat:InvalidDiag");
    testCase.verifyError(@() triu(A, 0.5), "dpmat:InvalidTriangularPart");
end

function deleteAssign(A)
    A(1, :) = [];
end

function growAssign(A)
    A(3, :) = 1;
end

function badSizeAssign(A)
    A(1, :) = ones(2);
end

function verifyCoeff(testCase, obj, cellSubs, expected)
    coeffs = obj.coeffs(cellSubs);
    testCase.verifyEqual(numel(coeffs), numel(expected));
    for k = 1:numel(expected)
        testCase.verifyEqual(coeffs{k}, expected{k}, AbsTol=1e-10);
    end
end
