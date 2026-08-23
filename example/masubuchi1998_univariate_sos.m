% MASUBUCHI1998_UNIVARIATE_SOS Reproduce a short one-parameter SOS case.
%
% Provenance
%   Source: Masubuchi, Kume, and Shimemura, "Spline-Type Solution to
%   Parameter-Dependent LMIs," Proceedings of the 37th IEEE Conference on
%   Decision and Control, 1998, Example 1,
%   DOI 10.1109/CDC.1998.758549. The matrices and rate-dependent bounded-real
%   formulation follow the GriD-LMIA software paper, "Degree, grid, and
%   certificate sensitivity when ell=1." Local anchors are
%   H:\office\UCI\research\Grid LMIA\PD software paper v2\paper.tex and
%   pics/masubuchi_k2_comparison.csv in that project.
%   Reproduction type: exact model and certificate setting used by the
%   software-paper row m=1, k=2, Putinar order 5.
%
% Settings and expected result
%   theta in [0,1], dot(theta) in [-1,1], one physical cell, degree(P)=1.
%   Certificate: univariate Putinar, absolute Gram order 5.
%   Solver: SDPT3 through YALMIP. Expected gamma = 6.05101324526206 with
%   comparison tolerance 5e-4. A fresh-process validation took 78.160 s;
%   elapsed time is solver- and hardware-dependent.
%
% What to tune
%   Change decisionDegree, gramOrder, gridNodes, solver, or compareTol below.
%   A larger grid or degree changes the finite certificate and need not retain
%   the printed comparison value.

yalmip('clear');

gridNodes = 2;
decisionDegree = 1;
gramOrder = 5;
solver = 'sdpt3';
strictMargin = 1e-8;
expectedGamma = 6.05101324526206;
compareTol = 5e-4;

grid = {linspace(0, 1, gridNodes)};
A = pdmat(grid, @(theta) [-1 0.5; -1 -2] + ...
    theta * [-1.3 -20; 2 -10], Degree=1);
B = pdmat(grid, @(theta) [1 -4; -1 -1] + ...
    theta * [2.2 0.5; -6 -5], Degree=1);
C = eye(2);
D = zeros(2);

P = pdvar(2, grid, 'symmetric', Degree=decisionDegree);
gamma = sdpvar(1, 1);
dP = rhodiff(P, [-1 1]);
boundedReal = [dP + P * A + A' * P, P * B, C'; ...
    B' * P, -gamma * eye(2), D'; ...
    C, D, -gamma * eye(2)] <= 0;
certified = boundedReal.usePutinar(gramOrder);
F = [certified, P >= strictMargin * eye(2), gamma >= 0];

opts = sdpsettings('solver', solver, 'verbose', 0, 'removeequalities', 1);
started = tic;
diagnostic = optimize(F, gamma, opts);
elapsed = toc(started);
classification = classifyDiagnostic(diagnostic);

gammaValue = NaN;
minResidual = NaN;
matchesSource = false;
if diagnostic.problem == 0
    gammaValue = value(gamma);
    residuals = check(F);
    minResidual = min(residuals);
    matchesSource = abs(gammaValue - expectedGamma) <= compareTol;
end

fprintf('Masubuchi 1998 univariate SOS\n');
fprintf('  solver=%s, problem=%d (%s), classification=%s\n', ...
    solver, diagnostic.problem, diagnostic.info, classification);
fprintf('  elapsed=%.3f s, gamma=%.9g, min residual=%.3g\n', ...
    elapsed, gammaValue, minResidual);
fprintf('  source gamma=%.9g, tolerance=%.1e, match=%d\n', ...
    expectedGamma, compareTol, matchesSource);

function label = classifyDiagnostic(diagnostic)
%CLASSIFYDIAGNOSTIC Keep infeasibility separate from numerical uncertainty.
    if diagnostic.problem == 0
        label = "feasible";
    elseif diagnostic.problem == 1
        label = "infeasible";
    else
        label = "unknown";
    end
end
