function n = height(obj)
    %HEIGHT Number of matrix rows in the dpvar payload.
    %
    %   Syntax:
    %     n = height(P)
    %
    %   Example:
    %     P = dpvar(2, 3, {[0 1]}, "full");
    %     n = height(P);

    n = obj.MatrixSize(1);
end
