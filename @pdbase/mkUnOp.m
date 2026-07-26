function out = mkUnOp(obj, vals, sz)
    %MKUNOP Rebuild a direct pdbase result by updating a value-class copy.

    out = obj;
    out.MatrixSize = sz;
    out.LocalValues = vals;
end
