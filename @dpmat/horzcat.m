function out = horzcat(varargin)
    %HORZCAT Horizontal concatenation for dpmat blocks.
    %
    %   Syntax:
    %     C = [A, B]
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     C = [A, A];

    out = cat(2, varargin{:});
end
