function info = mkGrid(grid, owner)
    %MKGRID Validate tensor-grid vectors and build GridInfo.
    %
    %   Syntax:
    %     info = helper.mkGrid(grid)
    %     info = helper.mkGrid(grid, owner)
    %
    %   Arguments:
    %     grid  - Nonempty cell array of increasing parameter vectors.
    %     owner - Optional package prefix for validation identifiers.
    %
    %   Output:
    %     info - Struct with Vectors, Points, Bounds, and NumNodes.
    %
    %   Example:
    %     info = helper.mkGrid({[0 1], [10 20]}, "demo");

    if nargin < 2
        owner = "pdbase";
    end

    helper.chk(grid, owner + ":InvalidGrid", ...
        "gridVectors", ...
        "cell", "nonempty");

    % Keep only primitive grid facts here. Counts such as number of cells are
    % derived by callers so GridInfo stays stable across subclasses.
    nPar = numel(grid);
    vecs = cell(1, nPar);
    bounds = zeros(nPar, 2);
    nNode = zeros(1, nPar);
    for k = 1:nPar
        v = helper.chk(grid{k}, owner + ":InvalidGridVector", ...
            "grid vector", ...
            "numeric", "real", "vector", "finite", "increasing", "MinNumel", 2);
        v = reshape(v, 1, []);

        vecs{k} = v;
        bounds(k, :) = [v(1), v(end)];
        nNode(k) = numel(v);
    end

    % Point rows follow the same combination order as local labels.
    info = struct( ...
        "Vectors", {vecs}, ...
        "Points", helper.combRows(vecs), ...
        "Bounds", bounds, ...
        "NumNodes", nNode);
end
