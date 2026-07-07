function n = length(obj)
    %LENGTH Largest matrix dimension of the dpvar payload.
    %
    %   Syntax:
    %     n = length(P)
    %
    %   Example:
    %     P = dpvar(2, 3, {[0 1]}, "full");
    %     n = length(P);

    n = max(obj.MatrixSize);
end
