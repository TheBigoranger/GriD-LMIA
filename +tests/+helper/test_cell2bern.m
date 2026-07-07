function tests = test_cell2bern
    %TEST_CELL2BERN Helper global-grid to local Bernstein conversion.
    tests = functiontests(localfunctions);
end

function testScalarDegreeTwo(testCase)
    % Scalar degree-2 data should split into overlapping local cells.
    data = {10, 11, 12, 13, 14};

    [flat, subs] = helper.cell2bern({[0 1 2]}, data, Degree=2);

    testCase.verifyEqual(subs, [1; 2]);
    testCase.verifyEqual(numel(flat), 2);
    testCase.verifyEqual(flat{1}, {10, 11, 12});
    testCase.verifyEqual(flat{2}, {12, 13, 14});
end

function testTensorOrderMatchesDpmatCoeffs(testCase)
    % Tensor conversion should match dpmat's coefficient row order exactly.
    data = cell(3, 2);
    for i = 1:3
        for j = 1:2
            data{i, j} = [i, j];
        end
    end

    [flat, subs] = helper.cell2bern({[0 1 2], [10 20]}, data, Degree=1);
    A = dpmat({[0 1 2], [10 20]}, data, Degree=1);

    testCase.verifyEqual(subs, [1 1; 2 1]);
    testCase.verifyEqual(flat{1}, A.coeffs([1 1]));
    testCase.verifyEqual(flat{2}, A.coeffs([2 1]));
    testCase.verifyEqual(numel(flat{2}), 4);
    testCase.verifyEqual(flat{2}, {[2 1], [2 2], [3 1], [3 2]});
end

function testValidation(testCase)
    % Malformed data, degree choices, and options should fail clearly.
    testCase.verifyError(@() helper.cell2bern({[0 1]}, {1, "bad"}, Degree=1), ...
        "cell2bern:InvalidData");
    testCase.verifyError(@() helper.cell2bern({[0 1 2]}, {1, 2, 3, 4}), ...
        "cell2bern:InvalidDegree");
    testCase.verifyError(@() helper.cell2bern({[0 1 2]}, {1, 2, 3}, Degree=2), ...
        "cell2bern:InvalidDegree");
    testCase.verifyError(@() helper.cell2bern({[0 1]}, {1, 2}, BadOption=true), ...
        "cell2bern:UnknownOption");
end
