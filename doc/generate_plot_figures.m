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
    makeTwoDimensionalMatrixFigure(outDir);
end

function makeOneDimensionalFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 430]);
    cleaner = onCleanup(@() close(fig));

    A = pdmat({[-1 1]}, @(rho) [rho, rho.^2]);
    h = plot(A, SamplesPerCell=80, LineWidth=2);
    set(h(1), "Color", [35 86 125]/255, "LineStyle", "-");
    set(h(2), "Color", [0.25 0.25 0.25], "LineStyle", "--");
    grid on
    xlabel("rho")
    ylabel("matrix entry")
    title("One-dimensional pdmat entries")
    legend(["A(1,1)", "A(1,2)"], "Location", "eastoutside")

    exportgraphics(fig, fullfile(outDir, "pdmat-plot-1d.png"), ...
        "Resolution", 200);
    clear cleaner
end

function makeTwoDimensionalFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 520]);
    cleaner = onCleanup(@() close(fig));

    A = pdmat({[-1 1], [0 2]}, ...
        @(rho1, rho2) 1 + rho1.^2 + 0.5*rho2 + rho1.*rho2);
    h = plot(A, [1 2], SamplesPerCell=45, EdgeColor="none", ...
        FaceAlpha=0.78);
    set(h, "FaceColor", [35 86 125]/255);
    grid on
    view(35, 25)
    xlabel("rho1", "Interpreter", "none")
    ylabel("rho2", "Interpreter", "none")
    zlabel("matrix entry")
    title("Two-dimensional pdmat surface")

    exportgraphics(fig, fullfile(outDir, "pdmat-plot-2d.png"), ...
        "Resolution", 200);
    clear cleaner
end

function makeTwoDimensionalMatrixFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 520]);
    cleaner = onCleanup(@() close(fig));

    A = pdmat({[-1 1], [0 2]}, @(rho1, rho2) [ ...
        1 + 0.8*rho1 + 0.25*rho2; ...
        1 - 0.8*rho1 + 0.25*rho2]);
    crossValue = A.evaluate([0 1]);
    leftValue = A.evaluate([-1 1]);
    rightValue = A.evaluate([1 1]);
    assert(abs(crossValue(1) - crossValue(2)) < 1e-12)
    assert(leftValue(1) < leftValue(2))
    assert(rightValue(1) > rightValue(2))
    h = plot(A, [1 2], SamplesPerCell=45, EdgeColor="none", ...
        FaceAlpha=0.62);
    set(h(1), "FaceColor", [35 86 125]/255);
    set(h(2), "FaceColor", [0.55 0.55 0.55]);
    grid on
    view(35, 25)
    xlabel("rho1", "Interpreter", "none")
    ylabel("rho2", "Interpreter", "none")
    zlabel("matrix entry")
    title("Two entries of a 2-by-1 pdmat cross at rho1 = 0")
    legend(h, ["A(1,1)", "A(2,1)"], ...
        "Location", "eastoutside")

    exportgraphics(fig, fullfile(outDir, "pdmat-plot-2d-matrix.png"), ...
        "Resolution", 200);
    clear cleaner
end
