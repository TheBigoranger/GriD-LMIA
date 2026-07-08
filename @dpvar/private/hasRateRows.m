function tf = hasRateRows(val)
    %HASRATEROWS True when a dpvar stores derivative rate-vertex rows.

    tf = false;
    if isa(val, "dpvar")
        nCoeff = (val.Degree + 1) ^ val.npar();
        tf = isRateRows(val.LocalValues, val.GridInfo.Vectors, nCoeff);
    end
end
