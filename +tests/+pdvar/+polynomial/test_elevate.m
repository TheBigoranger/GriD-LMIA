function tests = test_elevate
    % Behavioral regressions for pdvar.elevate.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep variable and assignment checks deterministic across test sessions.
    yalmip("clear");
end

function test_elevation_reuses_same_yalmip_decisions_instead(testCase)
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

function test_physical_cell_rate_row_elevated_without(testCase)
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
function test_binomial_reference_all_rows(testCase)
    for rates = [false true]
        A = tests.infrastructure.fixture("pdvar", rates);
        saved = A.LocalValues;
        B = elevate(A, 2);
        for cellIndex = 1:2
            expected = tests.infrastructure.elevate(A.coeffs(cellIndex), A.Degree, A.Degree+2);
            tests.infrastructure.verify_expr(testCase, B.coeffs(cellIndex), expected);
        end
        testCase.verifyEqual(A.LocalValues, saved);
        testCase.verifyEqual(B.NumRateRows, A.NumRateRows);
        testCase.verifyEqual(B.RateBounds, A.RateBounds);
        testCase.verifyEqual(B.IsContinuous, A.IsContinuous);
    end
end

function test_tensor_incidence_preserves_decisions(testCase)
    % Check the complete affine row and original decision identities.
    source = pdvar(2, {[0 1], [10 20]}, "full", Degree=[1 1]);
    variables = objectVariables(source);
    actual = source.elevate(2);
    expected = tests.infrastructure.elevate(source.coeffs([1 1]), [1 1], [3 3]);
    verifyAffineRow(testCase, actual.coeffs([1 1]), expected);
    testCase.verifyEqual(objectVariables(actual), variables);
    % Exercise the reused map through multiple cells and derivative rate rows
    % with rectangular affine coefficients and unequal tensor degrees.
    source = pdvar(2, 3, {[0 .3 1], [-2 0 3]}, 'full', Degree=[1 2]);
    source = rhodiff(source, [-1 2; -3 4]);
    variables = objectVariables(source);
    for mode = ["fast", "strict"]
        actual = source.elevate([2 1], mode);
        for subs = source.cells()'
            expected = tests.infrastructure.elevate(source.coeffs(subs'), [1 2], [3 3]);
            verifyAffineRow(testCase, actual.coeffs(subs'), expected);
        end
        testCase.verifyEqual(objectVariables(actual), variables);
        testCase.verifyEqual(actual.RateBounds, source.RateBounds);
        testCase.verifyEqual(actual.NumRateRows, source.NumRateRows);
    end
end

function test_fixed_tensor_elevation_semigroup_and_invalid_increments(testCase)
    % Two anisotropic changes must match a direct independent binomial transform.
    P = pdvar(2,3,{[0 2 5],[-3 1 6]},'full',Degree=[0 2]);
    D = rhodiff(P,[3 3;-2 -2]);
    R = elevate(elevate(D,[1 0]),[0 2]);
    for subs = [1 1;1 2;2 1;2 2]'
        expected = tests.infrastructure.elevate(D.coeffs(subs'),[0 2],[1 4]);
        tests.infrastructure.verify_expr(testCase,R.coeffs(subs'),expected);
    end
    testCase.verifyEqual(R.NumRateRows,1);
    testCase.verifyEqual(R.Degree,[1 4]);
    testCase.verifyEqual(objectVariables(R),objectVariables(D));
    testCase.verifyError(@() elevate(D,[1 -1]),'pdbase:InvalidDegreeIncrement');
    testCase.verifyError(@() elevate(D,[1 0 2]),'pdbase:InvalidDegreeIncrement');
end

function verifyAffineRow(testCase, actual, expected)
    % Compare YALMIP variable identities and complete affine base matrices.
    testCase.verifyEqual(size(actual), size(expected));
    for coefficient = 1:numel(actual)
        testCase.verifyEqual(getvariables(actual{coefficient}), ...
            getvariables(expected{coefficient}));
        difference = actual{coefficient} - expected{coefficient};
        base = full(getbase(difference));
        testCase.verifyLessThanOrEqual(norm(base, "fro"), ...
            128 * eps(max(1, norm(full(getbase(expected{coefficient})), "fro"))));
    end
end
