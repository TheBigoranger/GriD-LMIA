function n = numel(obj, varargin)
    %NUMEL Number of entries in the pdvar matrix payload.
    %
    %   Syntax:
    %     n = numel(P)
    %
    %   Example:
    %     P = pdvar(2, 3, {[0 1]}, "full");
    %     n = numel(P);

    if nargin == 1
        n = prod(obj.MatrixSize);
    else
        % MATLAB asks object numel during indexing; pdvar objects remain
        % scalar containers even when their symbolic payload is a matrix.
        n = 1;
    end
end
