function tests = test_bern_table
    % Behavioral regressions for pdvar.bern_table.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep symbolic display names local to this suite.
    yalmip("clear");
end

function test_pdvar_rows_share_pdmat_metadata_but(testCase)
    % pdvar rows share pdmat metadata but stringify symbolic coefficients.
    P = pdvar(1, {[0 1 2]});
    cp = P.coeffs(1);

    T = bernTable(P);

    testCase.verifyEqual(T.Properties.VariableNames, {'TermIndex', ...
        'CellSubscript', 'CoeffSubscript', 'LocalIndex', 'Basis', ...
        'IsPhysicalNode', 'Value'});
    testCase.verifyEqual(height(T), 4);
    testCase.verifyEqual(T.CellSubscript{1}, 1);
    testCase.verifyEqual(T.CellSubscript{3}, 2);
    testCase.verifyEqual(T.CoeffSubscript{2}, 2);
    testCase.verifyEqual(T.LocalIndex{2}, 1);
    testCase.verifyEqual(string(T.Basis(1)), "(1-α)");
    testCase.verifyEqual(string(T.Basis(2)), "α");
    testCase.verifyTrue(isstring(T.Value{1}));
    testCase.verifyEqual(T.Value{1}, sdpText(cp{1}));
    testCase.verifyEqual(T.Value{2}, sdpText(cp{2}));
end

function test_matrix_valued_sdpvar_rows_share_centered(testCase)
    % Matrix-valued sdpvar rows share one centered metadata row.
    P = pdvar(2, 2, {[0 1]}, "full");
    cp = P.coeffs(1);

    T = bernTable(P, 1);

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

function test_oneline_emit_complete_bernstein_expression_matrix(testCase)
    % oneLine should emit one complete Bernstein expression per matrix row.
    P = pdvar(2, 2, {[0 1]}, "full");
    cp = P.coeffs(1);

    T = bernTable(P, "oneLine");

    testCase.verifyEqual(height(T), 2);
    testCase.verifyEqual(strip(string(T.CellSubscript)), ...
        [""; "{[1]}"]);
    testCase.verifyEqual(string(T.Expression), [ ...
        "(1-α)*" + sdpText(cp{1}(1, :)) + ...
            " + α*" + sdpText(cp{2}(1, :)); ...
        "(1-α)*" + sdpText(cp{1}(2, :)) + ...
            " + α*" + sdpText(cp{2}(2, :))]);
end

function test_oneline_combine_bernstein_basis_text_sdisplay(testCase)
    % oneLine should combine Bernstein basis text with sdisplay output.
    P = pdvar(1, {[0 1]});
    cp = P.coeffs(1);

    T = bernTable(P, "oneLine");

    testCase.verifyEqual(T.Properties.VariableNames, ...
        {'CellSubscript', 'Expression'});
    testCase.verifyEqual(height(T), 1);
    testCase.verifyEqual(string(T.Expression(1)), ...
        "(1-α)*[" + sdpText(cp{1}) + "] + α*[" + sdpText(cp{2}) + "]");
end

function test_fixed_tensor_rate_table_retains_every_coefficient(testCase)
    % A one-row derivative must still expose its vertex on every physical cell.
    P = pdvar(1,{[0 2 5],[-3 1 6]},Degree=[1 2]);
    D = rhodiff(P,[3 3;-2 -2]);
    T = bernTable(D);
    cells = [1 1;1 2;2 1;2 2];
    labels = [0 0;0 1;0 2;1 0;1 1;1 2];
    testCase.verifyEqual(height(T),24);
    for cellIndex = 1:4
        c = D.coeffs(cells(cellIndex,:));
        for k = 1:6
            row = (cellIndex-1)*6+k;
            testCase.verifyEqual(T.CellSubscript{row},cells(cellIndex,:));
            testCase.verifyEqual(T.LocalIndex{row},labels(k,:));
            testCase.verifyEqual(T.RateVertexIndex(row),1);
            testCase.verifyEqual(T.RateVertex{row},[3 -2]);
            testCase.verifyEqual(T.Value{row},sdpText(c{k}));
        end
    end
end

function test_multi_cell_selectors_preserve_symbolic_and_rate_group_order(testCase)
    % Multi-cell selection preserves symbolic blocks and nested rate rows.
    P = pdvar(1, {[0 1 2], [10 20 30]}, Degree=[1 1]);
    detailed = bernTable(P, {2, 2; 1, 1; 2, 2; 1, 2});
    vals22 = P.coeffs([2 2]);
    vals11 = P.coeffs([1 1]);
    vals12 = P.coeffs([1 2]);

    testCase.verifyEqual(vertcat(detailed.CellSubscript{:}), ...
        repelem([2 2; 1 1; 1 2], 4, 1));
    testCase.verifyEqual(detailed.Value{1}, sdpText(vals22{1}));
    testCase.verifyEqual(detailed.Value{5}, sdpText(vals11{1}));
    testCase.verifyEqual(detailed.Value{9}, sdpText(vals12{1}));

    Q = pdvar(1, {[0 1 2 3]}, Degree=2);
    D = rhodiff(Q, [-1 2]);
    oneLine = bernTable(D, [3; 1; 3; 2], "oneLine");
    expectedCells = [3; 3; 1; 1; 2; 2];

    testCase.verifyEqual([oneLine.CellSubscript{:}]', expectedCells);
    testCase.verifyEqual(oneLine.RateVertexIndex, repmat([1; 2], 3, 1));
    for row = 1:height(oneLine)
        vals = D.coeffs(expectedCells(row));
        rate = oneLine.RateVertexIndex(row);
        expected = "(1-α)*[" + sdpText(vals{rate, 1}) + ...
            "] + α*[" + sdpText(vals{rate, 2}) + "]";
        testCase.verifyEqual(string(oneLine.Expression(row)), expected);
    end
end

function test_helper_text_bernstein_scales_degree_elevation(testCase)
    % Shared helper text should keep Bernstein scales after degree elevation.
    P = pdvar(1, {[0 1]});
    A = pdmat({[0 1]}, {10, 20, 30}, Degree=2);
    C = P + A;

    T = bernTable(C, "oneLine");

    testCase.verifyEqual(C.Degree, 2);
    testCase.verifyTrue(contains(string(T.Expression(1)), ...
        "2(1-α)α*"));
end

function test_rhodiff_leaves_store_coefficient_row_active(testCase)
    % rhodiff leaves store one coefficient row per active rho_dot vertex.
    P = pdvar(1, {[0 1]});
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);

    T = bernTable(D);

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

function test_oneline_rate_rows_separate_groups_composite(testCase)
    % oneLine keeps rate rows separate and groups composite coefficients.
    P = pdvar(1, {[0 1]}, Degree=3);
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);

    T = bernTable(D, "oneLine");

    testCase.verifyEqual(T.Properties.VariableNames, ...
        {'CellSubscript', 'RateVertexIndex', 'RateVertex', 'Expression'});
    testCase.verifyEqual(height(T), 2);
    testCase.verifyEqual(T.RateVertex{1}, -1);
    testCase.verifyEqual(T.RateVertex{2}, 2);
    expected = "(1-α)^2*[" + sdpText(cd{1, 1}) + "] + " + ...
        "2(1-α)α*[" + sdpText(cd{1, 2}) + "] + " + ...
        "α^2*[" + sdpText(cd{1, 3}) + "]";
    testCase.verifyEqual(string(T.Expression(1)), expected);
end

function test_matrix_expansion_inside_each_cell_rate(testCase)
    % Matrix expansion must remain inside each cell/rate/coefficient group.
    P = pdvar(2, 2, {[0 1]}, "full", Degree=2);
    D = rhodiff(P, [-1 2]);
    cd = D.coeffs(1);

    detailed = bernTable(D);

    testCase.verifyEqual(height(detailed), 8);
    testCase.verifyEqual(strip(string(detailed.TermIndex)), ...
        [""; "1"; ""; "2"; ""; "3"; ""; "4"]);
    testCase.verifyEqual(strip(string(detailed.RateVertexIndex)), ...
        [""; "1"; ""; "1"; ""; "2"; ""; "2"]);
    testCase.verifyEqual(detailed.Value{1}, sdpText(cd{1, 1}(1, :)));
    testCase.verifyEqual(detailed.Value{2}, sdpText(cd{1, 1}(2, :)));
    testCase.verifyEqual(detailed.Value{5}, sdpText(cd{2, 1}(1, :)));

    oneLine = bernTable(D, "oneLine");

    testCase.verifyEqual(height(oneLine), 4);
    testCase.verifyEqual(strip(string(oneLine.RateVertexIndex)), ...
        [""; "1"; ""; "2"]);
    firstRow = "(1-α)*" + sdpText(cd{1, 1}(1, :)) + ...
        " + α*" + sdpText(cd{1, 2}(1, :));
    secondRow = "(1-α)*" + sdpText(cd{1, 1}(2, :)) + ...
        " + α*" + sdpText(cd{1, 2}(2, :));
    testCase.verifyEqual(string(oneLine.Expression(1)), firstRow);
    testCase.verifyEqual(string(oneLine.Expression(2)), secondRow);
end

function test_option_validation_match_pdmat_berntable_surface(testCase)
    % Option validation should match the pdmat bernTable surface.
    P = pdvar(1, {[0 1]});

    testCase.verifyError(@() bernTable(P, "wide"), ...
        "pdvar:InvalidBernsteinTableInput");
    testCase.verifyError(@() bernTable(P, 1, 1), ...
        "pdvar:InvalidBernsteinTableInput");
    testCase.verifyError(@() bernTable(P, 2), ...
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

function test_all_cell_coefficients_and_variable_names(testCase)
    P=pdvar(1,[0 2 5],Degree=2);
    table=bernTable(P);
    basis=["(1-α)^2";"2(1-α)α";"α^2"];
    for cellIndex=1:2
        c=P.coeffs(cellIndex);
        for k=1:3
            row=(cellIndex-1)*3+k;
            testCase.verifyEqual(table.CellSubscript{row},cellIndex);
            testCase.verifyEqual(table.LocalIndex{row},k-1);
            testCase.verifyEqual(string(table.Basis(row)),basis(k));
            testCase.verifyEqual(table.Value{row},string(sdisplay(c{k})));
        end
    end
    testCase.verifyEqual(height(table),6);
end
