function cat(~, varargin)
    %CAT Reject MATLAB object-array concatenation of direct pdbase values.
    %
    %   Syntax:
    %     cat(dim, A, B)
    %
    %   Output:
    %     This method has no successful output for direct pdbase operands.
    %
    %   Example:
    %     A = pdbase({[0 1]}, [1 1], 0);
    %     cat(1, A, A);
    %
    %   Direct pdbase instances are scalar payload containers. Derived
    %   pdmat and pdvar classes own coefficient-wise concatenation, while a
    %   direct pdbase array would make overloaded size and numel ambiguous.

    error("pdbase:UnsupportedConcatenation", ...
        "Direct pdbase operands cannot be concatenated.");
end
