function out = vertcat(varargin)
    %VERTCAT Vertical concatenation for pdmat blocks.
    %
    %   Syntax:
    %     C = [A; B]
    %
    %   Example:
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     C = [A; A];

    out = cat(1, varargin{:});
end
