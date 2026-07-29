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
    [vals, lbls] = fitVals(info, deg, sz, @(pt) evalFcn(fh, pt, sz));
    nCoeff = size(lbls, 1);

    symOk = false;
    if exist("sym", "file") == 2
        try
            xs = sym("x", [1 nPar], "real");
            args = num2cell(xs);
            raw = fh(args{:});
            if isequal(size(raw), sz)
                raw = sym(raw);
                for r = 1:sz(1)
                    for c = 1:sz(2)
                        entry = raw(r, c);
                        for p = 1:nPar
                            high = simplify(diff(entry, xs(p), deg(p) + 1));
                            tf = isAlways(high == 0);
                            if isempty(tf) || ~all(tf(:))
                                error("pdmat:NonBernsteinPolynomial", ...
                                    "Function handle is not representable by the requested Bernstein degree.");
                            end
                        end
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
    probes = mid;
    probes(end + 1, :) = (1 / 3) * ones(1, nPar);
    probes(end + 1, :) = (2 / 3) * ones(1, nPar);
    for q = 1:nPar
        lo = mid;
        lo(q) = 1 / 3;
        hi = mid;
        hi(q) = 2 / 3;
        probes(end + 1, :) = lo;
        probes(end + 1, :) = hi;
    end
    probes = unique(probes, "rows", "stable");

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
                w = 1;
                for q = 1:nPar
                    j = lbls(k, q);
                    oneDeg = deg(q);
                    w = w * nchoosek(oneDeg, j) * ...
                        (1 - alpha(q))^(oneDeg - j) * alpha(q)^j;
                end
                recon = recon + coeffs{k} .* w;
            end

            tol = 1e-9 * max([1, norm(actual, "fro"), norm(recon, "fro")]);
            if norm(actual - recon, "fro") > tol
                error("pdmat:NonBernsteinPolynomial", ...
                    "Function handle is not representable by the requested Bernstein degree.");
            end
        end
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
