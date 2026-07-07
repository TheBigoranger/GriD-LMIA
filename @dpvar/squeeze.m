function out = squeeze(obj)
    %SQUEEZE Preserve the two-dimensional dpvar matrix payload.
    %
    %   Syntax:
    %     Q = squeeze(P)
    %
    %   Example:
    %     P = dpvar(1, 2, {[0 1]}, "full");
    %     Q = squeeze(P);

    out = obj;
end
