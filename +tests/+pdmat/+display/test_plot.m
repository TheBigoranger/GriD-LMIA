function tests = test_plot
    % Behavioral regressions for pdmat.plot.
    tests = functiontests(localfunctions);
end
function test_function_only_plot_preserves_hold_and_exact_matrix_data(testCase)
    % Graphics samples the exact evaluator and leaves a caller-owned hold state.
    fig = figure(Visible="off");
    cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
    ax = axes(fig);
    hold(ax,"on");
    F = pdmat([0 .5 2], @(x) [sin(x), exp(x); x^2, 1+x]);
    lines = plot(F, SamplesPerCell=2);
    points = [0 .25 .5 1.25 2];
    expected = {sin(points), points.^2, exp(points), 1+points};
    for k = 1:4
        testCase.verifyEqual(lines(k).XData, points, AbsTol=1e-12);
        testCase.verifyEqual(lines(k).YData, expected{k}, AbsTol=1e-12);
    end
    testCase.verifyTrue(ishold(ax));
    testCase.verifyEqual(F.SourceSummary, "function");
end

function test_1_d_plotting_sample_evaluate_label(testCase)
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

function test_2_d_plotting_create_transparent_surface(testCase)
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

function test_unnamed_expression_documented_fallback_legend_name(testCase)
    % An unnamed expression should use the documented fallback legend name.
    fig = figure("Visible", "off");
    cleaner = onCleanup(@() close(fig));
    A = pdmat([0 1], @(rho) rho, Degree=1);

    plot(A + 0, SamplesPerCell=1);
    lgd = findobj(fig, "Type", "legend");

    testCase.verifyEqual(string(lgd.String{1}), "$A_{1,1}$");
    clear cleaner
end

function test_higher_dimensional_objects_fix_unselected_dimensions(testCase)
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

function test_invalid_plot_dimensions_sample_counts_fail(testCase)
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

function test_adjacent_cells_contribute_sample_only_once(testCase)
    % Adjacent cells should contribute their shared sample only once.
    fig = figure("Visible", "off");
    cleaner = onCleanup(@() close(fig));
    A = pdmat([0 0.5 1], @(rho) rho);

    h = plot(A, SamplesPerCell=2);

    testCase.verifyEqual(h.XData, [0 0.25 0.5 0.75 1], AbsTol=1e-12);
    testCase.verifyEqual(h.YData, h.XData, AbsTol=1e-12);
    clear cleaner
end
function test_plot_selection_rejects_indices_beyond_distinct(testCase)
    % Plot selection rejects indices beyond the distinct stored vertices.
    fixed = pdmat([0 2], {1, 5}, Degree=1, RateBounds=[3 3]);
    fixedD = rhodiff(fixed);
    [tensorD, ~] = fixedTensorRateData();

    testCase.verifyError(@() plot(fixedD, RateVertex=2), ...
        "pdmat:InvalidRateVertex");
    testCase.verifyError(@() plot(tensorD, [1 2], RateVertex=3), ...
        "pdmat:InvalidRateVertex");
end

function [D, A] = fixedTensorRateData()
    % Build two stored rate rows from one fixed and one varying direction.
    grid = {[0 1], [10 12]};
    rb = [1 1; -3 5];
    source = pdmat(grid, @(rho, eta) rho + eta, ...
        Degree=[1 1], RateBounds=rb);
    D = rhodiff(source);
    A = pdmat(grid, @(rho, eta) 1 + rho, ...
        Degree=[1 0], RateBounds=rb);
end

function test_reversed_axes_complete_matrix_surfaces(testCase)
    fig=figure('Visible','off'); cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    A=pdmat({[0 2 5],[-3 1 7]},@(x,y) [x+2*y,3*x-y;5-x*y,x^2+y]);
    [X,Y]=meshgrid([-3 -1 1 4 7],[0 1 2 3.5 5]);
    expected={Y+2*X,5-Y.*X,3*Y-X,Y.^2+X};
    for held=[false true]
        if held, hold on; else, hold off; end
        handles=plot(A,[2 1],SamplesPerCell=2);
        testCase.verifyEqual(ishold,held);
        testCase.assertEqual(numel(handles),4);
        for k=1:4
            testCase.verifyEqual(handles(k).XData,X);
            testCase.verifyEqual(handles(k).YData,Y);
            testCase.verifyEqual(handles(k).ZData,expected{k},AbsTol=1e-10);
        end
    end
end
