function tests = test_elevate
    %TEST_ELEVATE Object-preserving public Bernstein degree elevation.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep variable and assignment checks deterministic across test sessions.
    yalmip("clear");
end

function testPdbaseZeroAndPositiveIncrements(testCase)
    % A value-class copy changes basis while retaining the source object.
    vals = {{{0, 2, 4, 6}}};
    obj = pdbase({[0 1], [10 20]}, [1 1], 1, vals);

    same = obj.elevate(0);
    out = obj.elevate(1);

    testCase.verifyClass(same, "pdbase");
    testCase.verifyEqual(same.Degree, 1);
    testCase.verifyEqual(same.LocalValues, vals);
    testCase.verifyClass(out, "pdbase");
    testCase.verifyEqual(out.Degree, 2);
    pts = [0 10; 0.25 14; 1 20];
    for k = 1:size(pts, 1)
        testCase.verifyEqual(out.evaluate(pts(k, :)), ...
            obj.evaluate(pts(k, :)), AbsTol=1e-12);
    end
    testCase.verifyEqual(obj.Degree, 1);
    testCase.verifyEqual(obj.LocalValues, vals);
end

function testPdmatPreservesClassHandleAndExactValues(testCase)
    % Function-plus-degree data keeps its exact evaluator and metadata.
    A = pdmat({[-2 0.5 4]}, @(rho) rho.^2, Degree=2);

    B = A.elevate(2);

    testCase.verifyClass(B, "pdmat");
    testCase.verifyEqual(B.Degree, 4);
    testCase.verifyEqual(B.GridInfo, A.GridInfo);
    testCase.verifyEqual(B.MatrixSize, A.MatrixSize);
    testCase.verifyEqual(B.IsContinuous, A.IsContinuous);
    testCase.verifyEqual(B.SourceSummary, A.SourceSummary);
    testCase.verifyTrue(isequal(B.FunctionHandle, A.FunctionHandle));
    testCase.verifyEqual(B.evaluate(-0.75), A.evaluate(-0.75), AbsTol=1e-12);
    testCase.verifyEqual(B.evaluate(2.25), A.evaluate(2.25), AbsTol=1e-12);
    testCase.verifyEqual(A.Degree, 2);
end

function testPdvarPreservesVariablesMetadataAndValues(testCase)
    % Elevation reuses the same YALMIP decisions instead of enlarging the model.
    P = pdvar(2, {[0 2]}, "full", Degree=1, RateBounds=[-1 2]);
    beforeVars = objectVariables(P);

    Q = P.elevate(2);

    testCase.verifyClass(Q, "pdvar");
    testCase.verifyEqual(Q.Degree, 3);
    testCase.verifyEqual(Q.GridInfo, P.GridInfo);
    testCase.verifyEqual(Q.MatrixSize, P.MatrixSize);
    testCase.verifyEqual(Q.IsContinuous, P.IsContinuous);
    testCase.verifyEqual(Q.ContainsDecision, P.ContainsDecision);
    testCase.verifyEqual(Q.HasRateDependence, P.HasRateDependence);
    testCase.verifyEqual(Q.RateBounds, P.RateBounds);
    testCase.verifyEqual(Q.SourceSummary, P.SourceSummary);
    testCase.verifyEqual(objectVariables(Q), beforeVars);
    coeffs = P.coeffs(1);
    assignCoeffs(coeffs, {eye(2), 3 * eye(2)});
    testCase.verifyEqual(value(P.evaluate(0.7)), ...
        value(Q.evaluate(0.7)), AbsTol=1e-12);
    testCase.verifyEqual(P.Degree, 1);
end

function testDerivativeRowsElevateIndependently(testCase)
    % Every physical-cell rate row is elevated without mixing its neighbors.
    P = pdvar(1, {[0 1], [10 12]}, Degree=2);
    lbls = P.lbls();
    vals = arrayfun(@(k) 1 + 2 * lbls(k, 1) + ...
        3 * lbls(k, 2) + 4 * prod(lbls(k, :)), ...
        1:size(lbls, 1), UniformOutput=false);
    assignCoeffs(P.coeffs([1 1]), vals);
    D = rhodiff(P, [-1 2; -3 5]);
    beforeVars = objectVariables(D);

    E = D.elevate(1);

    testCase.verifyClass(E, "pdvar");
    testCase.verifyEqual(E.Degree, D.Degree + 1);
    testCase.verifySize(E.coeffs([1 1]), [4 16]);
    testCase.verifyEqual(E.IsContinuous, D.IsContinuous);
    testCase.verifyEqual(E.HasRateDependence, D.HasRateDependence);
    testCase.verifyEqual(E.RateBounds, D.RateBounds);
    testCase.verifyEqual(objectVariables(E), beforeVars);
    pts = [0.2 10.5; 0.8 11.5];
    for k = 1:size(pts, 1)
        before = D.evaluate(pts(k, :));
        after = E.evaluate(pts(k, :));
        for row = 1:numel(before)
            testCase.verifyEqual(value(after{row}), value(before{row}), ...
                AbsTol=1e-12);
        end
    end
    testCase.verifyEqual(D.Degree, 2);
    testCase.verifySize(D.coeffs([1 1]), [4 9]);
end

function testRejectsInvalidIncrementsAndMissingEvidence(testCase)
    % The object API must not bypass validation or evidence requirements.
    obj = pdbase({[0 1]}, [1 1], 1, {{0, 1}});
    testCase.verifyError(@() obj.elevate(-1), ...
        "pdbase:InvalidDegreeIncrement");

    fun = pdmat({[0 1]}, @(rho) 1 + rho);
    testCase.verifyError(@() fun.elevate(1), ...
        "pdbase:MissingCoefficientEvidence");
end

function vars = objectVariables(obj)
    % Collect the unique YALMIP identifiers from every cell and rate row.
    vars = [];
    cells = obj.cells();
    for k = 1:size(cells, 1)
        coeffs = obj.coeffs(cells(k, :));
        for j = 1:numel(coeffs)
            if isa(coeffs{j}, "sdpvar")
                vars = [vars, getvariables(coeffs{j})]; %#ok<AGROW>
            end
        end
    end
    vars = unique(vars);
end

function assignCoeffs(coeffs, vals)
    % Assign each source decision once; elevated coefficients reuse them.
    for k = 1:numel(coeffs)
        assign(coeffs{k}, vals{k});
    end
end
