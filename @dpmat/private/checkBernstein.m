function vals = checkBernstein(fh, info, deg, sz)
    %CHECKBERNSTEIN Validate a function handle as local Bernstein data.
    %
    %   Syntax:
    %     vals = checkBernstein(fh, gridInfo, degree, matrixSize)
    %
    %   Example:
    %     info = internal.mkGrid({[0 1]}, "dpmat");
    %     vals = checkBernstein(@(rho) rho, info, 1, [1 1]);

    nPar = numel(info.Vectors);
    nCell = info.NumNodes - 1;
    [vals, lbls] = fitVals(info, deg, sz, @(pt) evalFun(fh, pt, sz));
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
                            high = simplify(diff(entry, xs(p), deg + 1));
                            tf = isAlways(high == 0);
                            if isempty(tf) || ~all(tf(:))
                                error("dpmat:NonBernsteinPolynomial", ...
                                    "Function handle is not representable by the requested Bernstein degree.");
                            end
                        end
                    end
                end
                symOk = true;
            end
        catch err
            if strcmp(err.identifier, "dpmat:NonBernsteinPolynomial")
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

    cells = internal.combRows(arrayfun(@(n) 1:n, nCell, "UniformOutput", false));
    for cellIdx = 1:size(cells, 1)
        cellSubs = cells(cellIdx, :);
        bounds = zeros(nPar, 2);
        for q = 1:nPar
            v = info.Vectors{q};
            bounds(q, :) = v(cellSubs(q):(cellSubs(q) + 1));
        end
        coeffs = internal.cellGet(vals, cellSubs);
        for p = 1:size(probes, 1)
            alpha = probes(p, :);

            % alpha=1 is the lower face and alpha=0 is the upper face.
            pt = bounds(:, 1).' + (1 - alpha) .* (bounds(:, 2).' - bounds(:, 1).');
            actual = evalFun(fh, pt, sz);

            % Reconstruct with the fitted Bernstein coefficients at the probe.
            recon = zeros(sz);
            for k = 1:nCoeff
                w = 1;
                for q = 1:nPar
                    j = lbls(k, q);
                    w = w * nchoosek(deg, j) * alpha(q)^(deg - j) * (1 - alpha(q))^j;
                end
                recon = recon + coeffs{k} .* w;
            end

            tol = 1e-9 * max([1, norm(actual, "fro"), norm(recon, "fro")]);
            if norm(actual - recon, "fro") > tol
                error("dpmat:NonBernsteinPolynomial", ...
                    "Function handle is not representable by the requested Bernstein degree.");
            end
        end
    end
end

function val = evalFun(fh, pt, sz)
    %EVALFUN Evaluate and validate a dpmat function-handle payload.

    args = num2cell(pt);
    try
        raw = fh(args{:});
    catch err
        error("dpmat:InvalidFunctionValue", ...
            "Function handle failed during Bernstein validation: %s", err.message);
    end

    got = helper.scanMats({raw}, "dpmat:InvalidFunctionValue", ...
        "Each dpmat payload must be a nonempty finite real numeric matrix.");
    if ~isequal(got, sz)
        error("dpmat:InvalidFunctionValue", ...
            "Function handle must return the same matrix size throughout Bernstein validation.");
    end
    val = raw;
end
