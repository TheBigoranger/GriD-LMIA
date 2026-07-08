function tf = isZeroKnown(val)
    %ISZEROKNOWN True when a dpmat has explicit zero coefficient evidence.

    tf = isa(val, "dpmat") && val.SourceSummary ~= "function" && ...
        isZeroVals(val.LocalValues);
end
