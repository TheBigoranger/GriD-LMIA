function out = zeroObj(grid, sz)
    %ZEROOBJ Build a degree-zero coefficient-backed zero pdmat.
    %
    %   Syntax:
    %     out = zeroObj(grid, sz)
    %
    %   Arguments:
    %     grid - Physical parameter grid vectors.
    %     sz   - Matrix payload size.
    %
    %   Output:
    %     out - Continuous coefficient-backed pdmat representing zero.
    %
    %   Example:
    %     out = zeroObj({[0 1]}, [2 2]);

    info = helper.mkGrid(grid, "pdmat");
    vals = helper.mkNest(info.NumNodes - 1, @(~) {zeros(sz)});
    out = mkCoeffObj(grid, vals, zeros(1, numel(grid)), [], ...
        "coefficient-backed", true, sz);
end
