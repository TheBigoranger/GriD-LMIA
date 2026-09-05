function tests = test_grid_protocols
    % Behavioral regressions for pdbase.grid_protocols.
    tests = functiontests(localfunctions);
end

function test_three_axis_zero_degree_labels_and_complete_cells(testCase)
    % Physical traversal and coefficient traversal have independent tensor sizes.
    A = pdbase({[0 2 5],[-3 1],[7 8 11]},[2 3],[0 2 1]);
    testCase.verifyEqual(A.cells(),[1 1 1;1 1 2;2 1 1;2 1 2]);
    testCase.verifyEqual(A.lbls(),[0 0 0;0 0 1;0 1 0;0 1 1;0 2 0;0 2 1]);
    testCase.verifyEqual([ncell(A) ncoeff(A) npar(A)],[4 6 3]);
    for s = [1 1 1;1 1 2;2 1 1;2 1 2].'
        testCase.verifyEqual(A.coeffs(s.'),repmat({zeros(2,3)},1,6));
    end
end

function test_label_enumeration_scalar_compatible_tensor_row(testCase)
% Label enumeration should be scalar-compatible and tensor row-major.
scalar = pdbase({[0 1]}, [1 1], 2);
tensor = pdbase({[0 1], [10 20]}, [1 1], 1);

% Local labels and physical cells must share the same flat row order.
testCase.verifyEqual(scalar.lbls(), [0; 1; 2]);
testCase.verifyEqual(tensor.lbls(), [0 0; 0 1; 1 0; 1 1]);
end

function test_physical_cell_enumeration_same_row_order(testCase)
% Physical cell enumeration should use the same row order as labels.
obj = pdbase({[0 1 2], [10 20 30 40]}, [1 1], 0);

expected = [
    1 1
    1 2
    1 3
    2 1
    2 2
    2 3
];
testCase.verifyEqual(obj.cells(), expected);
end

function test_ncoeff_report_bernstein_coefficient_count_local(testCase)
% ncoeff should report the Bernstein coefficient count per local cell.
scalar = pdbase({[0 1]}, [1 1], 2);
tensorDeg1 = pdbase({[0 1], [10 20]}, [1 1], 1);
tensorDeg2 = pdbase({[0 1], [10 20]}, [1 1], 2);
anisotropic = pdbase({[0 1], [10 20], [-1 1]}, [1 1], [1 3 0]);

testCase.verifyEqual(scalar.ncoeff(), 3);
testCase.verifyEqual(tensorDeg1.ncoeff(), 4);
testCase.verifyEqual(tensorDeg2.ncoeff(), 9);
testCase.verifyEqual(anisotropic.ncoeff(), 8);
testCase.verifyEqual(anisotropic.Degree, [1 3 0]);
end

function test_default_local_coefficients_allocate_zero_matrices(testCase)
% Default local coefficients should allocate zero matrices of MatrixSize.
obj = pdbase({[0 1 2], [10 20]}, [2 2], 1);
coeffs = obj.coeffs([2 1]);

testCase.verifyEqual(numel(coeffs), obj.ncoeff());
for k = 1:numel(coeffs)
    testCase.verifyEqual(coeffs{k}, zeros(2));
end
end

function test_gridinfo_expose_stable_primitive_grid_metadata(testCase)
% GridInfo should expose stable primitive grid metadata only.
obj = pdbase({[0 1], [10 20 30]}, [1 1], 1);

testCase.verifyEqual(fieldnames(obj.GridInfo), ...
    {'Vectors'; 'Points'; 'Bounds'; 'NumNodes'});
testCase.verifyEqual(obj.GridInfo.Vectors, {[0 1], [10 20 30]});
testCase.verifyEqual(obj.GridInfo.Bounds, [0 1; 10 30]);
testCase.verifyEqual(obj.GridInfo.NumNodes, [2 3]);
end

function test_tensor_grid_points_follow_matlab_row(testCase)
% Tensor grid points should follow MATLAB row-order enumeration.
obj = pdbase({[0 1], [10 20 30]}, [1 1], 0);

expected = [
    0    10
    0    20
    0    30
    1    10
    1    20
    1    30
    ];
testCase.verifyEqual(obj.GridInfo.Points, expected);
end
