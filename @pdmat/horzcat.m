function out = horzcat(varargin)
    %HORZCAT Horizontal concatenation for pdmat blocks.
    %
    %   Syntax:
    %     C = [A, B]
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     C = [A, A];

    out = cat(2, varargin{:});
end
