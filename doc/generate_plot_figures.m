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

function makeThreeParameterSliceFigure(outDir)
    fig = figure("Visible", "off", "Color", "w", ...
        "Position", [100 100 760 520]);
    cleaner = onCleanup(@() close(fig));

    A = pdmat({[-1 1], [0 2], [-2 3]}, ...
        @(rho1, rho2, rho3) [ ...
            1 + 0.4*rho1.^2 + 0.1*rho2 + 0.05*rho3, ...
            2 + 0.3*rho1 + 0.1*rho2 + 0.05*rho3; ...
            3 - 0.2*rho1 + 0.15*rho2 + 0.05*rho3, ...
            4 + 0.2*rho1.^2 + 0.25*rho2 + 0.05*rho3]);
    h = plot(A, [1 2], SamplesPerCell=45, EdgeColor="none", ...
        FaceAlpha=0.55);
    faceColors = [35 86 125; 103 127 145; 154 158 161; 205 205 205]/255;
    for k = 1:numel(h)
        set(h(k), "FaceColor", faceColors(k,:));
    end
    grid on
    view(35, 25)
    xlabel("rho1", "Interpreter", "none")
    ylabel("rho2", "Interpreter", "none")
    zlabel("matrix entry")
    title("2-by-2 three-parameter object: rho3 fixed at -2")
    legend(h, ["A(1,1)", "A(1,2)", "A(2,1)", "A(2,2)"], ...
        "Location", "eastoutside")

    exportgraphics(fig, fullfile(outDir, "pdmat-plot-3d-slice.png"), ...
        "Resolution", 200);
    clear cleaner
end
