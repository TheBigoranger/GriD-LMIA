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
    makeThreeParameterSliceFigure(outDir);
end

function makeOneDimensionalFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 430]);
    cleaner = onCleanup(@() close(fig));

    A = pdmat({[-1 1]}, @(rho) [rho, rho.^2]);
    plot(A, SamplesPerCell=80, LineWidth=2);
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
    plot(A, [1 2], SamplesPerCell=45, EdgeColor="none");
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

function makeThreeParameterSliceFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 520]);
    cleaner = onCleanup(@() close(fig));

    A = pdmat({[-1 1], [0 2], [-2 3]}, ...
        @(rho1, rho2, rho3) rho1.^2 + rho2 + 2*rho3);
    plot(A, [1 2], SamplesPerCell=45, EdgeColor="none");
    grid on
    view(35, 25)
    title("Three-parameter object: rho3 fixed at -2")

    exportgraphics(fig, fullfile(outDir, "pdmat-plot-3d-slice.png"), ...
        "Resolution", 200);
    clear cleaner
end
