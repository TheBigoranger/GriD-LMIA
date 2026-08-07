function tests = test_elevate
    %TEST_ELEVATE Public Bernstein degree-elevation APIs.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep variable and assignment checks deterministic across test sessions.
    yalmip("clear");
end

function testPubEleScaExaAnd(testCase)
    % Public coefficient elevation changes the basis, not source evidence.
    vals = {{0, 1}, {2, 4}};
    obj = pdbase({[0 1 2]}, [1 1], 1, vals);
    before = obj.LocalValues;

    same = obj.elevate(0);
    once = obj.elevate(1);
    twice = obj.elevate(2);

    testCase.verifyClass(same, "pdbase");
    testCase.verifyEqual(same.LocalValues, vals);
    testCase.verifyEqual(once.LocalValues{1}, {0, 0.5, 1});
    testCase.verifyEqual(once.LocalValues{2}, {2, 3, 4});
    testCase.verifyEqual(twice.LocalValues{1}, ...
        {0, 1 / 3, 2 / 3, 1}, AbsTol=1e-14);
    testCase.verifyEqual(twice.LocalValues{2}, ...
        {2, 8 / 3, 10 / 3, 4}, AbsTol=1e-14);
    testCase.verifyEqual(obj.LocalValues, before);
    testCase.verifyEqual(obj.Degree, 1);
end

function testPubEleTenComRow(testCase)
    % Tensor elevation must retain the package-wide coefficient row order.
    vals = {{{0, 2, 4, 6}}};
    obj = pdbase({[0 1], [10 20]}, [1 1], 1, vals);

    out = obj.elevate(1);

    expected = {0, 1, 2, 2, 3, 4, 4, 5, 6};
    testCase.verifyEqual(out.LocalValues{1}{1}, expected);
    testCase.verifyEqual(size(out.LocalValues{1}{1}), [1 9]);
end

function testPubElePreRatRow(testCase)
    % Rate rows must be elevated without reordering or mixing.
    vals = {{0, 2; 10, 14}};
    obj = pdbase({[0 1]}, [1 1], 1, vals, ...
        RateBounds=[-1 1]);

    out = obj.elevate(1);

    testCase.verifyEqual(out.LocalValues{1}, {0, 1, 2; 10, 12, 14});
    testCase.verifyEqual(size(out.LocalValues{1}), [2 3]);
    testCase.verifyEqual(obj.LocalValues, vals);
    testCase.verifyEqual(obj.RateBounds, [-1 1]);
end

function testPubEleRejInvInc(testCase)
    % Invalid increments must fail before transforming the coefficient tree.
    obj = pdbase({[0 1]}, [1 1], 1, {{0, 1}});

    bad = {-1, 0.5, Inf, NaN, "one", [1 2]};
    for k = 1:numel(bad)
        testCase.verifyError(@() obj.elevate(bad{k}), ...
            "pdbase:InvalidDegreeIncrement");
    end
end

function testPubEleRejFunOnl(testCase)
    % Function-only pdmat placeholders are not coefficient evidence.
    obj = pdmat({[0 1]}, @(rho) 1 + rho);

    testCase.verifyError(@() obj.elevate(1), ...
        "pdbase:MissingCoefficientEvidence");
end

function testPubEleRejInvTra(testCase)
    % The call-local validation mode remains scalar text owned by pdbase.
    obj = pdbase({[0 1], [10 20]}, [1 1], [1 0], {{{1, 2}}});
    bad = {42, ["fast", "strict"], string(missing), '', "sample"};

    for k = 1:numel(bad)
        testCase.verifyError(@() obj.elevate([0 1], bad{k}), ...
            "pdbase:InvalidValidationMode");
    end
end

function testPdbZerAndPosInc(testCase)
    % A value-class copy changes basis while retaining the source object.
    vals = {{{0, 2, 4, 6}}};
    obj = pdbase({[0 1], [10 20]}, [1 1], 1, vals);

    same = obj.elevate(0);
    out = obj.elevate(1);

    testCase.verifyClass(same, "pdbase");
    testCase.verifyEqual(same.Degree, [1 1]);
    testCase.verifyEqual(same.LocalValues, vals);
    testCase.verifyClass(out, "pdbase");
    testCase.verifyEqual(out.Degree, [2 2]);
    pts = [0 10; 0.25 14; 1 20];
    for k = 1:size(pts, 1)
        testCase.verifyEqual(out.evaluate(pts(k, :)), ...
            obj.evaluate(pts(k, :)), AbsTol=1e-12);
    end
    testCase.verifyEqual(obj.Degree, [1 1]);
    testCase.verifyEqual(obj.LocalValues, vals);
end

function testPdmPreClaHanAnd(testCase)
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

function testPdvPreVarMetAnd(testCase)
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
    testCase.verifyEqual(Q.RateBounds, P.RateBounds);
    testCase.verifyEqual(Q.SourceSummary, P.SourceSummary);
    testCase.verifyEqual(objectVariables(Q), beforeVars);
    coeffs = P.coeffs(1);
    assignCoeffs(coeffs, {eye(2), 3 * eye(2)});
    testCase.verifyEqual(value(P.evaluate(0.7)), ...
        value(Q.evaluate(0.7)), AbsTol=1e-12);
    testCase.verifyEqual(P.Degree, 1);
end

function testDerRowEleInd(testCase)
    % Every physical-cell rate row is elevated without mixing its neighbors.
    P = pdvar(1, {[0 1], [10 12]}, Degree=[2 2]);
    lbls = P.lbls();
    vals = arrayfun(@(k) 1 + 2 * lbls(k, 1) + ...
        3 * lbls(k, 2) + 4 * prod(lbls(k, :)), ...
        1:size(lbls, 1), UniformOutput=false);
    assignCoeffs(P.coeffs([1 1]), vals);
    D = rhodiff(P, [-1 2; -3 5]);
    beforeVars = objectVariables(D);

    E = D.elevate([1 0]);

    testCase.verifyClass(E, "pdvar");
    testCase.verifyEqual(E.Degree, D.Degree + [1 0]);
    testCase.verifySize(E.coeffs([1 1]), [4 12]);
    testCase.verifyEqual(E.IsContinuous, D.IsContinuous);
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
    testCase.verifyEqual(D.Degree, [2 2]);
    testCase.verifySize(D.coeffs([1 1]), [4 9]);
end

function testRejInvIncAndMis(testCase)
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
