function n = width(obj)
    %WIDTH Number of matrix columns in the pdvar payload.
    %
    %   Syntax:
    %     n = width(P)
    %
    %   Example:
    %     P = pdvar(2, 3, {[0 1]}, "full");
    %     n = width(P);

    n = obj.MatrixSize(2);
end
