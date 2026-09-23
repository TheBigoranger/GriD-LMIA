function tests = test_matrix_ops_integration
    % Behavioral regressions for pdvar.matrix_ops_integration.
    tests = functiontests(localfunctions);
end

function test_tensor_rate_transpose_reshape_reduction_chain(testCase)
    % A composed column-major map must retain the last rate row and matrix entry.
    tests.infrastructure.verify_tensor_transform(testCase,"pdvar", ...
        @(x) cumsum(reshape(transpose(x),2,3),2,"reverse"),"mixed", ...
        @(x) reshape(transpose(x),2,3)*[1 0 0;1 1 0;1 1 1]);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function test_matrix_like_shape_methods_report_pdvar(testCase)
    % Matrix-like shape methods should report the pdvar payload dimensions.
    P = pdvar(2, 3, {[0 1]}, "full");

    testCase.verifyTrue(isequal(+P, P));
    testCase.verifyTrue(isequal(P));
    testCase.verifyFalse(isequal(1, P));
    testCase.verifyEqual(length(P), 3);
    testCase.verifyEqual(height(P), 2);
    testCase.verifyEqual(width(P), 3);
    testCase.verifyEqual(numel(P), 6);
    testCase.verifyEqual(ndims(P), 2);
    testCase.verifyTrue(isequal(squeeze(P), P));
end

function test_size_changing_unary_operations_map_coefficient(testCase)
    % Size-changing unary operations should map every coefficient payload.
    P = pdvar(2, 3, {[0 1]}, "full");
    Q = pdvar(2, {[0 1]}, "full");
    cp = P.coeffs(1);
    cq = Q.coeffs(1);

    T = P.';
    H = P';
    Tr = trace(Q);

    testCase.verifyEqual(size(T), [3 2]);
    testCase.verifyEqual(size(H), [3 2]);
    testCase.verifyEqual(size(Tr), [1 1]);
    tests.infrastructure.verify_expr(testCase, T.coeffs(1), {cp{1}.', cp{2}.'});
    tests.infrastructure.verify_expr(testCase, H.coeffs(1), {cp{1}', cp{2}'});
    tests.infrastructure.verify_expr(testCase, Tr.coeffs(1), {trace(cq{1}), trace(cq{2})});
end

function test_common_matlab_structural_transforms_map_coefficient(testCase)
    % Common MATLAB structural transforms should map every coefficient payload.
    P = pdvar(2, {[0 1]}, "full");
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
    tests.infrastructure.verify_expr(testCase, V.coeffs(1), {cp{1}(:), cp{2}(:)});
    tests.infrastructure.verify_expr(testCase, D.coeffs(1), {diag(cp{1}), diag(cp{2})});
    tests.infrastructure.verify_expr(testCase, R.coeffs(1), {reshape(cp{1}, [1 4]), reshape(cp{2}, [1 4])});
    tests.infrastructure.verify_expr(testCase, L.coeffs(1), {tril(cp{1}), tril(cp{2})});
    tests.infrastructure.verify_expr(testCase, U.coeffs(1), {triu(cp{1}, 1), triu(cp{2}, 1)});
    tests.infrastructure.verify_expr(testCase, S1.coeffs(1), {sum(cp{1}), sum(cp{2})});
    tests.infrastructure.verify_expr(testCase, S2.coeffs(1), {sum(cp{1}, 2), sum(cp{2}, 2)});
    tests.infrastructure.verify_expr(testCase, Sa.coeffs(1), {sum(cp{1}, "all"), sum(cp{2}, "all")});
    tests.infrastructure.verify_expr(testCase, M1.coeffs(1), {mean(cp{1}), mean(cp{2})});
    tests.infrastructure.verify_expr(testCase, Ma.coeffs(1), {mean(cp{1}, "all"), mean(cp{2}, "all")});
    tests.infrastructure.verify_expr(testCase, Cs.coeffs(1), {cumsum(cp{1}, 2), cumsum(cp{2}, 2)});
    tests.infrastructure.verify_expr(testCase, Fu.coeffs(1), {flipud(cp{1}), flipud(cp{2})});
    tests.infrastructure.verify_expr(testCase, Fl.coeffs(1), {fliplr(cp{1}), fliplr(cp{2})});
    tests.infrastructure.verify_expr(testCase, Fp.coeffs(1), {flip(cp{1}, 2), flip(cp{2}, 2)});
    tests.infrastructure.verify_expr(testCase, Q.coeffs(1), {rot90(cp{1}), rot90(cp{2})});
    tests.infrastructure.verify_expr(testCase, Rp.coeffs(1), {repmat(cp{1}, 1, 2), repmat(cp{2}, 1, 2)});
    testCase.verifyFalse(isequal(P, D));
end

function test_structural_methods_map_constructor_created_high(testCase)
    % Structural methods map every constructor-created high-degree payload.
    P = pdvar(2, 3, {[0 1]}, "full", Degree=3);
    cp = P.coeffs(1);

    T = P.';
    V = vec(P);

    testCase.verifyEqual(T.Degree, 3);
    testCase.verifyEqual(V.Degree, 3);
    testCase.verifyEqual(size(T), [3 2]);
    testCase.verifyEqual(size(V), [6 1]);
    tests.infrastructure.verify_expr(testCase, T.coeffs(1), ...
        cellfun(@transpose, cp, UniformOutput=false));
    tests.infrastructure.verify_expr(testCase, V.coeffs(1), ...
        cellfun(@(x) x(:), cp, UniformOutput=false));
end

function test_unary_structural_transforms_derivative_row_tables(testCase)
    % Unary structural transforms should keep derivative row tables intact.
    P = pdvar(2, {[0 1]}, "full");
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);

    T = D.';
    H = D';
    Tr = trace(D);
    V = vec(D);
    G = diag(D);
    R = reshape(D, [1 4]);
    L = tril(D);
    U = triu(D, 1);
    S1 = sum(D);
    S2 = sum(D, 2);
    Sa = sum(D, "all");
    M1 = mean(D);
    Ma = mean(D, "all");
    Cs = cumsum(D, 2);
    Fu = flipud(D);
    Fl = fliplr(D);
    Fp = flip(D, 2);
    Q = rot90(D);
    Rp = repmat(D, 1, 2);

    outs = {T, H, Tr, V, G, R, L, U, S1, S2, Sa, M1, Ma, Cs, Fu, Fl, Fp, Q, Rp};
    exp = {
        {cd{1, 1}.'; cd{2, 1}.'}, ...
        {cd{1, 1}'; cd{2, 1}'}, ...
        {trace(cd{1, 1}); trace(cd{2, 1})}, ...
        {cd{1, 1}(:); cd{2, 1}(:)}, ...
        {diag(cd{1, 1}); diag(cd{2, 1})}, ...
        {reshape(cd{1, 1}, [1 4]); reshape(cd{2, 1}, [1 4])}, ...
        {tril(cd{1, 1}); tril(cd{2, 1})}, ...
        {triu(cd{1, 1}, 1); triu(cd{2, 1}, 1)}, ...
        {sum(cd{1, 1}); sum(cd{2, 1})}, ...
        {sum(cd{1, 1}, 2); sum(cd{2, 1}, 2)}, ...
        {sum(cd{1, 1}, "all"); sum(cd{2, 1}, "all")}, ...
        {mean(cd{1, 1}); mean(cd{2, 1})}, ...
        {mean(cd{1, 1}, "all"); mean(cd{2, 1}, "all")}, ...
        {cumsum(cd{1, 1}, 2); cumsum(cd{2, 1}, 2)}, ...
        {flipud(cd{1, 1}); flipud(cd{2, 1})}, ...
        {fliplr(cd{1, 1}); fliplr(cd{2, 1})}, ...
        {flip(cd{1, 1}, 2); flip(cd{2, 1}, 2)}, ...
        {rot90(cd{1, 1}); rot90(cd{2, 1})}, ...
        {repmat(cd{1, 1}, 1, 2); repmat(cd{2, 1}, 1, 2)}
    };

    testCase.verifyEqual(size(V), [4 1]);
    testCase.verifyEqual(size(R), [1 4]);
    testCase.verifyEqual(size(Rp), [2 4]);
    for k = 1:numel(outs)
        testCase.verifyEqual(outs{k}.RateBounds, [-1 2]);
        testCase.verifyEqual(size(outs{k}.coeffs(1)), [2 1]);
        tests.infrastructure.verify_expr(testCase, outs{k}.coeffs(1), exp{k});
    end
end

function test_degree_two_derivatives_rate_row_both(testCase)
    % Degree-two derivatives keep every rate row and both coefficient columns.
    P = pdvar(2, {[0 1]}, "full", Degree=2);
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);

    N = -D;
    S = sum(D, [1 2 3]);
    M = mean(D, [1 3]);
    C = cumsum(D, 2, "reverse");

    testCase.verifyEqual(size(cd), [2 2]);
    testCase.verifyEqual(size(N.coeffs(1)), [2 2]);
    testCase.verifyEqual(size(S.coeffs(1)), [2 2]);
    testCase.verifyEqual(size(M.coeffs(1)), [2 2]);
    testCase.verifyEqual(size(C.coeffs(1)), [2 2]);
    testCase.verifyEqual(size(N), [2 2]);
    testCase.verifyEqual(size(S), [1 1]);
    testCase.verifyEqual(size(M), [1 2]);
    testCase.verifyEqual(size(C), [2 2]);

    tests.infrastructure.verify_expr(testCase, N.coeffs(1), ...
        cellfun(@uminus, cd, UniformOutput=false));
    tests.infrastructure.verify_expr(testCase, S.coeffs(1), ...
        cellfun(@(x) sum(x, "all"), cd, UniformOutput=false));
    tests.infrastructure.verify_expr(testCase, M.coeffs(1), ...
        cellfun(@(x) mean(x, 1), cd, UniformOutput=false));
    tests.infrastructure.verify_expr(testCase, C.coeffs(1), ...
        cellfun(@(x) flip(cumsum(flip(x, 2), 2), 2), cd, ...
        UniformOutput=false));

    for out = {N, S, M, C}
        testCase.verifyEqual(out{1}.RateBounds, [-1 2]);
        testCase.verifyEqual(out{1}.Degree, 1);
        testCase.verifyEqual(out{1}.Continuity, Inf);
        testCase.verifyTrue(out{1}.IsContinuous);
    end
end

function test_vector_diag_empty_reshape_dimension_follow(testCase)
    % Vector diag and one empty reshape dimension should follow MATLAB usage.
    P = pdvar(3, 1, {[0 1]}, "full");
    cp = P.coeffs(1);

    D = diag(P, 1);
    R = reshape(P, [], 1);

    testCase.verifyEqual(size(D), [4 4]);
    testCase.verifyEqual(size(R), [3 1]);
    tests.infrastructure.verify_expr(testCase, D.coeffs(1), {diag(cp{1}, 1), diag(cp{2}, 1)});
    tests.infrastructure.verify_expr(testCase, R.coeffs(1), {cp{1}, cp{2}});
end

function test_cat_horzcat_vertcat_combine_compatible_coefficient(testCase)
    % cat/horzcat/vertcat should combine compatible coefficient blocks.
    P = pdvar(2, 1, {[0 1]}, "full");
    A = pdmat({[0 1]}, {[10; 20], [30; 40]}, Degree=1);
    cp = P.coeffs(1);

    H = [P, A];
    Hr = [A, P];
    V = [P; P];
    Vr = [P; A];
    N = cat(2, P, 5);
    Nl = [zeros(2, 1), P];
    Nt = [0; P];
    scalar = pdvar(1, {[0 1]});
    scalarRow = [scalar, 3, 4];
    scalarCol = [scalar; 3; 4];

    testCase.verifyEqual(size(H), [2 2]);
    testCase.verifyEqual(size(Hr), [2 2]);
    testCase.verifyEqual(size(V), [4 1]);
    testCase.verifyEqual(size(Vr), [4 1]);
    testCase.verifyEqual(size(N), [2 2]);
    testCase.verifyEqual(size(Nl), [2 2]);
    testCase.verifyEqual(size(Nt), [3 1]);
    testCase.verifyEqual(size(scalarRow), [1 3]);
    testCase.verifyEqual(size(scalarCol), [3 1]);
    tests.infrastructure.verify_expr(testCase, H.coeffs(1), {[cp{1}, [10; 20]], [cp{2}, [30; 40]]});
    tests.infrastructure.verify_expr(testCase, Hr.coeffs(1), {[[10; 20], cp{1}], [[30; 40], cp{2}]});
    tests.infrastructure.verify_expr(testCase, V.coeffs(1), {[cp{1}; cp{1}], [cp{2}; cp{2}]});
    tests.infrastructure.verify_expr(testCase, Vr.coeffs(1), {[cp{1}; 10; 20], [cp{2}; 30; 40]});
    tests.infrastructure.verify_expr(testCase, N.coeffs(1), {[cp{1}, 5 * ones(2, 1)], [cp{2}, 5 * ones(2, 1)]});
    tests.infrastructure.verify_expr(testCase, Nl.coeffs(1), {[zeros(2, 1), cp{1}], [zeros(2, 1), cp{2}]});
    tests.infrastructure.verify_expr(testCase, Nt.coeffs(1), {[0; cp{1}], [0; cp{2}]});
end

function test_composition_assignment_componentwise_maximum_degree(testCase)
    % Composition and assignment use componentwise maximum degree.
    grid = {[0 1], [10 20]};
    P = pdvar(2, 1, grid, "full", Degree=[1 3]);
    B = pdmat(grid, repmat({[10; 20]}, 3, 2), Degree=[2 1]);
    S = pdmat(grid, repmat({30}, 3, 2), Degree=[2 1]);
    elevated = P.elevate([1 0]);
    ep = elevated.coeffs([1 1]);

    horizontal = [P, B];
    diagonal = blkdiag(P, B);
    assigned = P;
    assigned(1, 1) = S;

    testCase.verifyEqual(horizontal.Degree, [2 3]);
    testCase.verifyEqual(diagonal.Degree, [2 3]);
    testCase.verifyEqual(assigned.Degree, [2 3]);
    testCase.verifyEqual(horizontal.ncoeff(), 12);
    testCase.verifyEqual(diagonal.ncoeff(), 12);
    testCase.verifyEqual(assigned.ncoeff(), 12);
    tests.infrastructure.verify_expr(testCase, horizontal.coeffs([1 1]), ...
        cellfun(@(x) [x, [10; 20]], ep, UniformOutput=false));
    tests.infrastructure.verify_expr(testCase, diagonal.coeffs([1 1]), ...
        cellfun(@(x) blkdiag(x, [10; 20]), ep, UniformOutput=false));
    tests.infrastructure.verify_expr(testCase, assigned.coeffs([1 1]), ...
        cellfun(@(x) [30; x(2, 1)], ep, UniformOutput=false));
end

function test_three_parameter_grids_preserve_nested_localvalues(testCase)
    % Three-parameter grids should preserve nested LocalValues traversal.
    grid = {[0 1 2], [10 20], [100 200 300]};
    P = pdvar(2, grid, "full");
    cp = P.coeffs([2 1 2]);

    U = triu(P);
    R = reshape(P, 1, 4);
    S = P(1, :);

    testCase.verifyEqual(P.ncoeff(), 8);
    testCase.verifyEqual(numel(U.LocalValues{2}{1}{2}), 8);
    testCase.verifyEqual(size(R), [1 4]);
    testCase.verifyEqual(size(S), [1 2]);
    tests.infrastructure.verify_expr(testCase, U.coeffs([2 1 2]), cellfun(@triu, cp, UniformOutput=false));
    tests.infrastructure.verify_expr(testCase, R.coeffs([2 1 2]), ...
        cellfun(@(a) reshape(a, 1, 4), cp, UniformOutput=false));
    tests.infrastructure.verify_expr(testCase, S.coeffs([2 1 2]), ...
        cellfun(@(a) a(1, :), cp, UniformOutput=false));
end

function test_structural_transforms_ratebounds_outside_localvalues(testCase)
    % Structural transforms should keep RateBounds outside LocalValues.
    rb = [-1 1];
    P = pdvar(2, {[0 1]}, "full", RateBounds=rb);
    Q = pdvar(2, {[0 1]}, "full");
    R = pdvar(2, {[0 1]}, "full", RateBounds=rb);
    Bad = pdvar(2, {[0 1]}, "full", RateBounds=[0 1]);

    U = triu(P);
    S = P(:, 1);
    B = blkdiag(P, 1);
    H = [Q, R];
    G = blkdiag(Q(1, 1), R(1, 1));
    A = rateAssign(P, R);

    testCase.verifyEqual(U.RateBounds, rb);
    testCase.verifyEqual(S.RateBounds, rb);
    testCase.verifyEqual(B.RateBounds, rb);
    testCase.verifyEqual(H.RateBounds, rb);
    testCase.verifyEqual(G.RateBounds, rb);
    testCase.verifyEqual(A.RateBounds, rb);
    testCase.verifyError(@() [R, Bad], "pdvar:InvalidConcatenation");
    testCase.verifyError(@() blkdiag(R, Bad), "pdvar:InvalidBlkdiag");
    testCase.verifyError(@() rateAssign(R, Bad), "pdvar:InvalidAssignment");
end

function test_unsupported_dimensions_source_modes_nonlinear_blocks(testCase)
    % Unsupported dimensions, source modes, and nonlinear blocks should fail.
    P = pdvar(2, 1, {[0 1]}, "full");
    F = pdmat({[0 1]}, @(rho) [rho; rho]);
    x = sdpvar(1, 1);

    testCase.verifyError(@() cat(3, P, P), "pdvar:UnsupportedCatDimension");
    testCase.verifyError(@() [P, ones(3, 1)], "pdvar:InvalidConcatenation");
    testCase.verifyError(@() [P, F], "pdvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() [P, x * x], "pdvar:InvalidConcatenation");
    testCase.verifyError(@() cat("bad", P, P), ...
        "pdvar:InvalidConcatenation");

    Q = pdvar(3, 1, {[0 1]}, "full");
    R = pdvar(1, 2, {[0 1]}, "full");
    S = pdvar(1, 3, {[0 1]}, "full");
    testCase.verifyError(@() [P, Q], "pdvar:InvalidConcatenation");
    testCase.verifyError(@() [R; S], "pdvar:InvalidConcatenation");
end

function test_structural_methods_reject_malformed_dimensions(testCase)
    % Structural methods should reject malformed dimensions and source modes.
    P = pdvar(2, {[0 1]}, "full");
    F = pdmat({[0 1]}, @(rho) rho * eye(2));

    testCase.verifyError(@() blkdiag(P, F), "pdvar:FunctionOnlyAlgebra");
    testCase.verifyError(@() reshape(P, 3, 3), "pdvar:InvalidReshape");
    testCase.verifyError(@() diag(P, 3), "pdvar:InvalidDiag");
    testCase.verifyError(@() triu(P, 0.5), "pdvar:InvalidTriangularPart");
    testCase.verifyError(@() sum(P, "rows"), "pdvar:InvalidSum");
    testCase.verifyError(@() mean(P, [1 1]), "pdvar:InvalidMean");
    testCase.verifyError(@() cumsum(P, 0.5), "pdvar:InvalidCumsum");
    testCase.verifyError(@() cumsum(P, 1, "backward"), ...
        "pdvar:InvalidCumsum");
    testCase.verifyError(@() rot90(P, 0.5), "pdvar:InvalidRot90");
    testCase.verifyError(@() repmat(P, [1 2 3]), "pdvar:InvalidRepmat");
end

function P = rateAssign(P, R)
    % Exercise rate-dependent assignment through a local helper.
    P(:, :) = R;
end
