function n = numel(obj, varargin)
    %NUMEL Number of entries in the stored matrix payload.
    %
    %   Syntax:
    %     n = numel(obj)
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [2 3], 0);
    %     n = numel(obj);

    if nargin == 1
        n = prod(obj.MatrixSize);
    else
        % MATLAB asks object numel during indexing; each object remains a
        % scalar container even when its stored payload is a matrix.
        n = 1;
    end
end
