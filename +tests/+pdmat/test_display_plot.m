function tests = test_display_plot
    %TEST_DISPLAY_PLOT pdmat command-window display and plotting.
    tests = functiontests(localfunctions);
end

function testDisAndDisTex(testCase)
    % disp should stay compact while display prints useful metadata.
    A = pdmat({[0 1]}, {1, 2}, Degree=1);

    short = evalc("disp(A)");
    detail = evalc("display(A)");
    unnamed = evalc("display(pdmat({[0 1]}, {1, 2}, Degree=1))");

    testCase.verifyTrue(contains(short, "pdmat [1 1] over 1-D grid"));
    testCase.verifyTrue(contains(short, "source coefficient-backed"));
    testCase.verifyTrue(contains(detail, "A ="));
    testCase.verifyTrue(contains(detail, "pdmat with 1-by-1 matrix values"));
    testCase.verifyTrue(contains(detail, "rho_1: [0, 1], 2 nodes"));
    testCase.verifyTrue(contains(detail, "Coefficients per cell: 2"));
    testCase.verifyTrue(contains(unnamed, "pdmat with 1-by-1 matrix values"));
end

function testPloOneDimFunBac(testCase)
    % 1-D plotting should sample through evaluate and label each matrix entry.
    fig = figure("Visible", "off");
    cleaner = onCleanup(@() close(fig));
    A = pdmat({[0 1]}, @(rho) [rho, rho^2]);

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

function testPloTwoDimSurDef(testCase)
    % 2-D plotting should create one transparent surface per matrix entry.
    fig = figure("Visible", "off");
    cleaner = onCleanup(@() close(fig));
    A = pdmat({[0 1], [10 20]}, @(rho, eta) [rho + eta, rho - eta]);

    hDefault = plot(A, [1 2], SamplesPerCell=1);
    testCase.verifyEqual(hDefault(1).FaceAlpha, 0.5);
    h = plot(A, [1 2], SamplesPerCell=2, EdgeColor="none", FaceAlpha=0.7);
    lgd = findobj(fig, "Type", "legend");
    ax = gca;
    colors = lines(2);

    testCase.verifyEqual(numel(h), 2);
    testCase.verifyEqual(size(h(1).XData), [3 3]);
    testCase.verifyEqual(h(1).FaceAlpha, 0.7);
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

function testPloExpUseDefNam(testCase)
    % An unnamed expression should use the documented fallback legend name.
    fig = figure("Visible", "off");
    cleaner = onCleanup(@() close(fig));
    A = pdmat([0 1], @(rho) rho);

    plot(A + 0, SamplesPerCell=1);
    lgd = findobj(fig, "Type", "legend");

    testCase.verifyEqual(string(lgd.String{1}), "$A_{1,1}$");
    clear cleaner
end

function testPloHigDimSli(testCase)
    % Higher-dimensional objects should fix unselected dimensions at lower bounds.
    fig = figure("Visible", "off");
    cleaner = onCleanup(@() close(fig));
    A = pdmat({[0 1], [10 20], [100 200]}, ...
        @(rho, eta, gam) rho + eta + gam);

    h = plot(A, 3, SamplesPerCell=2);

    testCase.verifyEqual(numel(h), 1);
    testCase.verifyEqual(h.XData, [100 150 200], AbsTol=1e-12);
    testCase.verifyEqual(h.YData, [110 160 210], AbsTol=1e-12);
    clear cleaner
end

function testPloOptVal(testCase)
    % Invalid plot dimensions and sample counts should fail clearly.
    A = pdmat({[0 1], [10 20]}, @(rho, eta) rho + eta);

    testCase.verifyError(@() plot(A, [1 2 3]), "pdmat:InvalidPlotDimensions");
    testCase.verifyError(@() plot(A, [1 1]), "pdmat:InvalidPlotDimensions");
    testCase.verifyError(@() plot(A, SamplesPerCell=0), "pdmat:InvalidPlotOptions");
    testCase.verifyError(@() plot(A, "SamplesPerCell"), ...
        "pdmat:InvalidPlotOptions");

    R = pdmat([0 1], {{1, 2; 3, 4}}, Degree=1, RateBounds=[-1 1]);
    testCase.verifyError(@() plot(R, RateVertex=1, RateVertex=2), ...
        "pdmat:InvalidRateVertex");
end

function testPloMulCelNoDup(testCase)
    % Adjacent cells should contribute their shared sample only once.
    fig = figure("Visible", "off");
    cleaner = onCleanup(@() close(fig));
    A = pdmat([0 0.5 1], @(rho) rho);

    h = plot(A, SamplesPerCell=2);

    testCase.verifyEqual(h.XData, [0 0.25 0.5 0.75 1], AbsTol=1e-12);
    testCase.verifyEqual(h.YData, h.XData, AbsTol=1e-12);
    clear cleaner
end
