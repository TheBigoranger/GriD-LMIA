function info = mkGrid(grid, owner)
    %MKGRID Validate tensor-grid vectors and build GridInfo.

    if nargin < 2
        owner = "pdbase";
    end

    helper.chk(grid, owner + ":InvalidGrid", ...
        "gridVectors must be a nonempty cell array of grid node vectors.", ...
        "cell", "nonempty");

    % Keep only primitive grid facts here. Counts such as number of cells are
    % derived by callers so GridInfo stays stable across subclasses.
    nPar = numel(grid);
    vecs = cell(1, nPar);
    bounds = zeros(nPar, 2);
    nNode = zeros(1, nPar);
    for k = 1:nPar
        v = helper.chk(grid{k}, owner + ":InvalidGridVector", ...
            "Each grid vector must be a finite, strictly increasing real numeric vector with at least two nodes.", ...
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
