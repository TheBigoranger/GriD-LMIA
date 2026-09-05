% LPV_L2_GAIN_THREE_PARAMETER Reproduce the three-parameter LPV gain case.
%
% Provenancev
%   Source: Agulhari, Felipe, Oliveira, and Peres, "Algorithm 998: The Robust
%   LMI Parser---A Toolbox to Construct LMI Conditions for Uncertain
%   Systems," ACM Transactions on Mathematical Software, 45(3), 2019,
%   DOI 10.1145/3323925, and the ROLMIP manual, §7.2, Algorithm 1. The same
%   case supplies the plant and manual example. The rate-dependent DPD-LMI
%   formulation and gamma=1.69895266198667 comparison row are from the
%   GriD-LMIA software paper, three-parameter numerical study.
%   Official toolbox pages: https://rolmip.github.io/ and
%   https://github.com/agulhari/ROLMIP
%   Reproduction type: exact plant and rate-dependent bounded-real model,
%   translated from ROLMIP to the GriD-LMIA Direct certificate.
%
% Settings and expected result
%   theta1 in [2/3,2], theta2 in [0.8,4/3], theta3 in [1,3]. Their rate
%   bounds are [-1,1], [-0.4,0.4], and [-0.5,0.5]. The default uses one
%   physical cell per axis and degree(P)=[1 1 1].
%   Certificate: Direct. Solver: SDPT3 through YALMIP.
%   Expected gamma = 1.69895266198667 with tolerance 5e-4. A fresh-process
%   validation took 1.856 s; elapsed time is solver- and hardware-dependent.
%
% What to tune
%   Change gridNodes, decisionDegree, solver, strictMargin, or compareTol.
%   Increasing one grid count refines only that parameter direction.

yalmip('clear');

gridNodes = [2 2 2];
decisionDegree = [1 1 1];
solver = 'sdpt3';
strictMargin = 1e-8;
expectedGamma = 1.69895266198667;
compareTol = 5e-4;

grid = {linspace(2/3, 2, gridNodes(1)), ...
    linspace(0.8, 4/3, gridNodes(2)), ...
    linspace(1, 3, gridNodes(3))};
Afun = @(t1, t2, t3) [0 0 1 0; 0 0 0 1; ...
    -2*t1 t1 -t1*t3 0; t2 -t2 0 -t2*t3];
Bfun = @(t1, t2, t3) [0; 0; t1; 0];
A = pdmat(grid, Afun, Degree=[1 1 1]);
B = pdmat(grid, Bfun, Degree=[1 0 0]);
C = [0 1 0 0];
D = 0;

P = pdvar(4, grid, 'symmetric', Degree=decisionDegree);
gamma = sdpvar(1, 1);
dP = rhodiff(P, [-1 1; -0.4 0.4; -0.5 0.5]);
boundedReal = [dP + P * A + A' * P, P * B, C'; ...
    B' * P, -gamma, D'; ...
    C, D, -gamma] <= 0;
F = [boundedReal, P >= strictMargin * eye(4), gamma >= 0];

opts = sdpsettings('solver', solver, 'verbose', 0);
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

fprintf('Agulhari three-parameter Direct certificate\n');
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
