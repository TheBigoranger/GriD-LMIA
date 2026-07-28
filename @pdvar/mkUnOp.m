function out = mkUnOp(obj, vals, sz)
    %MKUNOP Rebuild an affine result without dropping rate-row metadata.

    out = pdvar(mkInit(obj.GridInfo.Vectors, sz, obj.Degree, vals, ...
        obj.ContainsDecision, obj.HasRateDependence, obj.RateBounds, ...
        "expression", []));
end
