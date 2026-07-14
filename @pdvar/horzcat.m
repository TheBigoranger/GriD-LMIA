function out = horzcat(varargin)
    %HORZCAT Horizontal concatenation for pdvar-compatible blocks.
    %
    %   Syntax:
    %     C = [P, Q]
    %
    %   Example:
    %     P = pdvar(2, 1, {[0 1]});
    %     C = [P, zeros(2, 1)];

    out = cat(2, varargin{:});
end
