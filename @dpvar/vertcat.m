function out = vertcat(varargin)
    %VERTCAT Vertical concatenation for dpvar-compatible blocks.
    %
    %   Syntax:
    %     C = [P; Q]
    %
    %   Example:
    %     P = dpvar(1, 2, {[0 1]});
    %     C = [P; zeros(1, 2)];

    out = cat(1, varargin{:});
end
