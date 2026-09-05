function tests = test_indexing
    % Behavioral regressions for pdvar.indexing.
    tests = functiontests(localfunctions);
end

function test_three_dimensional_and_empty_selectors_are_rejected(testCase)
    % Unsupported shape changes do not mutate symbolic source handles.
    P = pdvar(2,3,{[0 2 5],[-3 1 6]},'full',Degree=[1 2]);
    saved = P.LocalValues;
    testCase.verifyError(@() P(1,2,1),'pdvar:InvalidSubscript');
    testCase.verifyError(@() P([],1),'pdvar:InvalidSubscript');
    testCase.verifyError(@() P([1 3],1),'pdvar:InvalidSubscript');
    testCase.verifyEqual(P.LocalValues,saved);
end

function test_function_only_block_assignment_is_rejected(testCase)
    % An exact evaluator cannot populate an affine coefficient block.
    P = pdvar(2,3,[0 2 5],'full',Degree=2);
    F = pdmat([0 2 5],@(r) r);
    saved = P.LocalValues;
    testCase.verifyError(@() subsasgn(P,substruct('()',{2,3}),F), ...
        'pdvar:FunctionOnlyAlgebra');
    testCase.verifyEqual(P.LocalValues,saved);
end

function setupOnce(~)
    % Clear YALMIP global state so variable IDs do not leak between tests.
    yalmip("clear");
end

function test_unsupported_indexing_assignment_forms_fail_stable(testCase)
    % Unsupported indexing and assignment forms should fail with stable IDs.
    P = pdvar(2, {[0 1]}, "full");
    R = pdvar(2, {[0 1]}, "full", RateBounds=[-1 1]);
    x = sdpvar(1, 1);

    testCase.verifyError(@() P(1), "pdvar:InvalidSubscript");
    testCase.verifyError(@() deleteAssign(P), "pdvar:UnsupportedAssignment");
    testCase.verifyError(@() growAssign(P), "pdvar:InvalidAssignment");
    testCase.verifyError(@() badSizeAssign(P), "pdvar:InvalidAssignment");
    testCase.verifyError(@() nonlinearAssign(P, x), "pdvar:InvalidAssignment");
    testCase.verifyError(@() nestedAssign(P), "pdvar:UnsupportedAssignment");
    testCase.verifyError(@() setSummary(P), "MATLAB:class:SetProhibited");
    testCase.verifyEqual(rateAssign(P, R).RateBounds, [-1 1]);
end

function nestedAssign(P)
    % Nested assignment is outside the pdvar coefficient-block contract.
    S = substruct("()", {1, 1}, ".", "field");
    subsasgn(P, S, 1);
end

function setSummary(P)
    % Dot assignment reaches MATLAB's private-set property guard.
    P.SourceSummary = "changed";
end

function deleteAssign(P)
    % Exercise deletion-assignment rejection through a local function handle.
    P(1, :) = [];
end

function growAssign(P)
    % Exercise out-of-bounds growth rejection through a local function handle.
    P(3, :) = 1;
end

function badSizeAssign(P)
    % Exercise block-size mismatch rejection through a local function handle.
    P(1, :) = ones(2);
end

function nonlinearAssign(P, x)
    % Exercise nonlinear sdpvar assignment rejection through a local helper.
    P(1, 1) = x * x;
end

function P = rateAssign(P, R)
    % Exercise rate-dependent assignment through a local helper.
    P(:, :) = R;
end
