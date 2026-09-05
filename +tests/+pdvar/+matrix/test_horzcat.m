function tests = test_horzcat
    % Public pdvar.horzcat behavioral contracts.
    tests = functiontests(localfunctions);
end

function test_tensor_fixed_rate_numeric_blocks_keep_order(testCase)
    % Known columns broadcast into each fixed-rate coefficient without new decisions.
    tests.infrastructure.verify_tensor_transform(testCase,"pdvar", ...
        @(x) horzcat([2;-3],x,[5;7]),"fixed");
end

function test_function_only_concatenation_is_rejected(testCase)
    % Handle-only inputs remain ineligible even beside a valid decision block.
    P = pdvar(2,1,[0 2 5],'full');
    F = pdmat([0 2 5],@(r) [r;r+1]);
    testCase.verifyError(@() horzcat(P,F),'pdvar:FunctionOnlyAlgebra');
    testCase.verifyError(@() horzcat(F,P),'pdvar:FunctionOnlyAlgebra');
end

function test_native_block_order_all_rows(testCase)
    A=tests.infrastructure.fixture("pdvar",true);
    testCase.verifyError(@() horzcat(A,ones(3)),"pdvar:InvalidConcatenation");
    B=horzcat(A,7*A);
    for cellIndex=1:2
        c=A.coeffs(cellIndex);
        expected=cellfun(@(x) cat(2,x,7*x),c,'UniformOutput',false);
        tests.infrastructure.verify_expr(testCase,B.coeffs(cellIndex),expected);
    end
end
