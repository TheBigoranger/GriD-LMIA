function out = flip(obj, dim)
    %FLIP Reverse every coefficient matrix along one matrix dimension.
    %
    %   Syntax:
    %     out = flip(obj)
    %     out = flip(obj, dim)
    %
    %   Arguments:
    %     dim - Optional positive integer matrix dimension.
    %
    %   Output:
    %     out - Same dynamic class with each coefficient matrix flipped.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2; 3 4], [2 4; 6 8]}, Degree=1);
    %     B = flip(A, 2);

    if nargin < 2
        out = mapUnary(obj, @(a) flip(a));
        return
    end

    prefix = string(class(obj));
    dim = helper.chk(dim, prefix + ":InvalidFlip", ...
        "flip dimension", ...
        "numeric", "real", "scalar", "finite", "integer", "positive");
    out = mapUnary(obj, @(a) flip(a, double(dim)));
end
