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

function testPublicElevationScalarExactAndNonMutating(testCase)
% Public elevation changes the basis, not the source object's evidence.
vals = {{0, 1}, {2, 4}};
obj = dpbase({[0 1 2]}, [1 1], 1, vals);
before = obj.LocalValues;

same = obj.elevVals(0);
once = obj.elevVals(1);
twice = obj.elevVals(2);

testCase.verifyEqual(same, vals);
testCase.verifyEqual(once{1}, {0, 0.5, 1});
testCase.verifyEqual(once{2}, {2, 3, 4});
testCase.verifyEqual(twice{1}, {0, 1 / 3, 2 / 3, 1}, AbsTol=1e-14);
testCase.verifyEqual(twice{2}, {2, 8 / 3, 10 / 3, 4}, AbsTol=1e-14);
testCase.verifyEqual(obj.LocalValues, before);
testCase.verifyEqual(obj.Degree, 1);
end

function testPublicElevationTensorCombRowsOrder(testCase)
% Tensor elevation must retain the package-wide combRows coefficient order.
vals = {{{0, 2, 4, 6}}};
obj = dpbase({[0 1], [10 20]}, [1 1], 1, vals);

out = obj.elevVals(1);

expected = {0, 1, 2, 2, 3, 4, 4, 5, 6};
testCase.verifyEqual(out{1}{1}, expected);
testCase.verifyEqual(size(out{1}{1}), [1 9]);
end

function testPublicElevationPreservesRateRows(testCase)
% Rate vertices are rows and must be elevated without reordering or mixing.
vals = {{0, 2; 10, 14}};
obj = dpbase({[0 1]}, [1 1], 1, vals, ...
    HasRateDependence=true, RateBounds=[-1 1]);

out = obj.elevVals(1);

testCase.verifyEqual(out{1}, {0, 1, 2; 10, 12, 14});
testCase.verifyEqual(size(out{1}), [2 3]);
testCase.verifyEqual(obj.LocalValues, vals);
testCase.verifyEqual(obj.RateBounds, [-1 1]);
end

function testPublicElevationRejectsInvalidIncrement(testCase)
% Invalid increments should fail before any coefficient tree is transformed.
obj = dpbase({[0 1]}, [1 1], 1, {{0, 1}});

bad = {-1, 0.5, Inf, NaN, "one", [1 2]};
for k = 1:numel(bad)
    testCase.verifyError(@() obj.elevVals(bad{k}), ...
        "dpbase:InvalidDegreeIncrement");
end
end

function testPublicElevationRejectsFunctionOnlyDpmat(testCase)
% Function-only dpmat placeholders are not Bernstein coefficient evidence.
obj = dpmat({[0 1]}, @(rho) 1 + rho);

testCase.verifyError(@() obj.elevVals(1), ...
    "dpbase:MissingCoefficientEvidence");
end
