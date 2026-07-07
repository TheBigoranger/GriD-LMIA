function n = ndims(~)
    %NDIMS Number of matrix dimensions represented by dpmat.
    %
    %   Syntax:
    %     n = ndims(A)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     n = ndims(A);

    n = 2;
end
