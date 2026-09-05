function tests = test_cat
    % Behavioral regressions for pdmat.cat.
    tests = functiontests(localfunctions);
end

function test_parent_forwarding_dispatch_object_first_numeric(testCase)
    % Parent forwarding should dispatch for object-first and numeric-first forms.
    A = pdmat({[0 1]}, {[1; 2], [3; 4]}, Degree=1);
    B = pdmat({[0 1]}, {[10 20; 30 40], [50 60; 70 80]}, Degree=1);

    H = [A, B];
    V = [A; A];
    Nleft = [zeros(2, 1), A];
    Ntop = [0; A];
    scalar = pdmat({[0 1]}, {1, 2}, Degree=1);
    scalarRow = [scalar, 3, 4];
    scalarCol = [scalar; 3; 4];

    testCase.verifyEqual(size(H), [2 3]);
    testCase.verifyEqual(size(V), [4 1]);
    testCase.verifyEqual(size(Nleft), [2 2]);
    testCase.verifyEqual(size(Ntop), [3 1]);
    testCase.verifyEqual(size(scalarRow), [1 3]);
    testCase.verifyEqual(size(scalarCol), [3 1]);
    tests.infrastructure.verify_coeff(testCase, H, 1, {
        [1 10 20; 2 30 40], ...
        [3 50 60; 4 70 80]
        });
    tests.infrastructure.verify_coeff(testCase, V, 1, {
        [1; 2; 1; 2], ...
        [3; 4; 3; 4]
        });
    tests.infrastructure.verify_coeff(testCase, Nleft, 1, {
        [0 1; 0 2], ...
        [0 3; 0 4]
        });
    tests.infrastructure.verify_coeff(testCase, Ntop, 1, {
        [0; 1; 2], ...
        [0; 3; 4]
        });
end

function test_cat_elevate_degrees_dim_1_2(testCase)
    % cat should elevate degrees for dim 1/2 and reject unsupported dimensions.
    A = pdmat({[0 1]}, {[1; 3], [2; 4]}, Degree=1);
    B = pdmat({[0 1]}, {[10; 10], [20; 20], [30; 30]}, Degree=2);

    C = cat(2, A, B);

    testCase.verifyEqual(C.Degree, 2);
    tests.infrastructure.verify_coeff(testCase, C, 1, {
        [1 10; 3 10], ...
        [1.5 20; 3.5 20], ...
        [2 30; 4 30]
        });
    testCase.verifyError(@() cat(3, A, A), "pdmat:UnsupportedCatDimension");
    % Two degree-one operands share a degree plan but have different widths.
    % Both must be elevated before joining the degree-two anchor B.
    wide = pdmat({[0 1]}, {[5 7; 9 11], [13 15; 17 19]}, Degree=1);
    mixed = cat(2, A, wide, B);
    tests.infrastructure.verify_coeff(testCase, mixed, 1, {
        [1 5 7 10; 3 9 11 10], ...
        [1.5 9 11 20; 3.5 13 15 20], ...
        [2 13 15 30; 4 17 19 30]});
end
function test_function_only_block_operands_rejected(testCase)
    % Every operand position must provide real coefficient evidence.
    F = pdmat([0 1], @(x) 1+x);
    A = pdmat([0 1], {1,2}, Degree=1);
    calls = {@() cat(2,F,A), @() cat(2,A,F), @() cat(1,F,A), @() cat(1,A,F)};
    for k = 1:numel(calls)
        testCase.verifyError(calls{k}, "pdmat:FunctionOnlyAlgebra");
    end
end

function test_tensor_refinement_degree_alignment_and_block_order(testCase)
    % Distinct polynomials prevent constant blocks from hiding alignment errors.
    f = @(x,y) [x^2+y; x*y];
    g = @(x,y) [x-y^2, 2*x; y^2, -3+y];
    A = pdmat({[0 .5 2], [-1 3]}, f, Degree=[2 1]);
    B = pdmat({[0 2], [-1 0 3]}, g, Degree=[1 2]);
    C = cat(2, A, B);
    testCase.verifyEqual(C.Degree, [2 2]);
    testCase.verifyEqual(C.GridInfo.Vectors, {[0 .5 2], [-1 0 3]});
    for x = [0 .25 .5 1.25 2]
        for y = [-1 -.5 0 1.5 3]
            expected = cat(2, f(x,y), g(x,y));
            testCase.verifyEqual(C.evaluate([x y]), expected, AbsTol=1e-10);
        end
    end
    testCase.verifyEmpty(C.FunctionHandle);
end

function test_concatenation_validates_dimension_non_scalar_block(testCase)
    % Concatenation validates its dimension and non-scalar block extents.
    A = pdmat({[0 1]}, {zeros(2, 1), ones(2, 1)}, Degree=1);
    B = pdmat({[0 1]}, {zeros(3, 1), ones(3, 1)}, Degree=1);
    C = pdmat({[0 1]}, {zeros(1, 2), ones(1, 2)}, Degree=1);
    D = pdmat({[0 1]}, {zeros(1, 3), ones(1, 3)}, Degree=1);

    testCase.verifyError(@() cat("bad", A, A), ...
        "pdmat:InvalidConcatenation");
    testCase.verifyError(@() [A, B], "pdmat:InvalidConcatenation");
    testCase.verifyError(@() [C; D], "pdmat:InvalidConcatenation");
end
