function grid = mergeGrid(obj, errId, varargin)
    %MERGEGRID Build a same-bound common refinement grid for gridded operands.
    %
    %   Syntax:
    %     grid = obj.mergeGrid(errId, other1, other2, ...)
    %
    %   Example (invoked through public pdmat algebra):
    %     A = pdmat({[0 1]}, {1, 2}, Degree=1);
    %     B = pdmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
    %     C = A + B;  % Uses the common refinement [0 0.5 1].
    %
    %   This protected helper preserves parameter bounds and inserts interior
    %   nodes from every pdbase operand. Different parameter dimensions or
    %   bounds raise ERRID; non-pdbase operands are ignored here and validated
    %   by the operation-specific conversion helper.

    grid = obj.GridInfo.Vectors;
    vals = [{obj}, varargin];
    for k = 1:numel(vals)
        val = vals{k};
        if ~isa(val, "pdbase")
            continue
        end
        if numel(grid) ~= val.npar()
            error(errId, "gridded operands must have the same parameter dimension.");
        end
        for p = 1:numel(grid)
            vec = val.GridInfo.Vectors{p};
            if grid{p}(1) ~= vec(1) || grid{p}(end) ~= vec(end)
                error(errId, "gridded operands must have matching grid bounds.");
            end
            grid{p} = unique([grid{p}, vec], "sorted");
        end
    end
end
