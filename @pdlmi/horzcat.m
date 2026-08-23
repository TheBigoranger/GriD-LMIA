function F = horzcat(varargin)
    %HORZCAT Export and concatenate pdlmi and YALMIP constraint lists.
    %
    %   Syntax:
    %     F = [C1, C2, ...]
    %
    %   Inputs:
    %     C1, C2, ... - Scalar symbolic pdlmi wrappers, YALMIP constraint
    %                   objects, or YALMIP lmi lists.
    %
    %   Output:
    %     F - YALMIP constraint object or list in the original operand order.
    %
    %   Logical known-data certificates and other operand classes raise
    %   pdlmi:InvalidConcatenation. Concatenation is a terminal conversion;
    %   apply pdlmi certificate selections before forming F.

    cons = varargin;
    for k = 1:numel(cons)
        item = cons{k};
        if isa(item, "pdlmi")
            if ~isscalar(item)
                error("pdlmi:InvalidConcatenation", ...
                    "pdlmi concatenation requires scalar pdlmi operands.");
            end
            item = toYalmip(item);
            if islogical(item)
                error("pdlmi:InvalidConcatenation", ...
                    "Logical known-data certificates cannot be concatenated with symbolic constraints.");
            end
        elseif ~(isa(item, "constraint") || isa(item, "lmi"))
            error("pdlmi:InvalidConcatenation", ...
                "Operands must be scalar pdlmi, constraint, or lmi objects.");
        end
        cons{k} = item;
    end

    % Delegate ordering, duplicate handling, and list storage to YALMIP.
    F = [cons{:}];
end
