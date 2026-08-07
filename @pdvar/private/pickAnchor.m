function anchor = pickAnchor(errId, args)
    %PICKANCHOR Return the first pdvar operand that owns dispatch context.
    %
    %   Syntax:
    %     anchor = pickAnchor(errId, args)
    %
    %   Arguments:
    %     errId - Error identifier owned by the calling operation.
    %     args  - Cell array of mixed operands.
    %
    %   Output:
    %     anchor - First pdvar operand in args.
    %
    %   Example:
    %     anchor = pickAnchor("pdvar:InvalidAddition", {lhs, rhs});

    anchor = [];
    for k = 1:numel(args)
        if isa(args{k}, "pdvar")
            anchor = args{k};
            break
        end
    end
    if isempty(anchor)
        error(errId, "At least one operand must be a pdvar.");
    end
end
