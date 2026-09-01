% DISCRETE_TIME_ROBUST_STABILITY Reproduce a discrete-time robust-stability case.
%
% Provenance
%   Source: ROLMIP User's Manual, §7.1, "Robust Stability Analysis," and
%   manual_examples/example_Section_7_1.m in the official ROLMIP package.
%   URLs: https://rolmip.github.io/ and
%   https://github.com/agulhari/ROLMIP
%   Reproduction type: exact two-vertex discrete-time system translated to
%   the scalar interval alpha2 in [0,1], with alpha1=1-alpha2.
%
% Settings and expected result
%   One parameter, one physical cell, affine P, Direct certificate, and no
%   RateBounds. The
%   ROLMIP manual reports strictly positive primal residuals 0.17957,
%   0.12168, and 0.056108. The decision matrix is nonunique, so this script
%   compares the positive optimized margin rather than matrix entries.
%   Solver: SeDuMi through YALMIP. A fresh-process validation took 7.889 s;
%   elapsed time is solver- and hardware-dependent.
%
% What to tune
%   Change decisionDegree or solver. Keep decisionDegree=1 for the manual's
%   affine Lyapunov matrix and retain the trace normalization when optimizing
%   the common margin.

yalmip('clear');

decisionDegree = 1;
solver = 'sedumi';
sourceMinResidual = 0.056108;

A1 = [0.1 0.9; 0 0.1];
A2 = [0.5 0; 1 0.5];
grid = {[0 1]};
A = pdmat(grid, @(alpha2) (1 - alpha2) * A1 + alpha2 * A2, ...
    Degree=1);
P = pdvar(2, grid, 'symmetric', Degree=decisionDegree);
eta = sdpvar(1, 1);
blockLmi = [P, A' * P; P * A, P] >= eta * eye(4);
pCoeff = P.coeffs(1);
normalization = trace(pCoeff{1}) + trace(pCoeff{2}) == 2;
F = [blockLmi, normalization];

opts = sdpsettings('solver', solver, 'verbose', 0);
started = tic;
diagnostic = optimize(F, -eta, opts);
elapsed = toc(started);
classification = classifyDiagnostic(diagnostic);

etaValue = NaN;
minResidual = NaN;
strictlyFeasible = false;
if diagnostic.problem == 0
    etaValue = value(eta);
    residuals = check(F);
    minResidual = min(residuals);
    strictlyFeasible = etaValue > 0 && minResidual >= -1e-7;
end

fprintf('ROLMIP manual Section 7.1 discrete-time stability\n');
fprintf('  solver=%s, problem=%d (%s), classification=%s\n', ...
    solver, diagnostic.problem, diagnostic.info, classification);
fprintf('  elapsed=%.3f s, optimized margin=%.6g, min residual=%.3g\n', ...
    elapsed, etaValue, minResidual);
fprintf('  source minimum residual=%.6g, strict-feasibility match=%d\n', ...
    sourceMinResidual, strictlyFeasible);

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
