function verts = rateVerts(rb)
    %RATEVERTS Enumerate distinct vertices of a normalized rate box.
    %
    %   A direction with equal lower and upper bounds contributes one value.
    %   Other directions retain the lower-then-upper combRows order.

    if isempty(rb)
        verts = zeros(0, size(rb, 1));
        return
    end

    vals = num2cell(rb, 2).';
    for dim = find(rb(:, 1) == rb(:, 2)).'
        vals{dim} = rb(dim, 1);
    end
    verts = helper.combRows(vals);
end
