function tests = test_indexing
    % Behavioral regressions for pdmat.indexing.
    tests = functiontests(localfunctions);
end
function test_reshape_then_repeated_indexing_retains_fixed_rate_row(testCase)
    % Reordered matrix indices must not reorder physical cells or rate rows.
    A = pdmat({[0 2 5], [-1 3]}, ...
        @(x,y) [x^2+y, x*y, y^2; 3*x-y, x^2-y, 1+x*y], ...
        Degree=[2 2], RateBounds=[2 2; -3 -3]);
    A = rhodiff(A);
    B = reshape(A,3,2);
    C = B([3 1 3],end:-1:1);
    for subs = A.cells()'
        input = A.coeffs(subs');
        expected = cell(size(input));
        for k = 1:numel(input)
            matrix = reshape(input{k},3,2);
            expected{k} = matrix([3 1 3],[2 1]);
        end
        testCase.verifyEqual(C.coeffs(subs'), expected, AbsTol=1e-10);
    end
    testCase.verifyEqual(C.NumRateRows, 1);
    testCase.verifyEqual(C.RateBounds, [2 2; -3 -3]);
    testCase.verifyEqual(C.MatrixSize, [3 2]);
end

function test_matlab_end_contexts_logical_shapes_reach(testCase)
    % MATLAB end contexts and logical shapes reach the shared index guards.
    A = pdmat({[0 1]}, {reshape(1:6, 2, 3), zeros(2, 3)}, Degree=1);
    B = pdmat({[0 1], [10 20]}, @(x, y) x + 0 * y, Degree=[1 1]);

    testCase.verifyError(@() linearEnd(A), "pdmat:InvalidSubscript");
    testCase.verifyError(@() higherEnd(A), "pdmat:InvalidSubscript");
    testCase.verifyError(@() A([true false; false true], :), ...
        "pdmat:InvalidSubscript");
    testCase.verifyError(@() A + B, "pdmat:MixedGrid");
end

function test_unsupported_indexing_assignment_forms_fail_stable(testCase)
    % Unsupported indexing and assignment forms should fail with stable IDs.
    A = pdmat({[0 1]}, {zeros(2), ones(2)}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho * eye(2));

    testCase.verifyError(@() A(1), "pdmat:InvalidSubscript");
    testCase.verifyError(@() F(:, 1), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() deleteAssign(A), "pdmat:UnsupportedAssignment");
    testCase.verifyError(@() growAssign(A), "pdmat:InvalidAssignment");
    testCase.verifyError(@() badSizeAssign(A), "pdmat:InvalidAssignment");
    testCase.verifyError(@() nestedAssign(A), "pdmat:UnsupportedAssignment");
    testCase.verifyError(@() assignFunction(F), "pdmat:FunctionOnlyAlgebra");
    testCase.verifyError(@() setSummary(A), "MATLAB:class:SetProhibited");
end

function linearEnd(A)
    % One-subscript syntax evaluates end before pdmat rejects linear indexing.
    A(end);
end

function higherEnd(A)
    % A trailing subscript evaluates the singleton higher-dimensional end.
    A(1, 1, end);
end

function deleteAssign(A)
    % Exercise deletion-assignment rejection through a local function handle.
    A(1, :) = [];
end

function growAssign(A)
    % Exercise out-of-bounds growth rejection through a local function handle.
    A(3, :) = 1;
end

function badSizeAssign(A)
    % Exercise block-size mismatch rejection through a local function handle.
    A(1, :) = ones(2);
end

function nestedAssign(A)
    % Nested assignment is outside the coefficient-block contract.
    S = substruct("()", {1, 1}, ".", "field");
    subsasgn(A, S, 1);
end

function assignFunction(F)
    % Function-only data cannot acquire coefficient blocks by assignment.
    F(1, 1) = 0;
end

function setSummary(A)
    % Dot assignment reaches MATLAB's private-set property guard.
    A.SourceSummary = "changed";
end
