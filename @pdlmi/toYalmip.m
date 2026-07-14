function F = toYalmip(obj)
    %TOYALMIP Concatenate stored pdlmi entries into YALMIP constraints.
    %
    %   Syntax:
    %     F = toYalmip(C)
    %     F = C.toYalmip()
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric");
    %     F = toYalmip(P <= 0);

    F = [];
    for k = 1:numel(obj.Constraints)
        % Keep storage inspectable as one constraint per coefficient, then
        % concatenate only at the solver-facing boundary.
        F = [F, obj.Constraints{k}]; %#ok<AGROW>
    end
end
