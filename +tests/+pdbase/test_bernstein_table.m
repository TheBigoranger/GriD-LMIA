function tests = test_bernstein_table
    %TEST_BERNSTEIN_TABLE pdbase-owned table behavior for pdmat and pdvar.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep symbolic display names local to this suite.
    yalmip("clear");
end

function testPdmatListsBernsteinCoefficients(testCase)
    % bernsteinTable(A) should expose cell-local Bernstein metadata.
    A = pdmat({[0 1]}, {1, 2, 3}, Degree=2);

    T = bernsteinTable(A);

    testCase.verifyEqual(T.Properties.VariableNames, {'TermIndex', ...
        'CellSubscript', 'CoeffSubscript', 'LocalIndex', 'Basis', ...
        'IsPhysicalNode', 'Value'});
    testCase.verifyEqual(height(T), 3);
    testCase.verifyEqual(T.CellSubscript{1}, 1);
    testCase.verifyEqual(T.CoeffSubscript{2}, 2);
    testCase.verifyEqual(T.LocalIndex{2}, 1);
    testCase.verifyEqual(string(T.Basis(1)), "(1-alpha)^2");
    testCase.verifyEqual(string(T.Basis(2)), "2(1-alpha)alpha");
    testCase.verifyEqual(string(T.Basis(3)), "alpha^2");
    testCase.verifyFalse(T.IsPhysicalNode(2));
    testCase.verifyEqual(T.Value{3}, 3);
end

function testPdmatSelectsPhysicalCell(testCase)
    % The optional cell selector should narrow output to one hypercube.
    A = pdmat({[0 1 2]}, {1, 2, 3, 4, 5}, Degree=2);

    T = bernsteinTable(A, 2);

    testCase.verifyEqual(height(T), 3);
    testCase.verifyEqual(T.CellSubscript{1}, 2);
    testCase.verifyEqual(T.CoeffSubscript{1}, 3);
    testCase.verifyEqual(T.CoeffSubscript{3}, 5);
    testCase.verifyEqual(T.Value{1}, 3);
    testCase.verifyEqual(T.Value{3}, 5);
end

function testPdmatOneLineModeIncludesBernsteinScales(testCase)
    % oneLine keeps the Bernstein basis multipliers, including middle terms.
    A = pdmat({[0 1]}, {[0 1], [1 2]}, Degree=1);
    B = pdmat({[0 1]}, {1, 2, 3}, Degree=2);

    TA = bernsteinTable(A, 1, "oneLine");
    TB = bernsteinTable(B, "oneLine");

    testCase.verifyEqual(TA.Properties.VariableNames, ...
        {'CellSubscript', 'Expression'});
    testCase.verifyEqual(height(TA), 1);
    testCase.verifyEqual(string(TA.Expression(1)), ...
        "(1-alpha)*[0 1] + alpha*[1 2]");
    testCase.verifyEqual(string(TB.Expression(1)), ...
        "(1-alpha)^2*1 + 2(1-alpha)alpha*2 + alpha^2*3");
end

function testPdmatMatrixRowsRemainVisibleInDetailedTable(testCase)
    % Matrix values expand by row while metadata appears once per coefficient.
    A = pdmat({[0 1]}, ...
        {[1 2; 3 4], [5 6; 7 8]}, Degree=1);

    T = bernsteinTable(A);

    testCase.verifyEqual(height(T), 4);
    testCase.verifyEqual(strip(string(T.TermIndex)), [""; "1"; ""; "2"]);
    testCase.verifyEqual(strip(string(T.CellSubscript)), ...
        [""; "{[1]}"; ""; "{[1]}"]);
    testCase.verifyEqual(strip(string(T.CoeffSubscript)), ...
        [""; "{[1]}"; ""; "{[2]}"]);
    testCase.verifyEqual(strip(string(T.LocalIndex)), ...
        [""; "{[0]}"; ""; "{[1]}"]);
    testCase.verifyEqual(strip(string(T.Basis)), ...
        [""; """(1-alpha)"""; ""; """alpha"""]);
    testCase.verifyEqual(strip(string(T.IsPhysicalNode)), ...
        [""; "true"; ""; "true"]);
    testCase.verifyEqual(T.Value, {[1 2]; [3 4]; [5 6]; [7 8]});
end

function testOddHeightMatrixCentersMetadata(testCase)
    % Odd-height matrix blocks should place metadata on the true middle row.
    A = pdmat({[0 1]}, ...
        {[1 2; 3 4; 5 6], [7 8; 9 10; 11 12]}, Degree=1);

    detailed = bernsteinTable(A);
    oneLine = bernsteinTable(A, "oneLine");

    testCase.verifyEqual(strip(string(detailed.TermIndex)), ...
        [""; "1"; ""; ""; "2"; ""]);
    testCase.verifyEqual(strip(string(detailed.CellSubscript)), ...
        [""; "{[1]}"; ""; ""; "{[1]}"; ""]);
    testCase.verifyEqual(detailed.Value, ...
        {[1 2]; [3 4]; [5 6]; [7 8]; [9 10]; [11 12]});
    testCase.verifyEqual(strip(string(oneLine.CellSubscript)), ...
        [""; "{[1]}"; ""]);
end

function testPdmatMatrixOneLineUsesActiveNumericFormat(testCase)
    % oneLine should expand matrix rows and honor the active MATLAB format.
    A = pdmat({[0 1]}, ...
        {[0.204908275128747 0.0320487219369788; ...
          0.0320487219369788 0.781999831414089], ...
         [0.170281985942478 -0.0736470291023216; ...
          -0.0736470291023216 0.571024555454962]}, Degree=1);
    originalFormat = format;
    testCase.addTeardown(@() restoreFormat(originalFormat));

    format short
    shortTable = bernsteinTable(A, "oneLine");
    testCase.verifyEqual(height(shortTable), 2);
    testCase.verifyEqual(strip(string(shortTable.CellSubscript)), ...
        [""; "{[1]}"]);
    testCase.verifyEqual(string(shortTable.Expression), [ ...
        "(1-alpha)*[0.2049 0.0320] + alpha*[0.1703 -0.0736]"; ...
        "(1-alpha)*[0.0320 0.7820] + alpha*[-0.0736 0.5710]"]);

    format longG
    longTable = bernsteinTable(A, "oneLine");
    testCase.verifyEqual(string(longTable.Expression(1)), ...
        "(1-alpha)*[0.204908275128747 0.0320487219369788] + " + ...
        "alpha*[0.170281985942478 -0.0736470291023216]");
end

function testPdmatTensorGridOrderingAndInvalidInputs(testCase)
    % Tensor rows should follow the shared local-label combination order.
    A = pdmat({[0 1], [10 20]}, {1 2; 3 4}, Degree=1);
    F = pdmat({[0 1]}, @(rho) rho);

    T = bernsteinTable(A);

    testCase.verifyEqual(height(T), 4);
    testCase.verifyEqual(T.CellSubscript{1}, [1 1]);
    testCase.verifyEqual(T.LocalIndex{1}, [0 0]);
    testCase.verifyEqual(T.CoeffSubscript{4}, [2 2]);
    testCase.verifyEqual(string(T.Basis(1)), ...
        "(1-alpha1) * (1-alpha2)");
    testCase.verifyEqual(string(T.Basis(4)), "alpha1 * alpha2");
    testCase.verifyEqual(T.Value{1}, 1);
    testCase.verifyEqual(T.Value{4}, 4);
    testCase.verifyError(@() bernsteinTable(F), "pdmat:FunctionOnlyBernsteinTable");
    testCase.verifyError(@() bernsteinTable(A, [2 1]), "pdbase:InvalidCellSubs");
    testCase.verifyError(@() bernsteinTable(A, [1 1], [1 1]), ...
        "pdmat:InvalidBernsteinTableInput");
    testCase.verifyError(@() bernsteinTable(A, "wide"), ...
        "pdmat:InvalidBernsteinTableInput");
end

function testPdvarOrdinaryTableUsesSdisplayStrings(testCase)
    % pdvar rows share pdmat metadata but stringify symbolic coefficients.
    P = pdvar(1, {[0 1 2]});
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
    testCase.verifyEqual(string(T.Basis(1)), "(1-alpha)");
    testCase.verifyEqual(string(T.Basis(2)), "alpha");
    testCase.verifyTrue(isstring(T.Value{1}));
    testCase.verifyEqual(T.Value{1}, sdpText(cp{1}));
    testCase.verifyEqual(T.Value{2}, sdpText(cp{2}));
end

function testPdvarMatrixCoefficientDisplayIsCompact(testCase)
    % Matrix-valued sdpvar rows share one centered metadata row.
    P = pdvar(2, 2, {[0 1]}, "full");
    cp = P.coeffs(1);

    T = bernsteinTable(P, 1);

    testCase.verifyEqual(height(T), 4);
    testCase.verifyEqual(strip(string(T.TermIndex)), [""; "1"; ""; "2"]);
    testCase.verifyEqual(strip(string(T.CellSubscript)), ...
        [""; "{[1]}"; ""; "{[1]}"]);
    testCase.verifyTrue(isstring(T.Value{1}));
    testCase.verifyTrue(isscalar(T.Value{1}));
    testCase.verifyEqual(T.Value{1}, sdpText(cp{1}(1, :)));
    testCase.verifyEqual(T.Value{2}, sdpText(cp{1}(2, :)));
    testCase.verifyEqual(T.Value{3}, sdpText(cp{2}(1, :)));
    testCase.verifyEqual(T.Value{4}, sdpText(cp{2}(2, :)));
end

function testPdvarMatrixOneLineExpandsRows(testCase)
    % oneLine should emit one complete Bernstein expression per matrix row.
    P = pdvar(2, 2, {[0 1]}, "full");
    cp = P.coeffs(1);

    T = bernsteinTable(P, "oneLine");

    testCase.verifyEqual(height(T), 2);
    testCase.verifyEqual(strip(string(T.CellSubscript)), ...
        [""; "{[1]}"]);
    testCase.verifyEqual(string(T.Expression), [ ...
        "(1-alpha)*" + sdpText(cp{1}(1, :)) + ...
            " + alpha*" + sdpText(cp{2}(1, :)); ...
        "(1-alpha)*" + sdpText(cp{1}(2, :)) + ...
            " + alpha*" + sdpText(cp{2}(2, :))]);
end

function testPdvarOneLineModeIncludesSymbolicBernsteinTerms(testCase)
    % oneLine should combine Bernstein basis text with sdisplay output.
    P = pdvar(1, {[0 1]});
    cp = P.coeffs(1);

    T = bernsteinTable(P, "oneLine");

    testCase.verifyEqual(T.Properties.VariableNames, ...
        {'CellSubscript', 'Expression'});
    testCase.verifyEqual(height(T), 1);
    testCase.verifyEqual(string(T.Expression(1)), ...
        "(1-alpha)*[" + sdpText(cp{1}) + "] + alpha*[" + sdpText(cp{2}) + "]");
end

function testPdvarOneLineModeIncludesDegreeTwoScale(testCase)
    % Shared helper text should keep Bernstein scales after degree elevation.
    P = pdvar(1, {[0 1]});
    A = pdmat({[0 1]}, {10, 20, 30}, Degree=2);
    C = P + A;

    T = bernsteinTable(C, "oneLine");

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyTrue(contains(string(T.Expression(1)), ...
        "2(1-alpha)alpha*"));
end

function testPdvarDerivativeTableAddsRateVertexColumns(testCase)
    % rhodiff leaves store one coefficient row per active rho_dot vertex.
    P = pdvar(1, {[0 1]});
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

function testPdvarDerivativeOneLineAddsRateVertexColumns(testCase)
    % oneLine keeps rate rows separate and groups composite coefficients.
    P = pdvar(1, {[0 1]}, Degree=3);
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);

    T = bernsteinTable(D, "oneLine");

    testCase.verifyEqual(T.Properties.VariableNames, ...
        {'CellSubscript', 'RateVertexIndex', 'RateVertex', 'Expression'});
    testCase.verifyEqual(height(T), 2);
    testCase.verifyEqual(T.RateVertex{1}, -1);
    testCase.verifyEqual(T.RateVertex{2}, 2);
    expected = "(1-alpha)^2*[" + sdpText(cd{1, 1}) + "] + " + ...
        "2(1-alpha)alpha*[" + sdpText(cd{1, 2}) + "] + " + ...
        "alpha^2*[" + sdpText(cd{1, 3}) + "]";
    testCase.verifyEqual(string(T.Expression(1)), expected);
end

function testPdvarDerivativeMatrixRowsPreserveRateOrder(testCase)
    % Matrix expansion must remain inside each cell/rate/coefficient group.
    P = pdvar(2, 2, {[0 1]}, "full", Degree=2);
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);

    detailed = bernsteinTable(D);

    testCase.verifyEqual(height(detailed), 8);
    testCase.verifyEqual(strip(string(detailed.TermIndex)), ...
        [""; "1"; ""; "2"; ""; "3"; ""; "4"]);
    testCase.verifyEqual(strip(string(detailed.RateVertexIndex)), ...
        [""; "1"; ""; "1"; ""; "2"; ""; "2"]);
    testCase.verifyEqual(detailed.Value{1}, sdpText(cd{1, 1}(1, :)));
    testCase.verifyEqual(detailed.Value{2}, sdpText(cd{1, 1}(2, :)));
    testCase.verifyEqual(detailed.Value{5}, sdpText(cd{2, 1}(1, :)));

    oneLine = bernsteinTable(D, "oneLine");

    testCase.verifyEqual(height(oneLine), 4);
    testCase.verifyEqual(strip(string(oneLine.RateVertexIndex)), ...
        [""; "1"; ""; "2"]);
    firstRow = "(1-alpha)*" + sdpText(cd{1, 1}(1, :)) + ...
        " + alpha*" + sdpText(cd{1, 2}(1, :));
    secondRow = "(1-alpha)*" + sdpText(cd{1, 1}(2, :)) + ...
        " + alpha*" + sdpText(cd{1, 2}(2, :));
    testCase.verifyEqual(string(oneLine.Expression(1)), firstRow);
    testCase.verifyEqual(string(oneLine.Expression(2)), secondRow);
end

function testPdvarInvalidInputsFailClearly(testCase)
    % Option validation should match the pdmat bernsteinTable surface.
    P = pdvar(1, {[0 1]});

    testCase.verifyError(@() bernsteinTable(P, "wide"), ...
        "pdvar:InvalidBernsteinTableInput");
    testCase.verifyError(@() bernsteinTable(P, 1, 1), ...
        "pdvar:InvalidBernsteinTableInput");
    testCase.verifyError(@() bernsteinTable(P, 2), ...
        "pdbase:InvalidCellSubs");
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

function restoreFormat(options)
    %RESTOREFORMAT Restore both numeric style and line spacing after a test.
    format(char(options.NumericFormat));
    format(char(options.LineSpacing));
end
