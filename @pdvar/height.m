function n = height(obj)
    %HEIGHT Number of matrix rows in the pdvar payload.
    %
    %   Syntax:
    %     n = height(P)
    %
    %   Example:
    %     P = pdvar(2, 3, {[0 1]}, "full");
    %     n = height(P);

    n = obj.MatrixSize(1);
end
