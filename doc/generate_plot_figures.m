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

    A = pdmat({[-1 1]}, @(rho) [ ...
        0.4 + 0.9*rho - 0.8*rho.^2 + 0.5*rho.^3, ...
       -0.2 + 0.3*rho + 1.1*rho.^2 - 0.7*rho.^3 + 0.2*rho.^4]);
    plot(A, SamplesPerCell=80, LineWidth=2);
    grid on
    xlabel("rho")
    ylabel("matrix entry")
    title("Crossing higher-order pdmat entries")
    legend(["A(1,1)", "A(1,2)"], "Location", "eastoutside")

    exportgraphics(fig, fullfile(outDir, "pdmat-plot-1d.png"), ...
        "Resolution", 200);
    clear cleaner
end

function makeTwoDimensionalFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 520]);
    cleaner = onCleanup(@() close(fig));

    A = pdmat({[-1 1], [-1 1]}, @(rho, eta) [ ...
        0.5 + 0.7*rho - 0.6*eta + 0.9*rho.*eta + ...
            0.4*rho.^2 - 0.3*eta.^3 + 0.25*rho.^2.*eta.^2, ...
        0.2 - 0.5*rho + 0.8*eta - 0.7*rho.*eta - ...
            0.3*rho.^2 + 0.35*eta.^2 + 0.3*rho.^3.*eta]);
    plot(A, [1 2], SamplesPerCell=45, EdgeColor="none", FaceAlpha=0.72);
    grid on
    view(35, 25)
    xlabel("rho1", "Interpreter", "none")
    ylabel("rho2", "Interpreter", "none")
    zlabel("matrix entry")
    title("Intersecting higher-order pdmat surfaces")
    legend(["A(1,1)", "A(1,2)"], "Location", "eastoutside")

    exportgraphics(fig, fullfile(outDir, "pdmat-plot-2d.png"), ...
        "Resolution", 200);
    clear cleaner
end
