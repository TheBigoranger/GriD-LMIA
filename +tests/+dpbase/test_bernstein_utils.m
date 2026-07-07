function tests = test_bernstein_utils
%TEST_BERNSTEIN_UTILS Public Bernstein row-order and count contracts.
tests = functiontests(localfunctions);
end

function testLblOrder(testCase)
% Label enumeration should be scalar-compatible and tensor row-major.
scalar = dpbase({[0 1]}, [1 1], 2);
tensor = dpbase({[0 1], [10 20]}, [1 1], 1);

% Local labels and physical cells must share the same flat row order.
testCase.verifyEqual(scalar.lbls(), [0; 1; 2]);
testCase.verifyEqual(tensor.lbls(), [0 0; 0 1; 1 0; 1 1]);
end

function testCellOrder(testCase)
% Physical cell enumeration should use the same row order as labels.
obj = dpbase({[0 1 2], [10 20 30 40]}, [1 1], 0);

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
scalar = dpbase({[0 1]}, [1 1], 2);
tensorDeg1 = dpbase({[0 1], [10 20]}, [1 1], 1);
tensorDeg2 = dpbase({[0 1], [10 20]}, [1 1], 2);

testCase.verifyEqual(scalar.ncoeff(), 3);
testCase.verifyEqual(tensorDeg1.ncoeff(), 4);
testCase.verifyEqual(tensorDeg2.ncoeff(), 9);
end

function testDefaultCount(testCase)
% Default local coefficients should allocate zero matrices of MatrixSize.
obj = dpbase({[0 1 2], [10 20]}, [2 2], 1);
coeffs = obj.coeffs([2 1]);

testCase.verifyEqual(numel(coeffs), obj.ncoeff());
for k = 1:numel(coeffs)
    testCase.verifyEqual(coeffs{k}, zeros(2));
end
end
