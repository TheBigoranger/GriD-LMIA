function tests = test_bernstein_utils
%TEST_BERNSTEIN_UTILS Public grid, Bernstein order, and count contracts.
tests = functiontests(localfunctions);
end

function testLblOrder(testCase)
% Label enumeration should be scalar-compatible and tensor row-major.
scalar = pdbase({[0 1]}, [1 1], 2);
tensor = pdbase({[0 1], [10 20]}, [1 1], 1);

% Local labels and physical cells must share the same flat row order.
testCase.verifyEqual(scalar.lbls(), [0; 1; 2]);
testCase.verifyEqual(tensor.lbls(), [0 0; 0 1; 1 0; 1 1]);
end

function testCellOrder(testCase)
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

function testCoeffCount(testCase)
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

function testDefaultCount(testCase)
% Default local coefficients should allocate zero matrices of MatrixSize.
obj = pdbase({[0 1 2], [10 20]}, [2 2], 1);
coeffs = obj.coeffs([2 1]);

testCase.verifyEqual(numel(coeffs), obj.ncoeff());
for k = 1:numel(coeffs)
    testCase.verifyEqual(coeffs{k}, zeros(2));
end
end

function testGridInfoFields(testCase)
% GridInfo should expose stable primitive grid metadata only.
obj = pdbase({[0 1], [10 20 30]}, [1 1], 1);

testCase.verifyEqual(fieldnames(obj.GridInfo), ...
    {'Vectors'; 'Points'; 'Bounds'; 'NumNodes'});
testCase.verifyEqual(obj.GridInfo.Vectors, {[0 1], [10 20 30]});
testCase.verifyEqual(obj.GridInfo.Bounds, [0 1; 10 30]);
testCase.verifyEqual(obj.GridInfo.NumNodes, [2 3]);
end

function testGridInfoPointOrder(testCase)
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
