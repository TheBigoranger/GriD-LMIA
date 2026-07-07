function n = numel(obj, varargin)
    %NUMEL Number of entries in the dpmat matrix payload.
    %
    %   Syntax:
    %     n = numel(A)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {zeros(2, 3), ones(2, 3)}, Degree=1);
    %     n = numel(A);

    if nargin == 1
        n = prod(obj.MatrixSize);
    else
        % MATLAB calls numel with subscripts for object indexing internals;
        % the dpmat object itself remains scalar even when its payload is not.
        n = 1;
    end
end
