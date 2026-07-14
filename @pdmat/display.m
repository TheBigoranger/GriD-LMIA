function display(obj)
    %DISPLAY Detailed command-window display for pdmat objects.
    %
    %   Syntax:
    %     A
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1)

    name = inputname(1);
    if isempty(name)
        name = "ans";
    end

    fprintf("%s =\n", name);
    fprintf("  pdmat with %d-by-%d matrix values\n", ...
        obj.MatrixSize(1), obj.MatrixSize(2));
    fprintf("  Parameters: %d\n", obj.npar());
    for k = 1:obj.npar()
        v = obj.GridInfo.Vectors{k};
        fprintf("    rho_%d: [%g, %g], %d nodes\n", ...
            k, v(1), v(end), numel(v));
    end
    fprintf("  Degree: %d\n", obj.Degree);
    fprintf("  Physical cells: %d\n", obj.ncell());
    fprintf("  Coefficients per cell: %d\n", obj.ncoeff());
    fprintf("  Continuous: %s\n", string(obj.IsContinuous));
    fprintf("  Source: %s\n", obj.SourceSummary);
    fprintf("  Function handle: %s\n", string(~isempty(obj.FunctionHandle)));
end
