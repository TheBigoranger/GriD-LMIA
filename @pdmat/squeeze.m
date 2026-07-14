function out = squeeze(obj)
    %SQUEEZE Preserve the two-dimensional pdmat matrix payload.
    %
    %   Syntax:
    %     B = squeeze(A)
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2], [3 4]}, Degree=1);
    %     B = squeeze(A);

    out = obj;
end
