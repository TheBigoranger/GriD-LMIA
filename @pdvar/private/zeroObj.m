function out = zeroObj(grid, sz)
    %ZEROOBJ Build a degree-zero zero pdvar expression.
    %
    %   Syntax:
    %     out = zeroObj(grid, sz)
    %
    %   Arguments:
    %     grid - Physical parameter grid vectors.
    %     sz   - Matrix payload size.
    %
    %   Output:
    %     out - Decision-free pdvar expression representing zero.
    %
    %   Example:
    %     out = zeroObj({[0 1]}, [2 2]);

    info = helper.mkGrid(grid, "pdvar");
    vals = helper.mkNest(info.NumNodes - 1, @(~) {zeros(sz)});
    out = pdvar(mkCtorState(grid, sz, zeros(1, numel(grid)), ...
        vals, false, [], ...
        "expression", true));
end
