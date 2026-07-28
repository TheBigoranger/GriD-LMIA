function disp(obj)
    %DISP Compact display for pdmat objects.
    %
    %   Syntax:
    %     disp(A)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     disp(A);

    fprintf("pdmat %s over %d-D grid, degree %d, source %s, rate rows %s\n", ...
        mat2str(obj.MatrixSize), obj.npar(), obj.Degree, ...
        obj.SourceSummary, string(obj.hasRateRows()));
end
