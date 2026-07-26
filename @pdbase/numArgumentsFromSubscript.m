function n = numArgumentsFromSubscript(~, ~, ~)
    %NUMARGUMENTSFROMSUBSCRIPT Keep subscript results scalar.
    %
    %   Syntax:
    %     n = numArgumentsFromSubscript(obj, S, ctx)
    %
    %   Example:
    %     obj = pdbase({[0 1]}, [1 1], 0);
    %     deg = obj.Degree;

    % numel follows matrix-payload semantics, so dot access needs this
    % object-level guard to avoid unintended comma-separated expansion.
    n = 1;
end
