function coeffs = cellGet(vals, subs)
    %CELLGET Read nested physical-cell storage by subscript row.

    coeffs = vals;
    for k = 1:numel(subs)
        coeffs = coeffs{subs(k)};
    end
end
