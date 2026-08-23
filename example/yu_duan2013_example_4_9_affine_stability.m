% YU_DUAN2013_EXAMPLE_4_9_AFFINE_STABILITY Reproduce textbook Example 4.9.
%
% Provenance
%   Source: Hai-Hua Yu and Guangren Duan, LMIs in Control Systems: Analysis,
%   Design and Applications, CRC Press, 2013, Example 4.9 and LMI (4.30),
%   ISBN 978-1-4665-8300-9. Local source:
%   H:\office\UCI\research\paper reading\LMI in control\Yu, Hai-Hua_ Duan,
%   Guangren - LMIs in control systems _ analysis, design and applications
%   (2013, CRC Press) - libgen.lc.pdf.
%   Reproduction type: exact affine system and constant common quadratic
%   Lyapunov certificate, translated from the MATLAB LMI Toolbox to
%   GriD-LMIA.
%
% Settings and expected result
%   delta1 in [-0.1,0.1], one physical cell, no RateBounds, degree(P)=0, Direct
%   certificate. The source reports a positive matrix P and concludes
%   quadratic Hurwitz stability. This script also checks the printed source
%   matrix by its minimum endpoint residual. Solver: SDPT3. A fresh-process
%   validation took 1.284 s; elapsed time is solver- and hardware-dependent.
%
% What to tune
%   Change deltaBounds, solver, or the trace normalization. A parameter-
%   dependent P would test a different condition from Example 4.9.

yalmip('clear');

deltaBounds = [-0.1 0.1];
solver = 'sdpt3';
A0 = [-3 0 1; 0 -3 0; 1 0 -4];
A1 = [1 0 1; 0 -1 0; 0 1 1];
sourceP = [0.2623 0 0.0677; 0 0.2393 0.0001; ...
    0.0677 0.0001 0.1944];

grid = {deltaBounds};
A = pdmat(grid, @(delta1) A0 + delta1 * A1, Degree=1);
P = pdvar(3, grid, 'symmetric', Degree=0);
eta = sdpvar(1, 1);
stability = A' * P + P * A <= -eta * eye(3);
positive = P >= eta * eye(3);
pCoeff = P.coeffs(1);
F = [stability, positive, trace(pCoeff{1}) == 1];

opts = sdpsettings('solver', solver, 'verbose', 0);
started = tic;
diagnostic = optimize(F, -eta, opts);
elapsed = toc(started);
classification = classifyDiagnostic(diagnostic);

etaValue = NaN;
minResidual = NaN;
if diagnostic.problem == 0
    etaValue = value(eta);
    minResidual = min(check(F));
end
sourceMargins = [min(eig(sourceP)), ...
    min(eig(-(A0 + deltaBounds(1) * A1)' * sourceP - ...
        sourceP * (A0 + deltaBounds(1) * A1))), ...
    min(eig(-(A0 + deltaBounds(2) * A1)' * sourceP - ...
        sourceP * (A0 + deltaBounds(2) * A1)))];
sourceCertificatePasses = min(sourceMargins) > 0;

fprintf('Yu and Duan 2013, Example 4.9\n');
fprintf('  solver=%s, problem=%d (%s), classification=%s\n', ...
    solver, diagnostic.problem, diagnostic.info, classification);
fprintf('  elapsed=%.3f s, optimized margin=%.6g, min residual=%.3g\n', ...
    elapsed, etaValue, minResidual);
fprintf('  printed-P minimum endpoint margin=%.6g, source check=%d\n', ...
    min(sourceMargins), sourceCertificatePasses);

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
