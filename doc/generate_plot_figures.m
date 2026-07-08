function generate_plot_figures()
    %GENERATE_PLOT_FIGURES Regenerate MATLAB plot assets for doc/manual.tex.

    docDir = fileparts(mfilename("fullpath"));
    repoRoot = fileparts(docDir);
    addpath(repoRoot);

    outDir = fullfile(docDir, "matlab-figures");
    if ~exist(outDir, "dir")
        mkdir(outDir);
    end

    makeOneDimensionalFigure(outDir);
    makeTwoDimensionalFigure(outDir);
    makeDpvarConstructorFigure(outDir);
    mirrorWebpageFigures(docDir, outDir);
end

function makeOneDimensionalFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 430]);
    cleaner = onCleanup(@() close(fig));

    A = dpmat({[0 1]}, @(rho) [rho, rho^2]);
    plot(A, SamplesPerCell=30, LineWidth=2);
    grid on
    title("One-dimensional dpmat plot")

    exportgraphics(fig, fullfile(outDir, "dpmat-plot-1d.png"), ...
        "Resolution", 200);
    clear cleaner
end

function makeTwoDimensionalFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 520]);
    cleaner = onCleanup(@() close(fig));

    A = dpmat({[0 1], [10 20]}, @(rho, eta) [rho + eta, rho - eta]);
    plot(A, [1 2], SamplesPerCell=20, EdgeColor="none");
    grid on
    view(35, 25)
    title("Two-dimensional dpmat plot")

    exportgraphics(fig, fullfile(outDir, "dpmat-plot-2d.png"), ...
        "Resolution", 200);
    clear cleaner
end

function makeDpvarConstructorFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 900 560]);
    cleaner = onCleanup(@() close(fig));

    x = [0 1 2];
    y = [0.28 0.82 0.48];
    plot(x(1:2), y(1:2), "-", "Color", [0.11 0.38 0.83], ...
        "LineWidth", 3);
    hold on
    plot(x(2:3), y(2:3), "-", "Color", [0.11 0.38 0.83], ...
        "LineWidth", 3);
    plot(x, y, "o", "MarkerSize", 9, "MarkerFaceColor", [0.11 0.38 0.83], ...
        "MarkerEdgeColor", "w", "LineWidth", 1.5);

    xlim([-0.25 2.25])
    ylim([-0.45 1.05])
    grid on
    box on
    xlabel("\rho")
    ylabel("one entry of P(\rho)")
    title("dpvar constructor: parameter-dependent variable stored by cell-local coefficients")

    text(0, y(1) + 0.10, "P_0", "HorizontalAlignment", "center", ...
        "FontWeight", "bold", "Color", [0.11 0.38 0.83]);
    text(1, y(2) + 0.10, "P_1 shared node", "HorizontalAlignment", "center", ...
        "FontWeight", "bold", "Color", [0.11 0.38 0.83]);
    text(2, y(3) + 0.10, "P_2", "HorizontalAlignment", "center", ...
        "FontWeight", "bold", "Color", [0.11 0.38 0.83]);

    annotation(fig, "textbox", [0.16 0.13 0.28 0.16], ...
        "String", "LocalValues{1}" + newline + ...
            "cell 1 coefficients: P0, P1" + newline + ...
            "local Bernstein pair", ...
        "FitBoxToText", "off", "BackgroundColor", [0.91 0.96 1.00], ...
        "EdgeColor", [0.44 0.60 0.82], "LineWidth", 1.2, ...
        "FontName", "Consolas", "FontSize", 10, "Interpreter", "none");
    annotation(fig, "textbox", [0.56 0.13 0.28 0.16], ...
        "String", "LocalValues{2}" + newline + ...
            "cell 2 coefficients: P1, P2" + newline + ...
            "P1 is the shared boundary", ...
        "FitBoxToText", "off", "BackgroundColor", [0.91 0.96 1.00], ...
        "EdgeColor", [0.44 0.60 0.82], "LineWidth", 1.2, ...
        "FontName", "Consolas", "FontSize", 10, "Interpreter", "none");
    annotation(fig, "textbox", [0.34 0.79 0.34 0.09], ...
        "String", "Schematic plot: each Pi is a YALMIP matrix coefficient.", ...
        "FitBoxToText", "off", "BackgroundColor", [1.00 0.98 0.88], ...
        "EdgeColor", [0.85 0.67 0.20], "LineWidth", 1.2, ...
        "FontSize", 10, "Interpreter", "none");

    exportgraphics(fig, fullfile(outDir, "dpvar-constructor-localvalues.png"), ...
        "Resolution", 200);
    clear cleaner
end

function mirrorWebpageFigures(docDir, outDir)
    repoRoot = fileparts(docDir);
    webDir = fullfile(repoRoot, "webpage", "public", "plots");
    if ~exist(webDir, "dir")
        return
    end

    fileName = "dpvar-constructor-localvalues.png";
    copyfile(fullfile(outDir, fileName), fullfile(webDir, fileName));
end
