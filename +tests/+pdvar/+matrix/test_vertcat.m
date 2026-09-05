function tests = test_vertcat
    % Public pdvar.vertcat behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_fixed_rate_numeric_blocks_keep_order(testCase)
    % Known rows broadcast into each fixed-rate coefficient without new decisions.
    tests.infrastructure.verify_tensor_transform(testCase,"pdvar", ...
        @(x) vertcat([2 -3 5],x,[7 11 -13]),"fixed");
end

function test_function_only_concatenation_is_rejected(testCase)
    % Handle-only inputs remain ineligible in either vertical operand position.
    P = pdvar(1,3,[0 2 5],'full');
    F = pdmat([0 2 5],@(r) [r r+1 r-2]);
    testCase.verifyError(@() vertcat(P,F),'pdvar:FunctionOnlyAlgebra');
    testCase.verifyError(@() vertcat(F,P),'pdvar:FunctionOnlyAlgebra');
end

function test_native_block_order_all_rows(testCase)
    A=tests.infrastructure.fixture("pdvar",true);
    testCase.verifyError(@() vertcat(A,ones(3)),"pdvar:InvalidConcatenation");
    B=vertcat(A,7*A);
    for cellIndex=1:2
        c=A.coeffs(cellIndex);
        expected=cellfun(@(x) cat(1,x,7*x),c,'UniformOutput',false);
        tests.infrastructure.verify_expr(testCase,B.coeffs(cellIndex),expected);
    end
end
