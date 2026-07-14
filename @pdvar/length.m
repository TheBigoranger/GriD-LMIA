function n = length(obj)
    %LENGTH Largest matrix dimension of the pdvar payload.
    %
    %   Syntax:
    %     n = length(P)
    %
    %   Example:
    %     P = pdvar(2, 3, {[0 1]}, "full");
    %     n = length(P);

    n = max(obj.MatrixSize);
end
