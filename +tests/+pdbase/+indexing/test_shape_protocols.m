function tests = test_shape_protocols
    % Public pdbase.shape_protocols behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_rectangular_fixed_rate_shape_is_not_coefficient_count(testCase)
    % Six matrix entries remain distinct from three coefficients and one rate row.
    A=pdbase({[0 2 5],[-3 1 6]},[2 3],[0 2],RateBounds=[3 3;-2 -2]);
    D=rhodiff(A);
    testCase.verifyEqual([height(D) width(D) length(D) numel(D)],[2 3 3 6]);
    testCase.verifyEqual([ncell(D) ncoeff(D) npar(D)],[4 3 2]);
    testCase.verifyEqual(D.NumRateRows,1);
    testCase.verifyEqual(feval('end',D,1,1),6);
    testCase.verifyEqual(D.coeffs([2 2]),{zeros(2,3),zeros(2,3),zeros(2,3)});
    testCase.verifyError(@() D.coeffs([2 3]),'pdbase:InvalidCellSubs');
end

function test_payload_shape_and_container_indexing(testCase)
    A = tests.infrastructure.fixture("pdbase", false);
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
    A = tests.infrastructure.fixture("pdbase", false);
    testCase.verifyEqual(A.cells(), [1;2]);
    testCase.verifyEqual(A.lbls(), [0;1;2]);
    testCase.verifyEqual([ncell(A) ncoeff(A) npar(A)], [2 3 1]);
    testCase.verifyEqual(A.coeffs(2), A.LocalValues{2});
    testCase.verifyError(@() A.coeffs(3), 'pdbase:InvalidCellSubs');
end
