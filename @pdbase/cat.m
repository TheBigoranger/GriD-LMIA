function cat(~, varargin)
    %CAT Reject MATLAB object-array concatenation of direct pdbase values.
    %
    %   Direct pdbase instances are scalar payload containers. Derived
    %   pdmat and pdvar classes own coefficient-wise concatenation, while a
    %   direct pdbase array would make overloaded size and numel ambiguous.

    error("pdbase:UnsupportedConcatenation", ...
        "Direct pdbase operands cannot be concatenated.");
end
