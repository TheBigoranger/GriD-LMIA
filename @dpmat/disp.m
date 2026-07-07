function disp(obj)
    %DISP Compact display for dpmat objects.
    %
    %   Syntax:
    %     disp(A)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     disp(A);

    fprintf("dpmat %s over %d-D grid, degree %d, source %s\n", ...
        mat2str(obj.MatrixSize), obj.npar(), obj.Degree, obj.SourceSummary);
end
