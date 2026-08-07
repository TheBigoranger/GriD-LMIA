function out = mkUnOp(obj, vals, sz)
    %MKUNOP Rebuild a direct pdbase result by updating a value-class copy.
    %
    %   Syntax:
    %     out = obj.mkUnOp(vals, sz)
    %
    %   Arguments:
    %     vals - Mapped nested coefficient tree.
    %     sz   - New stored matrix payload size.
    %
    %   Output:
    %     out - Direct pdbase copy with updated MatrixSize and LocalValues.
    %
    %   Example:
    %     out = obj.mkUnOp(vals, [1 1]);
    %
    %   Derived classes override this hook so inherited matrix operations can
    %   rebuild pdmat or pdvar without duplicating traversal logic.

    out = obj;
    out.MatrixSize = sz;
    out.LocalValues = vals;
end
