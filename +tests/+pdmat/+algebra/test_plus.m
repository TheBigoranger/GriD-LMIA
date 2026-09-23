function tests = test_plus
    % Behavioral regressions for pdmat.plus.
    tests = functiontests(localfunctions);
end

function test_function_only_zero_shortcuts_rejected(testCase)
    % Placeholder zeros cannot authorize an arithmetic identity shortcut.
    F = pdmat([0 1], @(x) [x 2*x; 3*x 1+x]);
    Z = pdmat([0 1], {zeros(2), zeros(2)}, Degree=1);
    saved = F.LocalValues;
    calls = {@() F + 0, @() 0 + F, @() F + zeros(2), ...
        @() zeros(2) + F, @() F + Z, @() Z + F};
    for k = 1:numel(calls)
        testCase.verifyError(calls{k}, "pdmat:FunctionOnlyAlgebra");
    end
    testCase.verifyEqual(F.LocalValues, saved);
    testCase.verifyEqual(F.evaluate(0.5), [0.5 1; 1.5 1.5]);
end

function test_addition_elevate_lower_degree_operands_summing(testCase)
    % Addition should elevate lower-degree operands before summing coefficients.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);
    B = pdmat({[0 1]}, {10, 20, 30}, Degree=2);

    C = A + B;

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyTrue(C.IsContinuous);
    testCase.verifyEqual(C.SourceSummary, "coefficient-backed");
    testCase.verifyEmpty(C.FunctionHandle);
    tests.infrastructure.verify_coeff(testCase, C, 1, {11, 21.5, 32});
end

function test_numeric_scalars_promote_compatible_constant_pdmat(testCase)
    % Numeric scalars should promote to compatible constant pdmat operands.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);

    tests.infrastructure.verify_coeff(testCase, A + 5, 1, {6, 7});
    tests.infrastructure.verify_coeff(testCase, 5 - A, 1, {4, 3});
    tests.infrastructure.verify_coeff(testCase, 2 * A, 1, {2, 4});
    tests.infrastructure.verify_coeff(testCase, A * 3, 1, {3, 6});
end

function test_proven_numeric_zeros_identities_only_size(testCase)
    % Proven and numeric zeros are identities only after size and grid checks.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);
    Z = A - A;

    testCase.verifyTrue(isequal(Z + A, A));
    testCase.verifyTrue(isequal(A + Z, A));
    testCase.verifyTrue(isequal(A + 0, A));
    testCase.verifyTrue(isequal(zeros(1) + A, A));

    matrixZero = pdmat({[0 1]}, {zeros(2), zeros(2)}, Degree=1);
    scalarData = pdmat({[0 1]}, {1, 2}, Degree=1);
    testCase.verifyError(@() matrixZero + scalarData, ...
        "pdmat:InvalidAddition");

    otherGrid = pdmat({[0 2]}, {1, 2}, Degree=1);
    testCase.verifyError(@() Z + otherGrid, "pdmat:MixedGrid");

    matrixZero = pdmat({[0 1]}, {zeros(2), zeros(2)}, Degree=1);
    testCase.verifyError(@() A - matrixZero, ...
        "pdmat:InvalidSubtraction");
end

function test_ordinary_operands_broadcast_products_allow_explicit(testCase)
    % Ordinary operands broadcast; products allow explicit rows on one side.
    R = rateScalar();
    A = pdmat([0 1], {2, 4}, Degree=1, RateBounds=[-1 2]);

    verifyRows(testCase, R + A, {3, 7; 12, 18});
    verifyRows(testCase, A - R, {1, 1; -8, -10});
    verifyRows(testCase, 5 - R, {4, 2; -5, -9});
    verifyRows(testCase, R * A, {2, 5, 12; 20, 34, 56});
    verifyRows(testCase, A * R, {2, 5, 12; 20, 34, 56});
    testCase.verifyError(@() R * R, "pdmat:InvalidMultiplication");
end

function R = rateScalar()
    % A two-row scalar fixture with one physical cell.
    R = pdmat([0 1], {{1, 3; 10, 14}}, ...
        Degree=1, RateBounds=[-1 2]);
end

function verifyRows(testCase, obj, expected)
    % Assert numeric rows, order, and rate metadata together.
    testCase.verifyEqual(obj.coeffs(1), expected, AbsTol=1e-10);
    verifyRateMeta(testCase, obj, [1 1]);
end

function verifyRateMeta(testCase, obj, sz)
    % Explicit rows remain rate-dependent and preserve their matrix shape.
    testCase.verifyEqual(size(obj), sz);
    testCase.verifyEqual(obj.RateBounds, [-1 2]);
    testCase.verifyEqual(size(obj.coeffs(1), 1), 2);
end

function test_complete_residual_in_both_orders(testCase)
    A = tests.infrastructure.fixture("pdmat", true);
    saved = A.LocalValues;
    constant = [2 -7;11 3];
    left = A + constant;
    right = constant + A;
    for cellIndex = 1:2
        c = A.coeffs(cellIndex);
        tests.infrastructure.verify_expr(testCase,left.coeffs(cellIndex), ...
            cellfun(@(x) x + constant,c,'UniformOutput',false));
        tests.infrastructure.verify_expr(testCase,right.coeffs(cellIndex), ...
            cellfun(@(x) constant + x,c,'UniformOutput',false));
    end
    testCase.verifyEqual(A.LocalValues,saved);
    testCase.verifyError(@() A + ones(3), 'pdmat:InvalidAddition');
end

function test_refinement_preserves_discontinuous_source_cell_endpoints(testCase)
    % Subdivision uses the source cell polynomial on both closed endpoints.
    A=pdmat([0 .5 1],{{0,1},{10,11}},Degree=1);
    saved=A.LocalValues;
    B=pdmat([0 .25 .5 .75 1],{{1},{1},{1},{1}},Degree=0);
    C=A+B;
    expected={{1,1.5},{1.5,2},{11,11.5},{11.5,12}};
    for cellIndex=1:4
        testCase.verifyEqual(C.coeffs(cellIndex),expected{cellIndex},AbsTol=1e-13);
    end
    testCase.verifyEqual(C.evaluate(.4),1.8,AbsTol=1e-13);
    testCase.verifyEqual(C.evaluate(.5-eps),2,AbsTol=1e-13);
    testCase.verifyEqual(C.evaluate(.5),11,AbsTol=1e-13);
    testCase.verifyEqual(C.evaluate(.5+eps),11,AbsTol=1e-13);
    testCase.verifyEqual(C.Continuity,-1);
    testCase.verifyEqual(A.LocalValues,saved);
end

function test_three_axis_refinement_preserves_jumps_and_zero_degree_faces(testCase)
    % Each source cell represents offset + M*t1^2*t2, including z-axis jumps.
    grid = {[0 1 3],[-2 0 4],[10 12 16]};
    target = {[0 .5 1 2 3],[-2 -1 0 2 4],[10 11 12 14 16]};
    M = [1 -2 3;5 7 -11]; N = [2 3 5;7 11 13];
    values = cell(1,2);
    for i=1:2
        for j=1:2
            for k=1:2
                offset = (100*i+10*j+k)*ones(2,3);
                values{i}{j}{k} = [repmat({offset},1,5),{offset+M}];
            end
        end
    end
    A = pdmat(grid,values,Degree=[2 1 0]); saved=A.LocalValues;
    B = pdmat(target,@(x,y,z) N,Degree=[0 0 0]);
    C = A+B;
    for i=1:4
        for j=1:4
            for k=1:4
                source = ceil([i j k]/2);
                a = mod([i j]-1,2)/2; b=a+.5;
                offset=(100*source(1)+10*source(2)+source(3))*ones(2,3);
                expected=cell(1,6);
                for p=0:2
                    for q=0:1
                        expected{2*p+q+1}=offset+N+M*a(1)^(2-p)*b(1)^p*a(2)^(1-q)*b(2)^q;
                    end
                end
                testCase.verifyEqual(C.coeffs([i j k]),expected,AbsTol=1e-12);
            end
        end
    end
    testCase.verifyEqual(C.evaluate([1 0 12]),222*ones(2,3)+N);
    testCase.verifyEqual(C.Degree,[2 1 0]);
    testCase.verifyEqual(C.Continuity,[-1 -1 -1]);
    testCase.verifyEqual(A.LocalValues,saved);
end

function test_high_degree_graded_and_repeated_refinement_has_exact_monomial_controls(testCase)
    % On [a,b], the degree-d Bernstein controls of rho^d are a^(d-k)*b^k.
    final = [0 2^-16 2^-8 .125 .5 .75 1];
    M = [1 -2 3;5 -7 11]; N = [2 3 5;7 11 13]; K=ones(2,3);
    for degree=[8 12]
        values=[repmat({N},1,degree),{N+M}];
        A=pdmat([0 1],values,Degree=degree); saved=A.LocalValues;
        B=pdmat([0 .5 1],{K,K,K},Degree=1);
        C=pdmat(final,@(x) K,Degree=0);
        repeated=(A+B)+C; direct=A+2*C;
        for cellIndex=1:numel(final)-1
            a=final(cellIndex); b=final(cellIndex+1);
            expected=cell(1,degree+1);
            for k=0:degree
                expected{k+1}=N+2*K+M*a^(degree-k)*b^k;
            end
            testCase.verifyEqual(repeated.coeffs(cellIndex),expected,AbsTol=2e-12);
            testCase.verifyEqual(direct.coeffs(cellIndex),expected,AbsTol=2e-12);
        end
        testCase.verifyEqual(A.LocalValues,saved);
    end
end

function test_refinement_preserves_single_and_sparse_numeric_payloads(testCase)
    % Literal quadratic restrictions exercise both supported numeric classes.
    for convert={@single,@sparse}
        cast=convert{1}; M=cast([1 -2;3 0]); N=cast([2 0;0 5]);
        A=pdmat([0 1],{cast(zeros(2)),cast(zeros(2)),M},Degree=2);
        B=pdmat([0 .5 1],{{N},{N}},Degree=0);
        C=A+B;
        expected={{N,N,N+.25*M},{N+.25*M,N+.5*M,N+M}};
        for c=1:2
            actual=C.coeffs(c);
            for k=1:3
                testCase.verifyEqual(full(double(actual{k})), ...
                    full(double(expected{c}{k})),AbsTol=2e-6);
            end
        end
    end
end
