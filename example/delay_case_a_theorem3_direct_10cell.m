% DELAY_CASE_A_THEOREM3_DIRECT_10CELL Reproduce the augmented delay theorem.
%
% Provenance
%   Source: Yicheng Xu, "Stability Analysis of Time-Varying Delay Systems
%   via Differentiable Parameter-Dependent LMIs," 2026, Theorem 3, equations
%   labeled "augmented-positive," "Rhat-positive," "augmented-interior-
%   condition," and "augmented lower/upper endpoint condition,"
%   Computational Setup, and the Case A comparison table.
%   Local anchors: H:\office\UCI\research\delay system\A parameter-dependent
%   LMI based integral inequality for stability analysis of time-varying
%   delay systems\root.tex, pics/case_a_comparison.csv, and
%   pics/theorem3_boundary_audit.csv. Case A uses A=[-2 0;0 -0.9] and
%   Ad=[-1 0;-1 -1]. The manuscript has no public archive URL in its source.
%   Reproduction type: exact endpoint-augmented DPD-LMI with the paper's
%   normalized delay coordinate and ten-cell Direct Bernstein certificate.
%
% Settings and expected result
%   tau in [0,h], dot(tau) in [-0.1,0.1], Bessel-Legendre order N=3,
%   degree(P)=3, and ten physical cells. The accepted published lattice
%   point is h=5.151 and the rejected point is h=5.152. The strict margin is
%   fixed at 1e-7, as in the paper's reproduction protocol.
%   Solver: MOSEK through YALMIP, one thread. On the paper's i7-11700K
%   fixture, a nearby fixed-delay solve took about 15 s. The latest validation
%   took 17.909 s at h=5.151 and 49.695 s at h=5.152; elapsed time is solver-
%   and hardware-dependent.
%
% What to tune
%   Change N, degree, gridCells, muBar, acceptedH, rejectionStep, solver, or
%   marginTol. Changing N, degree, or gridCells changes the finite theorem
%   realization and its numerical boundary.

yalmip('clear');

N = 3;
degree = 3;
gridCells = 10;
muBar = 0.1;
acceptedH = 5.151;
rejectionStep = 0.001;
solver = 'mosek';
marginTol = 1e-7;
residualTol = 1e-7;

accepted = solveTheorem3(acceptedH, N, degree, gridCells, muBar, ...
    solver, marginTol, residualTol);
rejected = solveTheorem3(acceptedH + rejectionStep, N, degree, ...
    gridCells, muBar, solver, marginTol, residualTol);
boundaryMatches = accepted.accepted && ...
    ismember(rejected.classification, ["infeasible" "noAcceptedMargin"]);

fprintf('Delay Case A, Theorem 3, ten-cell Direct certificate\n');
printResult('accepted endpoint', acceptedH, accepted);
printResult('higher check', acceptedH + rejectionStep, rejected);
fprintf('  expected accepted/rejected pair=[5.151, 5.152], match=%d\n', ...
    boundaryMatches);

function result = solveTheorem3(h, N, degree, gridCells, muBar, ...
        solver, marginTol, residualTol)
%SOLVETHEOREM3 Assemble and solve Theorem 3 at one fixed delay bound.
    yalmip('clear');
    sys.A = [-2 0; 0 -0.9];
    sys.Ad = [-1 0; -1 -1];
    n = size(sys.A, 1);
    grid = {linspace(0, 1, gridCells + 1)};
    rateBounds = [-muBar muBar] / h;
    rates = [-muBar muBar];
    sel = makeSelectors(sys, N);
    pSize = (2 * N + 5) * n;

    P = pdvar(pSize, grid, 'symmetric', Degree=degree, ...
        RateBounds=rateBounds);
    dP = rhodiff(P);
    Q1 = sdpvar(5 * n, 5 * n, 'symmetric');
    Q2 = sdpvar(5 * n, 5 * n, 'symmetric');
    R1 = sdpvar(2 * n, 2 * n, 'symmetric');
    R2 = sdpvar(2 * n, 2 * n, 'symmetric');
    gamma = sdpvar(1, 1);

    tau = h * pdmat(grid, num2cell(grid{1}), Degree=1);
    hmTau = h - tau;
    g = tau * hmTau;
    rate = rateConstant(grid, {-muBar, muBar}, rateBounds);
    oneMinusRate = rateConstant(grid, {1 + muBar, 1 - muBar}, ...
        rateBounds);
    J = rateConstant(grid, rateMaps(sel, N, rates), rateBounds);
    G = rateConstant(grid, partialTimeMaps(sel, rates), rateBounds);
    Rhat = oneMinusRate * R1 + rate * R2;

    H = [sel.Eh; sel.Etau; sel.E0; tau * sel.E1; hmTau * sel.E2];
    phiV1 = H' * P * J + J' * P * H + H' * dP * H;
    K1 = [sel.E0 - sel.Etau; tau * sel.E1k{1}; ...
        tau * sel.Eh; tau * sel.Etau; tau * sel.E0];
    K2 = [sel.Etau - sel.Eh; hmTau * sel.E2k{1}; ...
        hmTau * sel.Eh; hmTau * sel.Etau; hmTau * sel.E0];
    phiV2 = sel.T0' * Q1 * sel.T0 - sel.Th' * Q2 * sel.Th ...
        + oneMinusRate * (sel.Ttau' * (Q2 - Q1) * sel.Ttau) ...
        + K1' * Q1 * G + G' * Q1 * K1 ...
        + K2' * Q2 * G + G' * Q2 * K2;

    phiFirst = zeros(sel.q);
    phiSecond = zeros(sel.q);
    for k = 0:N
        weight = 2 * k + 1;
        G1k = (-1)^k * sel.E0 - sel.Etau;
        G2k = (-1)^k * sel.Etau - sel.Eh;
        for j = 0:(k - 1)
            parity = (2 * j + 1) * (1 - (-1)^(k + j));
            G1k = G1k + parity * sel.E1k{j + 1};
            G2k = G2k + parity * sel.E2k{j + 1};
        end
        U1k = [G1k; tau * sel.E1k{k + 1}];
        U2k = [G2k; hmTau * sel.E2k{k + 1}];
        phiFirst = phiFirst - weight * (U1k' * Rhat * U1k);
        phiSecond = phiSecond - weight * (U2k' * R2 * U2k);
    end

    present = [sel.Edot0; sel.E0];
    phi0 = phiV1 + phiV2 ...
        + tau * (present' * R1 * present) ...
        + hmTau * (present' * R2 * present);
    fullInterior = g * phi0 + tau * phiSecond + hmTau * phiFirst;
    projected = sel.NA' * fullInterior * sel.NA;
    decay = sel.NA' * (sel.E0' * sel.E0) * sel.NA;

    pLmi = P - gamma * eye(pSize) >= 0;
    rhatLmi = Rhat - gamma * eye(2 * n) >= 0;
    interiorLmi = projected + gamma * g * decay <= 0;
    pValues = P.coeffs(1);
    endpointF = [Q1 >= gamma * eye(5 * n), ...
        Q2 >= gamma * eye(5 * n), ...
        R1 >= gamma * eye(2 * n), ...
        R2 >= gamma * eye(2 * n), ...
        trace(pValues{1}) == pSize, gamma == marginTol];

    [inj0, injh] = endpointInjections(sel, sys, N);
    endpointSize = size(inj0, 2);
    lowerRows = [0 2];
    upperRows = [1 0];
    for row = 1:2
        phi00 = endpointCoefficient(phi0, lowerRows(row), ...
            "left", gridCells);
        phi0h = endpointCoefficient(phi0, upperRows(row), ...
            "right", gridCells);
        phiSecond0 = endpointCoefficient(phiSecond, lowerRows(row), ...
            "left", gridCells);
        phiFirsth = endpointCoefficient(phiFirst, upperRows(row), ...
            "right", gridCells);
        psi0 = inj0' * (phi00 + phiSecond0 / h) * inj0;
        psih = injh' * (phi0h + phiFirsth / h) * injh;
        endpointF = [endpointF, ...
            psi0 <= -gamma * eye(endpointSize), ...
            psih <= -gamma * eye(endpointSize)]; %#ok<AGROW>
    end
    F = [pLmi, rhatLmi, interiorLmi, endpointF];

    opts = sdpsettings('solver', solver, 'verbose', 0, ...
        'mosek.MSK_IPAR_NUM_THREADS', 1);
    started = tic;
    diagnostic = optimize(F, [], opts);
    result.elapsed = toc(started);
    result.problem = diagnostic.problem;
    result.info = diagnostic.info;
    result.phase = "fixedMarginFeasibility";
    result.margin = marginTol;
    result.minResidual = NaN;
    if diagnostic.problem == 0
        result.minResidual = min(check(F));
    end
    result.accepted = diagnostic.problem == 0 && ...
        isfinite(result.minResidual) && result.minResidual >= -residualTol;
    if result.accepted
        result.classification = "feasible";
        return
    end
    if diagnostic.problem == 1
        result.classification = "infeasible";
        return
    end

    % The paper uses this uniform-slack solve only to classify an ambiguous
    % fixed-margin result. It does not replace the theorem constraints.
    [diagnosticF, eta] = uniformSlackDiagnostic(F);
    diagnosticStarted = tic;
    slackDiagnostic = optimize(diagnosticF, -eta, opts);
    result.elapsed = result.elapsed + toc(diagnosticStarted);
    result.problem = slackDiagnostic.problem;
    result.info = slackDiagnostic.info;
    result.phase = "uniformSlackDiagnostic";
    result.margin = NaN;
    result.minResidual = NaN;
    if slackDiagnostic.problem == 0
        result.margin = marginTol + value(eta);
        result.minResidual = min(check(diagnosticF));
    end
    residualPass = isfinite(result.minResidual) && ...
        result.minResidual >= -residualTol;
    tinyTol = max(1e-10, 1e-3 * marginTol);
    if slackDiagnostic.problem == 0 && residualPass && ...
            isfinite(result.margin) && result.margin < marginTol - tinyTol
        result.classification = "noAcceptedMargin";
    else
        result.classification = "unknown";
    end
end

function sel = makeSelectors(sys, N)
%MAKESELECTORS Construct the full and dynamics-projected block selectors.
    n = size(sys.A, 1);
    blockCount = 2 * N + 8;
    fullSize = blockCount * n;
    E = cell(1, blockCount);
    for block = 1:blockCount
        E{block} = pick(fullSize, (block - 1) * n + 1, n);
    end
    E1k = E(7:(N + 7));
    E2k = E((N + 8):(2 * N + 8));
    E1 = vertcat(E1k{:});
    E2 = vertcat(E2k{:});

    projectedBlocks = [n n n n n (N + 1) * n (N + 1) * n];
    projectedSize = sum(projectedBlocks);
    starts = cumsum([1 projectedBlocks(1:(end - 1))]);
    Y = cell(1, numel(projectedBlocks));
    for block = 1:numel(projectedBlocks)
        Y{block} = pick(projectedSize, starts(block), projectedBlocks(block));
    end
    NA = [Y{1}; Y{2}; sys.Ad * Y{4} + sys.A * Y{5}; ...
        Y{3}; Y{4}; Y{5}; Y{6}; Y{7}];

    sel = struct('n', n, 'q', fullSize, 'NA', NA, ...
        'Edoth', E{1}, 'Edottau', E{2}, 'Edot0', E{3}, ...
        'Eh', E{4}, 'Etau', E{5}, 'E0', E{6}, ...
        'E1', E1, 'E2', E2, 'E1k', {E1k}, 'E2k', {E2k}, ...
        'T0', [E{3}; E{6}; E{4}; E{5}; E{6}], ...
        'Ttau', [E{2}; E{5}; E{4}; E{5}; E{6}], ...
        'Th', [E{1}; E{4}; E{4}; E{5}; E{6}]);
end

function maps = rateMaps(sel, N, rates)
%RATEMAPS Build the total-derivative maps at both delay-rate vertices.
    maps = cell(numel(rates), 1);
    for row = 1:numel(rates)
        [J1, J2] = legendreRateMaps(sel, N, rates(row));
        maps{row} = [sel.Edoth; (1 - rates(row)) * sel.Edottau; ...
            sel.Edot0; J1; J2];
    end
end

function maps = partialTimeMaps(sel, rates)
%PARTIALTIMEMAPS Build the partial-time maps for the augmented moments.
    maps = cell(numel(rates), 1);
    for row = 1:numel(rates)
        maps{row} = [zeros(2 * sel.n, sel.q); sel.Edoth; ...
            (1 - rates(row)) * sel.Edottau; sel.Edot0];
    end
end

function [J1, J2] = legendreRateMaps(sel, N, rate)
%LEGENDRERATEMAPS Lift the scalar shifted-Legendre derivative operators.
    [Lambda1, Lambda2] = legendreOps(N, rate);
    identities = eye(sel.n);
    onesN = ones(N + 1, 1);
    signs = (-1) .^ (0:N)';
    J1 = kron(signs, identities) * sel.E0 ...
        - (1 - rate) * kron(onesN, identities) * sel.Etau ...
        + kron(Lambda1, identities) * sel.E1;
    J2 = (1 - rate) * kron(signs, identities) * sel.Etau ...
        - kron(onesN, identities) * sel.Eh ...
        + kron(Lambda2, identities) * sel.E2;
end

function [Lambda1, Lambda2] = legendreOps(N, rate)
%LEGENDREOPS Build shifted-Legendre derivative operators by recurrence.
    m = N + 1;
    coeff = zeros(m, m);
    coeff(1, 1) = 1;
    if N >= 1
        coeff(2, 1:2) = [1 -2];
    end
    for k = 1:(N - 1)
        term = conv([1 -2], coeff(k + 1, 1:(k + 1)));
        previous = [coeff(k, 1:k), zeros(1, 2)];
        next = ((2 * k + 1) * term - k * previous(1:numel(term))) ...
            / (k + 1);
        coeff(k + 2, 1:numel(next)) = next;
    end

    Lambda1 = zeros(m);
    Lambda2 = zeros(m);
    for k = 1:m
        degree = k - 1;
        polynomial = coeff(k, 1:(degree + 1));
        derivative = (1:degree) .* polynomial(2:end);
        if isempty(derivative)
            target1 = zeros(1, m);
            target2 = zeros(1, m);
        else
            target1 = -conv([1 - rate, rate], derivative);
            target2 = -conv([1, -rate], derivative);
        end
        target1(end + 1:m) = 0;
        target2(end + 1:m) = 0;
        Lambda1(k, :) = target1 / coeff;
        Lambda2(k, :) = target2 / coeff;
    end
    Lambda1(abs(Lambda1) < 1e-12) = 0;
    Lambda2(abs(Lambda2) < 1e-12) = 0;
end

function [J0, Jh] = endpointInjections(sel, sys, N)
%ENDPOINTINJECTIONS Enforce the collapsed physical states at tau=0 and h.
    n = sel.n;
    projectionSize = (N + 1) * n;
    endpointSize = (N + 4) * n;
    E0 = pick(endpointSize, 1, n);
    Eh = pick(endpointSize, n + 1, n);
    Edoth = pick(endpointSize, 2 * n + 1, n);
    Ez = pick(endpointSize, 3 * n + 1, projectionSize);
    e0 = kron([1; zeros(N, 1)], eye(n));
    J0 = [Edoth; (sys.A + sys.Ad) * E0; ...
        (sys.A + sys.Ad) * E0; Eh; E0; E0; e0 * E0; Ez];
    Jh = [Edoth; Edoth; sys.A * E0 + sys.Ad * Eh; ...
        Eh; Eh; E0; Ez; e0 * Eh];
end

function value = endpointCoefficient(object, row, side, cellCount)
%ENDPOINTCOEFFICIENT Extract an exact endpoint and rate-row coefficient.
    if side == "left"
        coefficients = object.coeffs(1);
        column = 1;
    else
        coefficients = object.coeffs(cellCount);
        column = size(coefficients, 2);
    end
    if object.NumRateRows == 0
        row = 1;
    end
    if row == 0
        value = (coefficients{1, column} + ...
            coefficients{2, column}) / 2;
    else
        value = coefficients{row, column};
    end
end

function out = rateConstant(grid, values, rateBounds)
%RATECONSTANT Replicate rate-vertex constants over every physical cell.
    leaf = reshape(values, [], 1);
    localValues = repmat({leaf}, 1, numel(grid{1}) - 1);
    out = pdmat(grid, localValues, Degree=0, RateBounds=rateBounds);
end

function E = pick(total, start, width)
%PICK Select one consecutive block from a stacked vector.
    E = zeros(width, total);
    E(:, start:(start + width - 1)) = eye(width);
end

function [diagnosticF, eta] = uniformSlackDiagnostic(F)
%UNIFORMSLACKDIAGNOSTIC Shift every conic residual by one common scalar.
    eta = sdpvar(1, 1);
    diagnosticF = [];
    for index = 1:length(F)
        if is(F(index), 'equality')
            diagnosticF = [diagnosticF, F(index)]; %#ok<AGROW>
            continue
        end
        residual = sdpvar(F(index));
        if is(F(index), 'sdp')
            diagnosticF = [diagnosticF, ...
                residual >= eta * eye(size(residual, 1))]; %#ok<AGROW>
        else
            diagnosticF = [diagnosticF, residual >= eta]; %#ok<AGROW>
        end
    end
end

function printResult(role, h, result)
%PRINTRESULT Print one fixed-delay solver record.
    fprintf('  %s h=%.3f: problem=%d (%s), class=%s, phase=%s\n', ...
        role, h, result.problem, result.info, result.classification, ...
        result.phase);
    fprintf('    elapsed=%.3f s, margin=%.6g, min residual=%.3g\n', ...
        result.elapsed, result.margin, result.minResidual);
end
