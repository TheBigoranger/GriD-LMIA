function out = vertcat(varargin)
    %VERTCAT Vertical concatenation for pdvar-compatible blocks.
    %
    %   Syntax:
    %     C = [P; Q]
    %
    %   Example:
    %     P = pdvar(1, 2, {[0 1]});
    %     C = [P; zeros(1, 2)];

    out = cat(1, varargin{:});
end
