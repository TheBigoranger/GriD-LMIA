function display(obj)
    %DISPLAY Detailed command-window display for pdmat objects.
    %
    %   Syntax:
    %     A
    %
    %   Output:
    %     This method prints to the command window and returns no value.
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
    fprintf("  Degree: %s\n", mat2str(obj.Degree));
    fprintf("  Physical cells: %d\n", obj.ncell());
    fprintf("  Coefficients per cell: %d\n", obj.ncoeff());
    fprintf("  Continuous: %s\n", string(obj.IsContinuous));
    fprintf("  Rate metadata: %s\n", string(~isempty(obj.RateBounds)));
    fprintf("  Explicit rate rows: %s\n", string(obj.NumRateRows ~= 0));
    fprintf("  Source: %s\n", obj.SourceSummary);
    fprintf("  Function handle: %s\n", string(~isempty(obj.FunctionHandle)));
end
