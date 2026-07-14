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
end

function makeOneDimensionalFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 430]);
    cleaner = onCleanup(@() close(fig));

    A = pdmat({[0 1]}, @(rho) [rho, rho^2]);
    plot(A, SamplesPerCell=30, LineWidth=2);
    grid on
    title("One-dimensional pdmat plot")

    exportgraphics(fig, fullfile(outDir, "pdmat-plot-1d.png"), ...
        "Resolution", 200);
    clear cleaner
end

function makeTwoDimensionalFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 520]);
    cleaner = onCleanup(@() close(fig));

    A = pdmat({[0 1], [10 20]}, @(rho, eta) [rho + eta, rho - eta]);
    plot(A, [1 2], SamplesPerCell=20, EdgeColor="none");
    grid on
    view(35, 25)
    title("Two-dimensional pdmat plot")

    exportgraphics(fig, fullfile(outDir, "pdmat-plot-2d.png"), ...
        "Resolution", 200);
    clear cleaner
end
