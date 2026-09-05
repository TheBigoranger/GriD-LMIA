function tests = test_matrix_ops_integration
    % Behavioral regressions for pdmat.matrix_ops_integration.
    tests = functiontests(localfunctions);
end
function test_tensor_block_composition_then_indexing_matches_numeric_matrix(testCase)
    % Block layout must survive a subsequent rectangular reshape and selection.
    f = @(x,y) [x^2+y; x*y];
    g = @(x,y) [1+y^2, x-y];
    A = pdmat({[0 .5 2], [-1 3]}, f, Degree=[2 1]);
    B = pdmat({[0 2], [-1 0 3]}, g, Degree=[1 2]);
    C = blkdiag(A,B);
    C = reshape(C,1,9);
    C = C(1,[9 1 5 9]);
    for x = [0 .25 .5 1.25 2]
        for y = [-1 -.5 0 1.5 3]
            block = reshape(blkdiag(f(x,y),g(x,y)),1,9);
            testCase.verifyEqual(C.evaluate([x y]), block([9 1 5 9]), AbsTol=1e-10);
        end
    end
end

function test_transpose_variants_transpose_local_matrix(testCase)
    % Transpose variants should transpose every local matrix coefficient.
    A = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);

    T = A.';
    H = A';

    testCase.verifyEqual(size(T), [2 2]);
    tests.infrastructure.verify_coeff(testCase, T, 1, {[1 3; 2 4], [5 7; 6 8]});
    tests.infrastructure.verify_coeff(testCase, H, 1, {[1 3; 2 4], [5 7; 6 8]});
end

function test_coefficient_operation_untransformed_exact_handle(testCase)
    % A coefficient operation must not retain the untransformed exact handle.
    A = pdmat([0 1], @(rho) [rho, 2 * rho], Degree=1);

    T = A.';

    testCase.verifyClass(T, "pdmat");
    testCase.verifyEqual(size(T), [2 1]);
    testCase.verifyEmpty(T.FunctionHandle);
    testCase.verifyEqual(T.SourceSummary, "coefficient-backed");
    testCase.verifyEqual(evaluate(T, 0.25), [0.25; 0.5], AbsTol=1e-12);
end

function test_matrix_like_shape_methods_report_pdmat(testCase)
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

function test_common_matlab_structural_transforms_map_coefficient(testCase)
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
    tests.infrastructure.verify_coeff(testCase, V, 1, {[1; 3; 2; 4], [10; 30; 20; 40]});
    tests.infrastructure.verify_coeff(testCase, D, 1, {[1; 4], [10; 40]});
    tests.infrastructure.verify_coeff(testCase, R, 1, {[1 3 2 4], [10 30 20 40]});
    tests.infrastructure.verify_coeff(testCase, L, 1, {[1 0; 3 4], [10 0; 30 40]});
    tests.infrastructure.verify_coeff(testCase, U, 1, {[0 2; 0 0], [0 20; 0 0]});
    tests.infrastructure.verify_coeff(testCase, T, 1, {5, 50});
    tests.infrastructure.verify_coeff(testCase, S1, 1, {[4 6], [40 60]});
    tests.infrastructure.verify_coeff(testCase, S2, 1, {[3; 7], [30; 70]});
    tests.infrastructure.verify_coeff(testCase, Sa, 1, {10, 100});
    tests.infrastructure.verify_coeff(testCase, M1, 1, {[2 3], [20 30]});
    tests.infrastructure.verify_coeff(testCase, Ma, 1, {2.5, 25});
    tests.infrastructure.verify_coeff(testCase, Cs, 1, {[1 3; 3 7], [10 30; 30 70]});
    tests.infrastructure.verify_coeff(testCase, Sv, 1, {10, 100});
    tests.infrastructure.verify_coeff(testCase, Mv, 1, {[1.5; 3.5], [15; 35]});
    tests.infrastructure.verify_coeff(testCase, Cr, 1, {[3 2; 7 4], [30 20; 70 40]});
    tests.infrastructure.verify_coeff(testCase, Fu, 1, {[3 4; 1 2], [30 40; 10 20]});
    tests.infrastructure.verify_coeff(testCase, Fl, 1, {[2 1; 4 3], [20 10; 40 30]});
    tests.infrastructure.verify_coeff(testCase, Fp, 1, {[2 1; 4 3], [20 10; 40 30]});
    tests.infrastructure.verify_coeff(testCase, Q, 1, {[2 4; 1 3], [20 40; 10 30]});
    tests.infrastructure.verify_coeff(testCase, Rp, 1, {
        [1 2 1 2; 3 4 3 4], ...
        [10 20 10 20; 30 40 30 40]
        });
    testCase.verifyTrue(isequal(A, A));
    testCase.verifyFalse(isequal(A, D));
end

function test_vector_diag_empty_reshape_dimension_follow(testCase)
    % Vector diag and one empty reshape dimension should follow MATLAB usage.
    A = pdmat({[0 1]}, {[1; 2; 3], [4; 5; 6]}, Degree=1);

    D = diag(A, 1);
    R = reshape(A, [], 1);

    testCase.verifyEqual(size(D), [4 4]);
    testCase.verifyEqual(size(R), [3 1]);
    tests.infrastructure.verify_coeff(testCase, D, 1, {
        [0 1 0 0; 0 0 2 0; 0 0 0 3; 0 0 0 0], ...
        [0 4 0 0; 0 0 5 0; 0 0 0 6; 0 0 0 0]
        });
    tests.infrastructure.verify_coeff(testCase, R, 1, {[1; 2; 3], [4; 5; 6]});
end

function test_structural_composition_aligns_each_degree_axis(testCase)
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
    tests.infrastructure.verify_coeff(testCase, horizontal, [1 1], ...
        repmat({[1 3; 2 4]}, 1, 12));
    tests.infrastructure.verify_coeff(testCase, diagonal, [1 1], ...
        repmat({blkdiag([1; 2], [3; 4])}, 1, 12));
    tests.infrastructure.verify_coeff(testCase, assigned, [1 1], ...
        repmat({[3; 4]}, 1, 12));
end

function test_coefficient_structural_methods_reject_unsupported(testCase)
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
