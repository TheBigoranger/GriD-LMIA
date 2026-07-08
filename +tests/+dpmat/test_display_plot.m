function tests = test_display_plot
    %TEST_DISPLAY_PLOT dpmat command-window display and plotting.
    tests = functiontests(localfunctions);
end

function testDispAndDisplayText(testCase)
    % disp should stay compact while display prints useful metadata.
    A = dpmat({[0 1]}, {1, 2}, Degree=1);

    short = evalc("disp(A)");
    detail = evalc("display(A)");

    testCase.verifyTrue(contains(short, "dpmat [1 1] over 1-D grid"));
    testCase.verifyTrue(contains(short, "source coefficient-backed"));
    testCase.verifyTrue(contains(detail, "A ="));
    testCase.verifyTrue(contains(detail, "dpmat with 1-by-1 matrix values"));
    testCase.verifyTrue(contains(detail, "rho_1: [0, 1], 2 nodes"));
    testCase.verifyTrue(contains(detail, "Coefficients per cell: 2"));
end

function testTableListsBernsteinCoefficients(testCase)
    % table(A) should expose cell-local Bernstein metadata for the console.
    A = dpmat({[0 1]}, {1, 2, 3}, Degree=2);

    T = table(A);

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

function testTableTensorGridOrderingAndFunctionOnlyRejection(testCase)
    % Tensor rows should follow the shared local-label combination order.
    A = dpmat({[0 1], [10 20]}, {1 2; 3 4}, Degree=1);
    F = dpmat({[0 1]}, @(rho) rho);

    T = table(A);

    testCase.verifyEqual(height(T), 4);
    testCase.verifyEqual(T.CellSubscript{1}, [1 1]);
    testCase.verifyEqual(T.LocalIndex{1}, [0 0]);
    testCase.verifyEqual(T.CoeffSubscript{4}, [2 2]);
    testCase.verifyEqual(string(T.Basis(4)), "(1-a1) * (1-a2)");
    testCase.verifyEqual(T.Value{1}, 1);
    testCase.verifyEqual(T.Value{4}, 4);
    testCase.verifyError(@() table(F), "dpmat:FunctionOnlyTable");
end

function testPlotOneDimensionalFunctionBacked(testCase)
    % 1-D plotting should sample through evaluate and label each matrix entry.
    fig = figure("Visible", "off");
    cleaner = onCleanup(@() close(fig));
    A = dpmat({[0 1]}, @(rho) [rho, rho^2]);

    h = plot(A, SamplesPerCell=4, LineWidth=2);
    lgd = findobj(fig, "Type", "legend");
    ax = gca;
    colors = lines(2);

    testCase.verifyEqual(numel(h), 2);
    testCase.verifyEqual(numel(h(1).XData), 5);
    testCase.verifyEqual(h(1).YData, [0 0.25 0.5 0.75 1], AbsTol=1e-12);
    testCase.verifyEqual(h(2).YData, [0 0.0625 0.25 0.5625 1], AbsTol=1e-12);
    testCase.verifyEqual(h(1).Color, colors(1, :), AbsTol=1e-12);
    testCase.verifyEqual(h(2).Color, colors(2, :), AbsTol=1e-12);
    testCase.verifyEqual(h(1).LineWidth, 2);
    testCase.verifyEqual(string(lgd.Location), "northeast");
    testCase.verifyEqual(string(lgd.Interpreter), "latex");
    testCase.verifyEqual(string(lgd.String{1}), "$A_{1,1}$");
    testCase.verifyEqual(string(ax.XLabel.Interpreter), "latex");
    testCase.verifyEqual(string(ax.XLabel.String), "$\rho_{1}$");
    clear cleaner
end

function testPlotTwoDimensionalSurfaceDefaults(testCase)
    % 2-D plotting should create one transparent surface per matrix entry.
    fig = figure("Visible", "off");
    cleaner = onCleanup(@() close(fig));
    A = dpmat({[0 1], [10 20]}, @(rho, eta) [rho + eta, rho - eta]);

    h = plot(A, [1 2], SamplesPerCell=2, EdgeColor="none");
    lgd = findobj(fig, "Type", "legend");
    ax = gca;
    colors = lines(2);

    testCase.verifyEqual(numel(h), 2);
    testCase.verifyEqual(size(h(1).XData), [3 3]);
    testCase.verifyEqual(h(1).FaceAlpha, 0.5);
    testCase.verifyEqual(h(1).FaceColor, colors(1, :), AbsTol=1e-12);
    testCase.verifyEqual(h(2).FaceColor, colors(2, :), AbsTol=1e-12);
    testCase.verifyEqual(string(h(1).EdgeColor), "none");
    testCase.verifyEqual(h(1).ZData(1, 1), 10, AbsTol=1e-12);
    testCase.verifyEqual(h(1).ZData(end, end), 21, AbsTol=1e-12);
    testCase.verifyEqual(string(lgd.Interpreter), "latex");
    testCase.verifyEqual(string(lgd.String{2}), "$A_{1,2}$");
    testCase.verifyEqual(string(ax.XLabel.Interpreter), "latex");
    testCase.verifyEqual(string(ax.YLabel.Interpreter), "latex");
    testCase.verifyEqual(string(ax.XLabel.String), "$\rho_{1}$");
    testCase.verifyEqual(string(ax.YLabel.String), "$\rho_{2}$");
    clear cleaner
end

function testPlotHigherDimensionalSlices(testCase)
    % Higher-dimensional objects should fix unselected dimensions at lower bounds.
    fig = figure("Visible", "off");
    cleaner = onCleanup(@() close(fig));
    A = dpmat({[0 1], [10 20], [100 200]}, ...
        @(rho, eta, gam) rho + eta + gam);

    h = plot(A, 3, SamplesPerCell=2);

    testCase.verifyEqual(numel(h), 1);
    testCase.verifyEqual(h.XData, [100 150 200], AbsTol=1e-12);
    testCase.verifyEqual(h.YData, [110 160 210], AbsTol=1e-12);
    clear cleaner
end

function testPlotOptionValidation(testCase)
    % Invalid plot dimensions and sample counts should fail clearly.
    A = dpmat({[0 1], [10 20]}, @(rho, eta) rho + eta);

    testCase.verifyError(@() plot(A, [1 2 3]), "dpmat:InvalidPlotDimensions");
    testCase.verifyError(@() plot(A, [1 1]), "dpmat:InvalidPlotDimensions");
    testCase.verifyError(@() plot(A, SamplesPerCell=0), "dpmat:InvalidPlotOptions");
end
