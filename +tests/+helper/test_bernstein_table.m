function tests = test_bernstein_table
    %TEST_BERNSTEIN_TABLE Shared Bernstein table behavior for dpmat and dpvar.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep symbolic display names local to this suite.
    yalmip("clear");
end

function testDpmatListsBernsteinCoefficients(testCase)
    % bernsteinTable(A) should expose cell-local Bernstein metadata.
    A = dpmat({[0 1]}, {1, 2, 3}, Degree=2);

    T = bernsteinTable(A);

    testCase.verifyEqual(T.Properties.VariableNames, {'TermIndex', ...
        'CellSubscript', 'CoeffSubscript', 'LocalIndex', 'Basis', ...
        'IsPhysicalNode', 'Value'});
    testCase.verifyEqual(height(T), 3);
    testCase.verifyEqual(T.CellSubscript{1}, 1);
    testCase.verifyEqual(T.CoeffSubscript{2}, 2);
    testCase.verifyEqual(T.LocalIndex{2}, 1);
    testCase.verifyEqual(string(T.Basis(2)), "2a(1-a)");
    testCase.verifyFalse(T.IsPhysicalNode(2));
    testCase.verifyEqual(T.Value{3}, 3);
end

function testDpmatSelectsPhysicalCell(testCase)
    % The optional cell selector should narrow output to one hypercube.
    A = dpmat({[0 1 2]}, {1, 2, 3, 4, 5}, Degree=2);

    T = bernsteinTable(A, 2);

    testCase.verifyEqual(height(T), 3);
    testCase.verifyEqual(T.CellSubscript{1}, 2);
    testCase.verifyEqual(T.CoeffSubscript{1}, 3);
    testCase.verifyEqual(T.CoeffSubscript{3}, 5);
    testCase.verifyEqual(T.Value{1}, 3);
    testCase.verifyEqual(T.Value{3}, 5);
end

function testDpmatOneLineModeIncludesBernsteinScales(testCase)
    % oneLine keeps the Bernstein basis multipliers, including middle terms.
    A = dpmat({[0 1]}, {[0 1], [1 2]}, Degree=1);
    B = dpmat({[0 1]}, {1, 2, 3}, Degree=2);

    TA = bernsteinTable(A, 1, "oneLine");
    TB = bernsteinTable(B, "oneLine");

    testCase.verifyEqual(TA.Properties.VariableNames, ...
        {'CellSubscript', 'Expression'});
    testCase.verifyEqual(height(TA), 1);
    testCase.verifyEqual(string(TA.Expression(1)), ...
        "a*[0 1] + (1-a)*[1 2]");
    testCase.verifyEqual(string(TB.Expression(1)), ...
        "a^2*1 + 2a(1-a)*2 + (1-a)^2*3");
end

function testDpmatTensorGridOrderingAndInvalidInputs(testCase)
    % Tensor rows should follow the shared local-label combination order.
    A = dpmat({[0 1], [10 20]}, {1 2; 3 4}, Degree=1);
    F = dpmat({[0 1]}, @(rho) rho);

    T = bernsteinTable(A);

    testCase.verifyEqual(height(T), 4);
    testCase.verifyEqual(T.CellSubscript{1}, [1 1]);
    testCase.verifyEqual(T.LocalIndex{1}, [0 0]);
    testCase.verifyEqual(T.CoeffSubscript{4}, [2 2]);
    testCase.verifyEqual(string(T.Basis(4)), "(1-a1) * (1-a2)");
    testCase.verifyEqual(T.Value{1}, 1);
    testCase.verifyEqual(T.Value{4}, 4);
    testCase.verifyError(@() bernsteinTable(F), "dpmat:FunctionOnlyBernsteinTable");
    testCase.verifyError(@() bernsteinTable(A, [2 1]), "dpbase:InvalidCellSubs");
    testCase.verifyError(@() bernsteinTable(A, [1 1], [1 1]), ...
        "dpmat:InvalidBernsteinTableInput");
    testCase.verifyError(@() bernsteinTable(A, "wide"), ...
        "dpmat:InvalidBernsteinTableInput");
end

function testDpvarOrdinaryTableUsesSdisplayStrings(testCase)
    % dpvar rows share dpmat metadata but stringify symbolic coefficients.
    P = dpvar(1, {[0 1 2]});
    cp = P.coeffs(1);

    T = bernsteinTable(P);

    testCase.verifyEqual(T.Properties.VariableNames, {'TermIndex', ...
        'CellSubscript', 'CoeffSubscript', 'LocalIndex', 'Basis', ...
        'IsPhysicalNode', 'Value'});
    testCase.verifyEqual(height(T), 4);
    testCase.verifyEqual(T.CellSubscript{1}, 1);
    testCase.verifyEqual(T.CellSubscript{3}, 2);
    testCase.verifyEqual(T.CoeffSubscript{2}, 2);
    testCase.verifyEqual(T.LocalIndex{2}, 1);
    testCase.verifyEqual(string(T.Basis(1)), "a");
    testCase.verifyTrue(isstring(T.Value{1}));
    testCase.verifyEqual(T.Value{1}, sdpText(cp{1}));
    testCase.verifyEqual(T.Value{2}, sdpText(cp{2}));
end

function testDpvarMatrixCoefficientDisplayIsCompact(testCase)
    % Matrix-valued sdpvar coefficients should still occupy one table cell.
    P = dpvar(2, 1, {[0 1]}, "full");
    cp = P.coeffs(1);

    T = bernsteinTable(P, 1);

    testCase.verifyEqual(height(T), 2);
    testCase.verifyTrue(isstring(T.Value{1}));
    testCase.verifyTrue(isscalar(T.Value{1}));
    testCase.verifyEqual(T.Value{1}, sdpText(cp{1}));
end

function testDpvarOneLineModeIncludesSymbolicBernsteinTerms(testCase)
    % oneLine should combine Bernstein basis text with sdisplay output.
    P = dpvar(1, {[0 1]});
    cp = P.coeffs(1);

    T = bernsteinTable(P, "oneLine");

    testCase.verifyEqual(T.Properties.VariableNames, ...
        {'CellSubscript', 'Expression'});
    testCase.verifyEqual(height(T), 1);
    testCase.verifyEqual(string(T.Expression(1)), ...
        "a*" + sdpText(cp{1}) + " + (1-a)*" + sdpText(cp{2}));
end

function testDpvarOneLineModeIncludesDegreeTwoScale(testCase)
    % Shared helper text should keep Bernstein scales after degree elevation.
    P = dpvar(1, {[0 1]});
    A = dpmat({[0 1]}, {10, 20, 30}, Degree=2);
    C = P + A;

    T = bernsteinTable(C, "oneLine");

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyTrue(contains(string(T.Expression(1)), "2a(1-a)*"));
end

function testDpvarDerivativeTableAddsRateVertexColumns(testCase)
    % rhodiff leaves store one coefficient row per active rho_dot vertex.
    P = dpvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);

    T = bernsteinTable(D);

    testCase.verifyEqual(T.Properties.VariableNames, {'TermIndex', ...
        'CellSubscript', 'RateVertexIndex', 'RateVertex', ...
        'CoeffSubscript', 'LocalIndex', 'Basis', 'IsPhysicalNode', 'Value'});
    testCase.verifyEqual(height(T), 2);
    testCase.verifyEqual(T.RateVertexIndex, [1; 2]);
    testCase.verifyEqual(T.RateVertex{1}, -1);
    testCase.verifyEqual(T.RateVertex{2}, 2);
    testCase.verifyEqual(string(T.Basis(1)), "1");
    testCase.verifyEqual(T.Value{1}, sdpText(cd{1, 1}));
    testCase.verifyEqual(T.Value{2}, sdpText(cd{2, 1}));
end

function testDpvarDerivativeOneLineAddsRateVertexColumns(testCase)
    % oneLine keeps a separate expression for each rate vertex row.
    P = dpvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);

    T = bernsteinTable(D, "oneLine");

    testCase.verifyEqual(T.Properties.VariableNames, ...
        {'CellSubscript', 'RateVertexIndex', 'RateVertex', 'Expression'});
    testCase.verifyEqual(height(T), 2);
    testCase.verifyEqual(T.RateVertex{1}, -1);
    testCase.verifyEqual(T.RateVertex{2}, 2);
end

function testDpvarInvalidInputsFailClearly(testCase)
    % Option validation should match the dpmat bernsteinTable surface.
    P = dpvar(1, {[0 1]});

    testCase.verifyError(@() bernsteinTable(P, "wide"), ...
        "dpvar:InvalidBernsteinTableInput");
    testCase.verifyError(@() bernsteinTable(P, 1, 1), ...
        "dpvar:InvalidBernsteinTableInput");
    testCase.verifyError(@() bernsteinTable(P, 2), ...
        "dpbase:InvalidCellSubs");
end

function txt = sdpText(val)
    if isscalar(val)
        txt = scalarText(val);
        return
    end

    rows = strings(size(val, 1), 1);
    for r = 1:size(val, 1)
        cols = strings(1, size(val, 2));
        for c = 1:size(val, 2)
            cols(c) = scalarText(val(r, c));
        end
        rows(r) = strjoin(cols, ", ");
    end
    txt = "[" + strjoin(rows, "; ") + "]";
end

function txt = scalarText(expr)
    txt = string(sdisplay(expr));
    vars = depends(expr);
    if numel(vars) == 1 && txt == "expr"
        txt = "internal(" + string(vars) + ")";
    end
end
