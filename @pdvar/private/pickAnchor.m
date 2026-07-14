function anchor = pickAnchor(errId, args)
    %PICKANCHOR Return the first pdvar operand that owns dispatch context.

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
