% YU_DUAN2013_EXAMPLE_4_10_MASS_SPRING_DAMPER Reproduce Example 4.10.
%
% Provenance
%   Source: Hai-Hua Yu and Guangren Duan, LMIs in Control Systems: Analysis,
%   Design and Applications, CRC Press, 2013, Example 4.10, equations
%   (4.33)-(4.35), ISBN 978-1-4665-8300-9. Local source:
%   H:\office\UCI\research\paper reading\LMI in control\Yu, Hai-Hua_ Duan,
%   Guangren - LMIs in control systems _ analysis, design and applications
%   (2013, CRC Press) - libgen.lc.pdf. The model is attributed there to
%   Gahinet et al. (1996) and Yu (2002).
%   Reproduction type: exact unit-mass model and both parameter boxes from
%   the textbook, translated to a two-parameter Direct certificate.
%
% Settings and expected result
%   One physical cell is used along each parameter axis. RateBounds are not
%   used, and degree(P)=[0 0] gives one constant common quadratic matrix.
%   The box k in [9.51,12.49], d in [0.451,0.749] is certified. The box
%   k in [4,8], d in [0.1,0.3] is not certified by this common quadratic
%   condition. The latter statement does not say that each frozen system is
%   unstable. Solver: SDPT3. Both solves were short in the validation run;
%   elapsed time is solver- and hardware-dependent.
%
% What to tune
%   Change the two boxes, solver, or decisionDegree. A positive degree tests
%   a parameter-dependent certificate and is not the textbook condition.

yalmip('clear');

solver = 'sdpt3';
decisionDegree = [0 0];
certifiedBox = [9.51 12.49; 0.451 0.749];
nonCertifiedBox = [4 8; 0.1 0.3];
sourceP = [26.7632 0.5439; 0.5439 2.4332];

certified = solveBox(certifiedBox, decisionDegree, solver);
nonCertified = solveBox(nonCertifiedBox, decisionDegree, solver);
sourceMargin = printedCertificateMargin(sourceP, certifiedBox);

fprintf('Yu and Duan 2013, Example 4.10\n');
fprintf(['  certified box: problem=%d (%s), class=%s, eta=%.6g, ' ...
    'residual=%.3g, elapsed=%.3f s\n'], certified.problem, ...
    certified.info, certified.classification, certified.eta, ...
    certified.minResidual, certified.elapsed);
fprintf(['  non-certified box: problem=%d (%s), class=%s, eta=%.6g, ' ...
    'residual=%.3g, elapsed=%.3f s\n'], nonCertified.problem, ...
    nonCertified.info, nonCertified.classification, nonCertified.eta, ...
    nonCertified.minResidual, nonCertified.elapsed);
fprintf('  printed-P minimum vertex margin=%.6g, source check=%d\n', ...
    sourceMargin, sourceMargin > 0);
certifiedMatch = certified.classification == "solved" && ...
    isfinite(certified.eta) && certified.eta > 0;
nonCertifiedMatch = nonCertified.classification == "infeasible" || ...
    (nonCertified.classification == "solved" && ...
    isfinite(nonCertified.eta) && nonCertified.eta <= 1e-7);
fprintf('  conclusion match=%d\n', certifiedMatch && nonCertifiedMatch);

function result = solveBox(bounds, degree, solver)
%SOLVEBOX Maximize a normalized common quadratic stability margin.
    yalmip('clear');
    grid = {bounds(1, :), bounds(2, :)};
    A = pdmat(grid, @(k, d) [0 1; -k -d], Degree=[1 1]);
    P = pdvar(2, grid, 'symmetric', Degree=degree);
    eta = sdpvar(1, 1);
    stability = A' * P + P * A <= -eta * eye(2);
    positive = P >= eta * eye(2);
    pCoeff = P.coeffs([1 1]);
    F = [stability, positive, trace(pCoeff{1}) == 1];
    opts = sdpsettings('solver', solver, 'verbose', 0);
    started = tic;
    diagnostic = optimize(F, -eta, opts);
    result.elapsed = toc(started);
    result.problem = diagnostic.problem;
    result.info = diagnostic.info;
    result.classification = classifyDiagnostic(diagnostic);
    result.eta = NaN;
    result.minResidual = NaN;
    if diagnostic.problem == 0
        result.eta = value(eta);
        result.minResidual = min(check(F));
    end
end

function margin = printedCertificateMargin(P, bounds)
%PRINTEDCERTIFICATEMARGIN Check the textbook matrix at all four vertices.
    margin = min(eig(P));
    for k = bounds(1, :)
        for d = bounds(2, :)
            A = [0 1; -k -d];
            margin = min(margin, min(eig(-(A' * P + P * A))));
        end
    end
end

function label = classifyDiagnostic(diagnostic)
%CLASSIFYDIAGNOSTIC Keep infeasibility separate from numerical uncertainty.
    if diagnostic.problem == 0
        label = "solved";
    elseif diagnostic.problem == 1
        label = "infeasible";
    else
        label = "unknown";
    end
end
