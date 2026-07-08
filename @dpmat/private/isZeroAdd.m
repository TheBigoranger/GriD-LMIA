function tf = isZeroAdd(val, sz)
    %ISZEROADD True when VAL is an additive zero for matrix size SZ.

    tf = isZeroNum(val) && (isscalar(val) || isequal(size(val), sz));
end
