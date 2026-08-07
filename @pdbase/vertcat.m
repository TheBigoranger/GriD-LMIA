function out = vertcat(varargin)
    %VERTCAT Vertically concatenate compatible derived payload objects.
    %
    %   Syntax:
    %     C = [A; B]
    %
    %   Output:
    %     C - Concatenated derived object returned by the class-owned cat.
    %
    %   Direct pdbase operands are rejected because pdbase represents one
    %   scalar payload container rather than a MATLAB object array.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     C = [A; A];

    if any(cellfun(@(arg) strcmp(class(arg), "pdbase"), varargin))
        error("pdbase:UnsupportedConcatenation", ...
            "Direct pdbase operands cannot be concatenated.");
    end
    out = cat(1, varargin{:});
end
