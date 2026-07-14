function n = numArgumentsFromSubscript(~, ~, ~)
    %NUMARGUMENTSFROMSUBSCRIPT Keep pdvar subscript results scalar.
    %
    %   Syntax:
    %     n = numArgumentsFromSubscript(P, S, ctx)
    %
    %   Example:
    %     P = pdvar(1, {[0 1]});
    %     c = P.Degree;

    % numel(P) follows matrix-payload semantics, so dot access needs this
    % object-level guard to avoid unintended comma-separated expansion.
    n = 1;
end
