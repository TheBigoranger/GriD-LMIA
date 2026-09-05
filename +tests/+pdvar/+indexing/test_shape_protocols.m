function tests = test_shape_protocols
    % Public pdvar.shape_protocols behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_zero_degree_axis_has_independent_matrix_shape(testCase)
    % Cell/label counts and scalar-container indexing must not mix dimensions.
    P = pdvar(2,3,{[0 2 5],[-3 1 6]},'full',Degree=[0 2]);
    testCase.verifyEqual(P.cells(),[1 1;1 2;2 1;2 2]);
    testCase.verifyEqual(P.lbls(),[0 0;0 1;0 2]);
    testCase.verifyEqual([ncell(P),ncoeff(P),npar(P)],[4 3 2]);
    testCase.verifyEqual(size(P),[2 3]);
    testCase.verifyEqual([numel(P),length(P),ndims(P)],[6 3 2]);
    first = P.coeffs([1 2]);
    second = P.coeffs([2 2]);
    tests.infrastructure.verify_expr(testCase,first,second);
end

function test_payload_shape_and_container_indexing(testCase)
    A = tests.infrastructure.fixture("pdvar", false);
    B = repmat(A, 1, 3);
    [m, n, trailing] = size(B);
    testCase.verifyEqual([m n trailing], [2 6 1]);
    testCase.verifyEqual(size(B, 4), 1);
    testCase.verifyEqual([height(B) width(B) length(B) ndims(B)], [2 6 6 2]);
    testCase.verifyEqual(numel(B), 12);
    testCase.verifyEqual(numel(B, 1, 1), 1);
    testCase.verifyEqual(numArgumentsFromSubscript(B, substruct('()', {1,1}), []), 1);
    testCase.verifyEqual([feval('end',B,1,1) feval('end',B,1,2) feval('end',B,2,2) feval('end',B,3,3)], [12 2 6 1]);
    testCase.verifyEqual(B.MatrixSize, [2 6]);
end

function test_complete_cell_and_label_order(testCase)
    A = tests.infrastructure.fixture("pdvar", false);
    testCase.verifyEqual(A.cells(), [1;2]);
    testCase.verifyEqual(A.lbls(), [0;1;2]);
    testCase.verifyEqual([ncell(A) ncoeff(A) npar(A)], [2 3 1]);
    testCase.verifyEqual(A.coeffs(2), A.LocalValues{2});
    testCase.verifyError(@() A.coeffs(3), 'pdbase:InvalidCellSubs');
end
