function n = width(obj)
    %WIDTH Number of matrix columns in the dpvar payload.
    %
    %   Syntax:
    %     n = width(P)
    %
    %   Example:
    %     P = dpvar(2, 3, {[0 1]}, "full");
    %     n = width(P);

    n = obj.MatrixSize(2);
end
