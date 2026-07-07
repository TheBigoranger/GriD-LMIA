function n = numArgumentsFromSubscript(~, ~, ~)
    %NUMARGUMENTSFROMSUBSCRIPT Keep dpmat subscript results scalar.
    %
    %   Syntax:
    %     n = numArgumentsFromSubscript(A, S, ctx)
    %
    %   Example:
    %     A = dpmat({[0 1]}, {1, 2}, Degree=1);
    %     d = A.Degree;

    % numel(A) reports matrix-payload entries, so dot access needs this
    % object-level guard to avoid unintended comma-separated expansion.
    n = 1;
end
