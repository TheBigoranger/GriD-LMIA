function grid = mergeGrid(obj, errId, varargin)
    %MERGEGRID Build a same-bound common refinement grid for gridded operands.

    grid = obj.GridInfo.Vectors;
    vals = [{obj}, varargin];
    for k = 1:numel(vals)
        val = vals{k};
        if ~isa(val, "dpbase")
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
