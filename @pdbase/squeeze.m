function out = squeeze(obj)
    %SQUEEZE Preserve the two-dimensional stored matrix payload.
    %
    %   Syntax:
    %     out = squeeze(obj)
    %
    %   Output:
    %     out - The input object unchanged.
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [1 2], 0);
    %     out = squeeze(obj);

    out = obj;
end
