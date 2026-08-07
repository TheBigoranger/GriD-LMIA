function vals = chkBernstein(fh, info, deg, sz)
    %CHKBERNSTEIN Validate a function handle as local Bernstein data.
    %
    %   Syntax:
    %     vals = chkBernstein(fh, gridInfo, degree, matrixSize)
    %
    %   Arguments:
    %     fh         - Function handle with one input per parameter.
    %     gridInfo   - Normalized tensor-grid metadata.
    %     degree     - Requested scalar or per-parameter degree.
    %     matrixSize - Required function-output size.
    %
    %   Output:
    %     vals - Certified cell-local coefficient tree.
    %
    %   Example:
    %     info = helper.mkGrid({[0 1]}, "pdmat");
    %     vals = chkBernstein(@(rho) rho, info, 1, [1 1]);

    nPar = numel(info.Vectors);
    nCell = info.NumNodes - 1;
    [vals, lbls] = helper.fitVals(info, deg, sz, ...
        @(pt) evalFcn(fh, pt, sz), "pdmat");
    nCoeff = size(lbls, 1);

    symOk = false;
    if exist("sym", "file") == 2
        try
            xs = sym("x", [1 nPar], "real");
            args = num2cell(xs);
            raw = fh(args{:});
            if isequal(size(raw), sz)
                raw = sym(raw);
                % Symbolic differentiation and truth checks preserve matrix shape.
                for p = 1:nPar
                    high = simplify(diff(raw, xs(p), deg(p) + 1));
                    tf = isAlways(high == 0);
                    if isempty(tf) || ~all(tf(:))
                        error("pdmat:NonBernsteinPolynomial", ...
                            "Function handle is not representable by the requested Bernstein degree.");
                    end
                end
                symOk = true;
            end
        catch err
            if strcmp(err.identifier, "pdmat:NonBernsteinPolynomial")
                rethrow(err);
            end
            symOk = false;
        end
    end
    if symOk
        return
    end

    % Probe away from interpolation nodes so accidental fits are rejected.
    mid = 0.5 * ones(1, nPar);
    probes = repmat(mid, 3 + 2 * nPar, 1);
    probes(2, :) = 1 / 3;
    probes(3, :) = 2 / 3;
    for q = 1:nPar
        probes(2 * q + 2, q) = 1 / 3;
        probes(2 * q + 3, q) = 2 / 3;
    end
    probes = unique(probes, "rows", "stable");

    % Probe weights depend on local coordinates and degree, not physical cells.
    probeWeights = ones(size(probes, 1), size(lbls, 1));
    for q = 1:nPar
        labels = lbls(:, q).';
        axisWeights = probeWeightsAt(deg(q), probes(:, q));
        probeWeights = probeWeights .* axisWeights(:, labels + 1);
    end

    cells = helper.combRows(arrayfun(@(n) 1:n, nCell, "UniformOutput", false));
    for cellIdx = 1:size(cells, 1)
        cellSubs = cells(cellIdx, :);
        bounds = zeros(nPar, 2);
        for q = 1:nPar
            v = info.Vectors{q};
            bounds(q, :) = v(cellSubs(q):(cellSubs(q) + 1));
        end
        coeffs = helper.cellGet(vals, cellSubs);
        for p = 1:size(probes, 1)
            alpha = probes(p, :);

            % Map the forward local coordinate back into this physical cell.
            pt = bounds(:, 1).' + alpha .* (bounds(:, 2).' - bounds(:, 1).');
            actual = evalFcn(fh, pt, sz);

            % Reconstruct with the fitted Bernstein coefficients at the probe.
            recon = zeros(sz);
            for k = 1:nCoeff
                recon = recon + coeffs{k} .* probeWeights(p, k);
            end

            tol = 1e-9 * max([1, norm(actual, "fro"), norm(recon, "fro")]);
            if norm(actual - recon, "fro") > tol
                error("pdmat:NonBernsteinPolynomial", ...
                    "Function handle is not representable by the requested Bernstein degree.");
            end
        end
    end
end

function weights = probeWeightsAt(degree, alpha)
    %PROBEWEIGHTSAT Evaluate one Bernstein basis through modal recurrences.
    weights = zeros(numel(alpha), degree + 1);
    for row = 1:numel(alpha)
        point = alpha(row);
        if point == 0
            weights(row, 1) = 1;
            continue
        elseif point == 1
            weights(row, end) = 1;
            continue
        end

        mode = min(degree, floor((degree + 1) * point));
        values = zeros(1, degree + 1);
        values(mode + 1) = 1;
        for label = mode:-1:1
            values(label) = values(label + 1) * label ...
                * (1 - point) / ((degree - label + 1) * point);
        end
        for label = mode:degree - 1
            values(label + 2) = values(label + 1) * (degree - label) ...
                * point / ((label + 1) * (1 - point));
        end
        weights(row, :) = values ./ sum(values);
    end
end

function val = evalFcn(fh, pt, sz)
    %EVALFCN Evaluate and validate a pdmat function-handle payload.
    %
    %   PT contains one point per parameter dimension. The helper normalizes
    %   function-handle failures and output-shape/type failures to the
    %   pdmat:InvalidFunctionValue error used by Bernstein validation.

    args = num2cell(pt);
    try
        raw = fh(args{:});
    catch err
        error("pdmat:InvalidFunctionValue", ...
            "Function handle failed during Bernstein validation: %s", err.message);
    end

    got = scanMats({raw}, "pdmat:InvalidFunctionValue", ...
        "Each pdmat payload must be a nonempty finite real numeric matrix.");
    if ~isequal(got, sz)
        error("pdmat:InvalidFunctionValue", ...
            "Function handle must return the same matrix size throughout Bernstein validation.");
    end
    val = raw;
end
