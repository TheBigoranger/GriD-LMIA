function tests = test_bern_table
    % Behavioral regressions for pdmat.bern_table.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Keep symbolic display names local to this suite.
    yalmip("clear");
end

function test_berntable_expose_cell_wise_bernstein_metadata(testCase)
    % bernTable(A) should expose cell-wise Bernstein metadata.
    A = pdmat({[0 1]}, {1, 2, 3}, Degree=2);

    T = bernTable(A);

    testCase.verifyEqual(T.Properties.VariableNames, {'TermIndex', ...
        'CellSubscript', 'CoeffSubscript', 'LocalIndex', 'Basis', ...
        'IsPhysicalNode', 'Value'});
    testCase.verifyEqual(height(T), 3);
    testCase.verifyEqual(T.CellSubscript{1}, 1);
    testCase.verifyEqual(T.CoeffSubscript{2}, 2);
    testCase.verifyEqual(T.LocalIndex{2}, 1);
    testCase.verifyEqual(string(T.Basis(1)), "(1-α)^2");
    testCase.verifyEqual(string(T.Basis(2)), "2(1-α)α");
    testCase.verifyEqual(string(T.Basis(3)), "α^2");
    testCase.verifyFalse(T.IsPhysicalNode(2));
    testCase.verifyEqual(T.Value{3}, 3);
end

function test_optional_cell_selector_narrow_output_hypercube(testCase)
    % The optional cell selector should narrow output to one hypercube.
    A = pdmat({[0 1 2]}, {1, 2, 3, 4, 5}, Degree=2);

    T = bernTable(A, 2);

    testCase.verifyEqual(height(T), 3);
    testCase.verifyEqual(T.CellSubscript{1}, 2);
    testCase.verifyEqual(T.CoeffSubscript{1}, 3);
    testCase.verifyEqual(T.CoeffSubscript{3}, 5);
    testCase.verifyEqual(T.Value{1}, 3);
    testCase.verifyEqual(T.Value{3}, 5);
end
function test_function_only_selectors_cannot_tabulate_placeholders(testCase)
    % A valid selector and display format do not establish Bernstein evidence.
    F = pdmat({[0 2 5], [-1 3]}, @(x,y) [sin(x+y), exp(y)]);
    calls = {@() bernTable(F,[2 1]), @() bernTable(F,[2 1;1 1],"oneLine"), ...
        @() bernTable(F,"oneLine")};
    for k = 1:numel(calls)
        testCase.verifyError(calls{k}, "pdmat:FunctionOnlyBernsteinTable");
    end
    testCase.verifyEqual(F.evaluate([.5 1]), [sin(1.5) exp(1)], AbsTol=1e-12);
end

function test_multi_cell_selectors_preserve_order_and_stably_deduplicate(testCase)
    % Numeric and cell-array selectors keep first-occurrence cell-block order.
    A = pdmat({[0 1 2 3]}, {10, 20, 30, 40}, Degree=1);

    detailed = bernTable(A, [3; 1; 3; 2]);
    oneLine = bernTable(A, [3; 1; 3; 2], "oneLine");

    testCase.verifyEqual([detailed.CellSubscript{:}]', ...
        [3; 3; 1; 1; 2; 2]);
    testCase.verifyEqual([detailed.Value{:}]', ...
        [30; 40; 10; 20; 20; 30]);
    testCase.verifyEqual([oneLine.CellSubscript{:}]', [3; 1; 2]);
    testCase.verifyEqual(string(oneLine.Expression), [ ...
        "(1-α)*30 + α*40"; ...
        "(1-α)*10 + α*20"; ...
        "(1-α)*20 + α*30"]);

    B = pdmat({[0 1 2], [10 20 30]}, ...
        reshape(num2cell(1:9), 3, 3), Degree=[1 1]);
    selected = bernTable(B, {2, 2; 1, 1; 2, 2; 1, 2});

    testCase.verifyEqual(vertcat(selected.CellSubscript{:}), ...
        repelem([2 2; 1 1; 1 2], 4, 1));
    testCase.verifyEqual([selected.Value{1}, selected.Value{5}, ...
        selected.Value{9}], [5, 1, 4]);
end

function test_oneline_bernstein_basis_multipliers_including_middle(testCase)
    % oneLine keeps the Bernstein basis multipliers, including middle terms.
    A = pdmat({[0 1]}, {[0 1], [1 2]}, Degree=1);
    B = pdmat({[0 1]}, {1, 2, 3}, Degree=2);
    Z = pdmat({[0 1]}, {5}, Degree=0);

    TA = bernTable(A, 1, "oneLine");
    TB = bernTable(B, "oneLine");
    TZ = bernTable(Z, "oneLine");

    testCase.verifyEqual(TA.Properties.VariableNames, ...
        {'CellSubscript', 'Expression'});
    testCase.verifyEqual(height(TA), 1);
    testCase.verifyEqual(string(TA.Expression(1)), ...
        "(1-α)*[0 1] + α*[1 2]");
    testCase.verifyEqual(string(TB.Expression(1)), ...
        "(1-α)^2*1 + 2(1-α)α*2 + α^2*3");
    testCase.verifyEqual(string(TZ.Expression(1)), "5");
end

function test_tensor_selectors_zero_degree_axes_complete(testCase)
    % Tensor selectors and zero-degree axes retain complete metadata.
    A = pdmat({[0 1 2], [10 20 30]}, reshape(num2cell(1:9), 3, 3), ...
        Degree=[1 1]);
    T = bernTable(A, {2, 2});

    testCase.verifyEqual(height(T), 4);
    testCase.verifyEqual(T.CellSubscript{1}, [2 2]);
    testCase.verifyEqual(T.CoeffSubscript{4}, [3 3]);

    matrixData = reshape(arrayfun(@(k) [k; -k], 1:9, ...
        "UniformOutput", false), 3, 3);
    M = pdmat({[0 1 2], [10 20 30]}, matrixData, Degree=[1 1]);
    V = bernTable(M, {2, 2});
    testCase.verifyTrue(any(contains(string(V.CellSubscript), "[2 2]")));

    B = pdmat({[0 1], [10 20]}, {1, 2}, Degree=[0 1]);
    U = bernTable(B);
    testCase.verifyEqual(string(U.Basis), ["1 * (1-α2)"; "1 * α2"]);
end

function test_matrix_values_expand_by_row_while(testCase)
    % Matrix values expand by row while metadata appears once per coefficient.
    A = pdmat({[0 1]}, ...
        {[1 2; 3 4], [5 6; 7 8]}, Degree=1);

    T = bernTable(A);

    testCase.verifyEqual(height(T), 4);
    testCase.verifyEqual(strip(string(T.TermIndex)), [""; "1"; ""; "2"]);
    testCase.verifyEqual(strip(string(T.CellSubscript)), ...
        [""; "{[1]}"; ""; "{[1]}"]);
    testCase.verifyEqual(strip(string(T.CoeffSubscript)), ...
        [""; "{[1]}"; ""; "{[2]}"]);
    testCase.verifyEqual(strip(string(T.LocalIndex)), ...
        [""; "{[0]}"; ""; "{[1]}"]);
    testCase.verifyEqual(strip(string(T.Basis)), ...
        [""; """(1-α)"""; ""; """α"""]);
    testCase.verifyEqual(strip(string(T.IsPhysicalNode)), ...
        [""; "true"; ""; "true"]);
    testCase.verifyEqual(T.Value, {[1 2]; [3 4]; [5 6]; [7 8]});
end

function test_odd_height_matrix_blocks_place_metadata(testCase)
    % Odd-height matrix blocks should place metadata on the true middle row.
    A = pdmat({[0 1]}, ...
        {[1 2; 3 4; 5 6], [7 8; 9 10; 11 12]}, Degree=1);

    detailed = bernTable(A);
    oneLine = bernTable(A, "oneLine");

    testCase.verifyEqual(strip(string(detailed.TermIndex)), ...
        [""; "1"; ""; ""; "2"; ""]);
    testCase.verifyEqual(strip(string(detailed.CellSubscript)), ...
        [""; "{[1]}"; ""; ""; "{[1]}"; ""]);
    testCase.verifyEqual(detailed.Value, ...
        {[1 2]; [3 4]; [5 6]; [7 8]; [9 10]; [11 12]});
    testCase.verifyEqual(strip(string(oneLine.CellSubscript)), ...
        [""; "{[1]}"; ""]);
end

function test_oneline_expand_matrix_rows_honor_active(testCase)
    % oneLine should expand matrix rows and honor the active MATLAB format.
    A = pdmat({[0 1]}, ...
        {[0.204908275128747 0.0320487219369788; ...
          0.0320487219369788 0.781999831414089], ...
         [0.170281985942478 -0.0736470291023216; ...
          -0.0736470291023216 0.571024555454962]}, Degree=1);
    originalFormat = format;
    testCase.addTeardown(@() restoreFormat(originalFormat));

    format short
    shortTable = bernTable(A, "oneLine");
    testCase.verifyEqual(height(shortTable), 2);
    testCase.verifyEqual(strip(string(shortTable.CellSubscript)), ...
        [""; "{[1]}"]);
    testCase.verifyEqual(string(shortTable.Expression), [ ...
        "(1-α)*[0.2049 0.0320] + α*[0.1703 -0.0736]"; ...
        "(1-α)*[0.0320 0.7820] + α*[-0.0736 0.5710]"]);

    format longG
    longTable = bernTable(A, "oneLine");
    testCase.verifyEqual(string(longTable.Expression(1)), ...
        "(1-α)*[0.204908275128747 0.0320487219369788] + " + ...
        "α*[0.170281985942478 -0.0736470291023216]");
end

function test_tensor_rows_follow_local_label_combination(testCase)
    % Tensor rows should follow the shared local-label combination order.
    A = pdmat({[0 1], [10 20]}, {1 2; 3 4}, Degree=[1 1]);
    F = pdmat({[0 1]}, @(rho) rho);

    T = bernTable(A);

    testCase.verifyEqual(height(T), 4);
    testCase.verifyEqual(T.CellSubscript{1}, [1 1]);
    testCase.verifyEqual(T.LocalIndex{1}, [0 0]);
    testCase.verifyEqual(T.CoeffSubscript{4}, [2 2]);
    testCase.verifyEqual(string(T.Basis(1)), ...
        "(1-α1) * (1-α2)");
    testCase.verifyEqual(string(T.Basis(4)), "α1 * α2");
    testCase.verifyEqual(T.Value{1}, 1);
    testCase.verifyEqual(T.Value{4}, 4);
    testCase.verifyError(@() bernTable(F), "pdmat:FunctionOnlyBernsteinTable");
    testCase.verifyError(@() bernTable(A, [2 1]), "pdbase:InvalidCellSubs");
    testCase.verifyError(@() bernTable(A, [1 1], [1 1]), ...
        "pdmat:InvalidBernsteinTableInput");
    testCase.verifyError(@() bernTable(A, "wide"), ...
        "pdmat:InvalidBernsteinTableInput");
    testCase.verifyError(@() bernTable(A, zeros(0, 2)), ...
        "pdbase:InvalidCellSubs");
    testCase.verifyError(@() bernTable(A, [1 1 1; 1 1 1]), ...
        "pdbase:InvalidCellSubs");
    testCase.verifyError(@() bernTable(A, {1, "bad"}), ...
        "pdbase:InvalidCellSubs");
    testCase.verifyError(@() bernTable(A, [1 1; 2 1]), ...
        "pdbase:InvalidCellSubs");
end

function restoreFormat(options)
    %RESTOREFORMAT Restore both numeric style and line spacing after a test.
    format(char(options.NumericFormat));
    format(char(options.LineSpacing));
end
function test_complete_tensor_rate_table(testCase)
    A=pdmat({[0 2 5],[-1 1 4]},@(x,y) y^2,Degree=[0 2],RateBounds=[3 3;-2 5]);
    D=rhodiff(A);
    T=bernTable(D);
    cells=[1 1;1 2;2 1;2 2]; rates=[3 -2;3 5];
    control={[-1 0 1],[1 2.5 4]};
    basis=["1 * (1-α2)^2";"1 * 2(1-α2)α2";"1 * α2^2"];
    index=0;
    for cellIndex=1:4
        for row=1:2
            for k=1:3
                index=index+1;
                testCase.verifyEqual(T.CellSubscript{index},cells(cellIndex,:));
                testCase.verifyEqual(T.LocalIndex{index},[0 k-1]);
                testCase.verifyEqual(T.RateVertex{index},rates(row,:));
                testCase.verifyEqual(T.Value{index},2*rates(row,2)*control{cells(cellIndex,2)}(k),AbsTol=1e-10);
                testCase.verifyEqual(string(T.Basis(index)),basis(k));
            end
        end
    end
    testCase.verifyEqual(height(T),index);
    selected=bernTable(D,[2 2]);
    testCase.verifyEqual(selected.Value,T.Value(19:24));
    one=bernTable(D,[2 2],'oneLine');
    testCase.verifyEqual(string(one.Expression),[ ...
        "1 * (1-α2)^2*-4 + 1 * 2(1-α2)α2*-10 + 1 * α2^2*-16"; ...
        "1 * (1-α2)^2*10 + 1 * 2(1-α2)α2*25 + 1 * α2^2*40"]);
end
