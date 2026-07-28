function out = mkRhodiff(obj, deg, vals, rb, hasDec)
    %MKRHODIFF Rebuild a derivative while preserving pdvar value semantics.

    out = pdvar(mkInit(obj.GridInfo.Vectors, obj.MatrixSize, deg, vals, ...
        hasDec, true, rb, "derivative", false));
end
