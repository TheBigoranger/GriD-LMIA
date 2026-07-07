function tests = test_diff
    %TEST_DIFF Cell-local derivative-row dpvar storage.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    yalmip("clear");
end

function testScalarDiffWarnsAndStoresRows(testCase)
    % diff(P) without rate metadata should warn but still build row storage.
    P = dpvar(1, {[0 2]});
    cp = P.coeffs(1);

    D = diffWithWarn(testCase, P);
    rows = D.coeffs(1);

    testCase.verifyEqual(D.SourceSummary, "derivative");
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifyTrue(D.ContainsDecision);
    testCase.verifyFalse(D.HasRateDependence);
    testCase.verifyEmpty(D.RateBounds);
    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(D.DerivativeSourceDegree, 1);
    testCase.verifyEqual(numel(rows), 1);
    verifyCoeffExpr(testCase, rows{1}, {0.5 * (cp{2} - cp{1})});
end

function testRateMetadataSuppressesWarning(testCase)
    % RateBounds remain metadata on the derivative-row object.
    rb = [-2 3];
    P = dpvar(1, {[0 1]}, RateBounds=rb);

    D = diffNoWarn(testCase, P);

    testCase.verifyTrue(D.HasRateDependence);
    testCase.verifyEqual(D.RateBounds, rb);
    testCase.verifyFalse(D.IsContinuous);
    testCase.verifyEqual(D.SourceSummary, "derivative");
end

function testNonuniformCellsStayLocal(testCase)
    % Each physical cell uses its own width and keeps its derivative row local.
    P = dpvar(1, {[0 1 3]});
    c1 = P.coeffs(1);
    c2 = P.coeffs(2);

    D = diffWithWarn(testCase, P);
    r1 = D.coeffs(1);
    r2 = D.coeffs(2);

    verifyCoeffExpr(testCase, r1{1}, {c1{2} - c1{1}});
    verifyCoeffExpr(testCase, r2{1}, {0.5 * (c2{2} - c2{1})});
    testCase.verifyNotEqual(getvariables(r1{1}{1}), getvariables(r2{1}{1}));
end

function testDegreeTwoScalarExpressionDiff(testCase)
    % A degree-2 scalar expression differentiates to a degree-1 row.
    P = dpvar(1, {[0 1]});
    A = dpmat({[0 1]}, {2, 4}, Degree=1);
    C = A * P;
    cc = C.coeffs(1);

    D = diffWithWarn(testCase, C);
    rows = D.coeffs(1);

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyEqual(D.Degree, 1);
    testCase.verifyEqual(D.DerivativeSourceDegree, 2);
    verifyCoeffExpr(testCase, rows{1}, { ...
        2 * (cc{2} - cc{1}), ...
        2 * (cc{3} - cc{2})});
end

function testTensorRowsUseMixedDegreeOrder(testCase)
    % Direction rows use mixed-degree labels in shared combination order.
    rb = [-1 1; -2 2];
    P = dpvar(1, {[0 1], [10 12]}, RateBounds=rb);
    cp = P.coeffs([1 1]);

    D = diffNoWarn(testCase, P);
    rows = D.coeffs([1 1]);

    testCase.verifyEqual(D.Degree, 0);
    testCase.verifyEqual(numel(rows), 2);
    testCase.verifyEqual(numel(rows{1}), 2);
    testCase.verifyEqual(numel(rows{2}), 2);
    verifyCoeffExpr(testCase, rows{1}, {cp{3} - cp{1}, cp{4} - cp{2}});
    verifyCoeffExpr(testCase, rows{2}, {0.5 * (cp{2} - cp{1}), 0.5 * (cp{4} - cp{3})});
end

function testDerivativeRowsRejectOrdinaryAlgebra(testCase)
    % Row contraction belongs to future assembly, so ordinary algebra rejects D.
    P = dpvar(1, {[0 1]});
    D = diffWithWarn(testCase, P);

    testCase.verifyError(@() D + P, "dpvar:InvalidAddition");
    testCase.verifyError(@() [D, D], "dpvar:InvalidConcatenation");
    testCase.verifyError(@() blkdiag(D, 1), "dpvar:InvalidBlkdiag");
    testCase.verifyError(@() 2 * D, "dpvar:InvalidMultiplication");
    testCase.verifyError(@() -D, "dpvar:UnsupportedDerivativeRows");
    testCase.verifyError(@() D(1, 1), "dpvar:UnsupportedDerivativeRows");
    testCase.verifyError(@() assignDeriv(D), "dpvar:InvalidAssignment");
    testCase.verifyError(@() diff(D), "dpvar:InvalidDiff");
end

function D = diffWithWarn(testCase, P)
    lastwarn("");
    D = diff(P);
    [~, id] = lastwarn();
    testCase.verifyEqual(string(id), "dpvar:NoRateDependence");
    lastwarn("");
end

function D = diffNoWarn(testCase, P)
    lastwarn("");
    D = diff(P);
    [~, id] = lastwarn();
    testCase.verifyEqual(string(id), "");
end

function assignDeriv(D)
    D(1, 1) = 0;
end

function verifyCoeffExpr(testCase, actual, expected)
    testCase.verifyEqual(numel(actual), numel(expected));
    for k = 1:numel(expected)
        delta = actual{k} - expected{k};
        if isa(delta, "sdpvar")
            base = full(getbase(delta));
            testCase.verifyEqual(base, zeros(size(base)), AbsTol=1e-10);
        else
            testCase.verifyEqual(delta, zeros(size(delta)), AbsTol=1e-10);
        end
    end
end
