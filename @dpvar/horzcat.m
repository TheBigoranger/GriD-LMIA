function out = horzcat(varargin)
    %HORZCAT Horizontal concatenation for dpvar-compatible blocks.
    %
    %   Syntax:
    %     C = [P, Q]
    %
    %   Example:
    %     P = dpvar(2, 1, {[0 1]});
    %     C = [P, zeros(2, 1)];

    out = cat(2, varargin{:});
end
