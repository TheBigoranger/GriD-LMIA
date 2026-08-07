function out = mkUnOp(obj, vals, sz)
    %MKUNOP Rebuild an affine result without dropping rate-row metadata.
    %
    %   Syntax:
    %     out = obj.mkUnOp(vals, sz)
    %
    %   Arguments:
    %     vals - Mapped nested coefficient tree.
    %     sz   - New stored matrix payload size.
    %
    %   Output:
    %     out - pdvar expression preserving decision, rate, and RateBounds
    %           metadata.
    %
    %   Example:
    %     out = obj.mkUnOp(vals, [1 1]);

    out = pdvar(mkCtorState(obj.GridInfo.Vectors, sz, obj.Degree, vals, ...
        obj.ContainsDecision, obj.RateBounds, ...
        "expression", [], "fast", obj.NumRateRows));
end
