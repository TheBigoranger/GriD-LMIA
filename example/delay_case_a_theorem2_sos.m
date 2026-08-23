% DELAY_CASE_A_THEOREM2_SOS Reproduce the simple delay theorem with SOS.
%
% Provenance
%   Source: Yicheng Xu, "Stability Analysis of Time-Varying Delay Systems
%   via Differentiable Parameter-Dependent LMIs," 2026, Theorem 2, equations
%   labeled "simple DPDLMI time delay" and "simple DPDLMI end points 1--2,"
%   Computational Setup, and the Case A comparison table.
%   Local anchors: H:\office\UCI\research\delay system\A parameter-dependent
%   LMI based integral inequality for stability analysis of time-varying
%   delay systems\root.tex, pics/case_a_comparison.csv, and
%   pics/reproduction_audit.csv. The staged numerical protocol is preserved
%   in program/+delaybench/solveModel.m and the corresponding audit rows.
%   Case A uses A=[-2 0;0 -0.9] and Ad=[-1 0;-1 -1]. The manuscript has no
%   public archive URL in its source.
%   Reproduction type: exact theorem assembly with the one-cell univariate
%   matrix Markov-Lukacs certificate implemented by useFullBox.
%
% Settings and expected result
%   tau in [0,h], dot(tau) in [-0.1,0.1], degree(P)=2, one physical cell,
%   FullBox uses absolute order 1 for P positivity and absolute order 2 for
%   the interior residual, which are their default exact univariate orders.
%   The staged solve maximizes gamma, retries the identical constraints with
%   gamma>=1e-7, retries that accepted-margin model with a trace regularizer,
%   and finally retries the original margin maximization in MOSEK dual form.
%   The audited feasible endpoint is h=3.68676263203714, which rounds to
%   3.687; its audited rejected upper endpoint is h=3.68710592863777. The
%   accepted endpoint plus h+rejectionStep is the primary planned gate; the
%   audited bracket is secondary corroboration. Literal h=3.687 is not
%   assumed feasible. Canonical reproduction uses MOSEK through YALMIP, with
%   one thread. Early-stage solver exceptions are recorded as unknown and
%   trigger the next retry; a final-stage exception remains unknown. Every
%   exception retains its MATLAB identifier and message. The latest validation
%   took 0.759 s for the accepted probe, 0.922 s for the primary planned gate,
%   and 0.095 s for the secondary audited upper endpoint. Retry behavior and
%   elapsed time remain solver- and hardware-dependent.
%
% What to tune
%   Change degree, muBar, acceptedH, rejectionStep, auditedUpperH, solver,
%   marginTol, or residualTol.
%   Changing degree or certificate changes the theorem realization and its
%   numerical boundary.

yalmip('clear');

degree = 2;
muBar = 0.1;
acceptedH = 3.68676263203714;
rejectionStep = 0.001;
auditedUpperH = 3.68710592863777;
solver = 'mosek';
marginTol = 1e-7;
residualTol = 1e-7;

accepted = solveTheorem2(acceptedH, degree, muBar, solver, ...
    marginTol, residualTol);
plannedStep = solveTheorem2(acceptedH + rejectionStep, degree, muBar, ...
    solver, marginTol, residualTol);
auditedUpper = solveTheorem2(auditedUpperH, degree, muBar, ...
    solver, marginTol, residualTol);
sourceRoundsToTable = round(acceptedH, 3) == 3.687;
rejectedClasses = ["infeasible" "noAcceptedMargin"];
plannedStepMatches = ismember(plannedStep.classification, rejectedClasses);
auditBracketMatches = accepted.accepted && ...
    ismember(auditedUpper.classification, rejectedClasses);
canonicalSolver = strcmpi(solver, 'mosek');
reproductionMatches = canonicalSolver && accepted.accepted && ...
    sourceRoundsToTable && plannedStepMatches;

fprintf('Delay Case A, Theorem 2, one-cell FullBox\n');
printResult('accepted endpoint', acceptedH, accepted);
printResult(sprintf('planned +%.6g check', rejectionStep), ...
    acceptedH + rejectionStep, plannedStep);
printResult('audited upper endpoint', auditedUpperH, auditedUpper);
fprintf('  sourceRoundsToTable=%d (published table value 3.687)\n', ...
    sourceRoundsToTable);
fprintf('  canonicalSolver=%d (MOSEK)\n', canonicalSolver);
fprintf(['  reproductionMatches=%d PRIMARY gate ' ...
    '(accepted endpoint plus h+%.6g)\n'], reproductionMatches, rejectionStep);
fprintf(['  plannedStepMatches=%d (+%.6g rejected or no accepted ' ...
    'margin)\n'], plannedStepMatches, rejectionStep);
fprintf(['  auditBracketMatches=%d SECONDARY corroboration ' ...
    '(source bracket [%.14g, %.14g])\n'], ...
    auditBracketMatches, acceptedH, auditedUpperH);
fprintf('  accepted margin threshold=%.1e\n', marginTol);

function result = solveTheorem2(h, degree, muBar, solver, ...
        marginTol, residualTol)
%SOLVETHEOREM2 Assemble and solve Theorem 2 at one fixed delay bound.
    yalmip('clear');
    sysA = [-2 0; 0 -0.9];
    sysAd = [-1 0; -1 -1];
    n = size(sysA, 1);
    grid = {[0 h]};
    rateBounds = [-muBar muBar];

    P = pdvar(n, grid, 'symmetric', Degree=degree, ...
        RateBounds=rateBounds);
    dP = rhodiff(P);
    Q1 = sdpvar(n, n, 'symmetric');
    Q2 = sdpvar(n, n, 'symmetric');
    R = sdpvar(n, n, 'symmetric');
    gamma = sdpvar(1, 1);
    tau = pdmat(grid, num2cell(grid{1}), Degree=1);
    oneMinusRate = rateConstant(grid, {1 + muBar, 1 - muBar}, ...
        rateBounds);
    Z = zeros(n);

    phi0 = [h * R, Z, Z, P; ...
        Z, -Q2, Z, Z; ...
        Z, Z, oneMinusRate * (Q2 - Q1), Z; ...
        P, Z, Z, dP + Q1];
    phi1 = [Z, Z, Z, Z; Z, -R, R, Z; ...
        Z, R, -R, Z; Z, Z, Z, Z];
    phi2 = [Z, Z, Z, Z; Z, Z, Z, Z; ...
        Z, Z, -R, R; Z, Z, R, -R];
    I = eye(n);
    NA = [zeros(n), sysAd, sysA; I, Z, Z; Z, I, Z; Z, Z, I];
    N1 = [I, Z; Z, I; Z, I];
    N2 = [I, Z; I, Z; Z, I];

    g = tau * (h - tau);
    interior = NA' * (g * phi0 + tau * phi1 + (h - tau) * phi2) * NA ...
        + gamma * g * eye(3 * n);
    pLmi = P - gamma * eye(n) >= 0;
    interiorLmi = interior <= 0;
    pCert = pLmi.useFullBox();
    interiorCert = interiorLmi.useFullBox();

    p0Coeff = P.coeffs(1);
    phCoeff = P.coeffs(1);
    dpCoeff = dP.coeffs(1);
    P0 = p0Coeff{1};
    Ph = phCoeff{end};
    lowerRates = [0 muBar];
    upperRates = [-muBar 0];
    lowerDerivatives = {zeros(n), dpCoeff{2, 1}};
    upperDerivatives = {dpCoeff{1, end}, zeros(n)};
    endpointF = [Q1 >= gamma * I, Q2 >= gamma * I, ...
        R >= gamma * I, trace(P0) == n];
    for row = 1:2
        phi00 = phi0At(lowerRates(row), P0, ...
            lowerDerivatives{row}, Q1, Q2, R, h);
        lower = N1' * NA' * (phi00 + phi1 / h) * NA * N1;
        endpointF = [endpointF, lower <= -gamma * eye(2 * n)]; %#ok<AGROW>

        phi0h = phi0At(upperRates(row), Ph, ...
            upperDerivatives{row}, Q1, Q2, R, h);
        upper = N2' * NA' * (phi0h + phi2 / h) * NA * N2;
        endpointF = [endpointF, upper <= -gamma * eye(2 * n)]; %#ok<AGROW>
    end
    F = [pCert, interiorCert, endpointF];

    opts = sdpsettings('solver', solver, 'verbose', 0, ...
        'mosek.MSK_IPAR_NUM_THREADS', 1);
    stage = runStage(F, -gamma, opts, gamma, "marginMax");
    stage = classifyMargin(stage, marginTol, residualTol, false);
    result = firstStageResult(stage);
    if ismember(result.classification, ["feasible" "infeasible"])
        return
    end

    % Retry the identical theorem model at the accepted margin threshold.
    acceptedF = [F, gamma >= marginTol];
    stage = runStage(acceptedF, [], opts, gamma, "acceptedMargin");
    stage = classifyAcceptedMargin(stage, marginTol, residualTol);
    result = appendStage(result, stage);
    if ismember(result.classification, ["feasible" "noAcceptedMargin"])
        return
    end

    % Retry the same accepted-margin model with the historical regularizer.
    regularizer = trace(Q1) + trace(Q2) + trace(R);
    stage = runStage(acceptedF, regularizer, opts, gamma, ...
        "acceptedMarginRegularized");
    stage = classifyAcceptedMargin(stage, marginTol, residualTol);
    result = appendStage(result, stage);
    if ismember(result.classification, ["feasible" "noAcceptedMargin"])
        return
    end

    % Retry the original margin maximization; MOSEK uses its dual solve form.
    if strcmpi(solver, 'mosek')
        finalOpts = sdpsettings(opts, ...
            'mosek.MSK_IPAR_INTPNT_SOLVE_FORM', 'MSK_SOLVE_DUAL');
        finalPhase = "marginMaxDualForm";
    else
        finalOpts = opts;
        finalPhase = "marginMaxRetry";
    end
    stage = runStage(F, -gamma, finalOpts, gamma, finalPhase);
    stage = classifyMargin(stage, marginTol, residualTol, true);
    result = appendStage(result, stage);
end

function stage = runStage(F, objective, opts, gamma, phase)
%RUNSTAGE Solve one retry stage and preserve exceptions as unknown results.
    started = tic;
    stage.phase = phase;
    stage.problem = NaN;
    stage.info = '';
    stage.gamma = NaN;
    stage.minResidual = NaN;
    stage.elapsed = NaN;
    stage.exceptionOccurred = false;
    stage.exceptionIdentifier = '';
    stage.exceptionMessage = '';
    stage.sourceClass = "unclassified";
    stage.classification = "unknown";
    try
        diagnostic = optimize(F, objective, opts);
        stage.elapsed = toc(started);
        stage.problem = diagnostic.problem;
        stage.info = diagnostic.info;
        if diagnostic.problem == 0
            stage.gamma = value(gamma);
            stage.minResidual = min(check(F));
        end
    catch exception
        stage.elapsed = toc(started);
        stage.info = sprintf('%s: %s', exception.identifier, ...
            exception.message);
        stage.exceptionOccurred = true;
        stage.exceptionIdentifier = exception.identifier;
        stage.exceptionMessage = exception.message;
    end
end

function stage = classifyMargin(stage, marginTol, residualTol, ...
        acceptedBoundary)
%CLASSIFYMARGIN Apply the historical marginClass rule to one stage.
    tinyTol = max(1e-10, 1e-3 * marginTol);
    residualPass = isfinite(stage.minResidual) && ...
        stage.minResidual >= -residualTol;
    if stage.exceptionOccurred
        stage.sourceClass = "exception";
    elseif stage.problem == 1
        stage.sourceClass = "infeasible";
    elseif stage.problem ~= 0
        stage.sourceClass = "problem" + string(stage.problem);
    elseif ~residualPass
        stage.sourceClass = "residualFailure";
    elseif isfinite(stage.gamma) && stage.gamma > marginTol
        stage.sourceClass = "feasible";
    elseif acceptedBoundary && isfinite(stage.gamma) && ...
            stage.gamma < marginTol - tinyTol
        stage.sourceClass = "noAcceptedMargin";
    elseif isfinite(stage.gamma) && stage.gamma < -marginTol
        stage.sourceClass = "infeasible";
    else
        stage.sourceClass = "unknownBoundary";
    end
    stage.classification = normalizeClass(stage.sourceClass);
end

function stage = classifyAcceptedMargin(stage, marginTol, residualTol)
%CLASSIFYACCEPTEDMARGIN Apply the historical acceptedMarginClass rule.
    residualPass = isfinite(stage.minResidual) && ...
        stage.minResidual >= -residualTol;
    if stage.exceptionOccurred
        stage.sourceClass = "exception";
    elseif stage.problem == 1
        stage.sourceClass = "noAcceptedMargin";
    elseif stage.problem ~= 0
        stage.sourceClass = "problem" + string(stage.problem);
    elseif ~residualPass
        stage.sourceClass = "residualFailure";
    elseif isfinite(stage.gamma) && stage.gamma >= marginTol
        stage.sourceClass = "feasible";
    else
        stage.sourceClass = "marginFailure";
    end
    stage.classification = normalizeClass(stage.sourceClass);
end

function classification = normalizeClass(sourceClass)
%NORMALIZECLASS Map audit-detail classes to the public diagnostic classes.
    if ismember(sourceClass, ...
            ["feasible" "infeasible" "noAcceptedMargin"])
        classification = sourceClass;
    else
        classification = "unknown";
    end
end

function result = firstStageResult(stage)
%FIRSTSTAGERESULT Initialize the aggregate while retaining stage evidence.
    result.stages = stage;
    result.elapsed = stage.elapsed;
    result = retainFinalStage(result, stage);
end

function result = appendStage(result, stage)
%APPENDSTAGE Append evidence and update the aggregate final-stage fields.
    result.stages(end + 1) = stage;
    result.elapsed = result.elapsed + stage.elapsed;
    result = retainFinalStage(result, stage);
end

function result = retainFinalStage(result, stage)
%RETAINFINALSTAGE Expose the latest stage without discarding prior evidence.
    result.problem = stage.problem;
    result.info = stage.info;
    result.phase = stage.phase;
    result.gamma = stage.gamma;
    result.minResidual = stage.minResidual;
    result.classification = stage.classification;
    result.accepted = stage.classification == "feasible";
    result.phaseChain = buildPhaseChain(result.stages);
end

function chain = buildPhaseChain(stages)
%BUILDPHASECHAIN Summarize normalized and source-detail classifications.
    parts = strings(1, numel(stages));
    for index = 1:numel(stages)
        part = stages(index).phase + ":" + stages(index).classification;
        if stages(index).sourceClass ~= stages(index).classification
            part = part + "/" + stages(index).sourceClass;
        end
        parts(index) = part;
    end
    chain = strjoin(parts, " > ");
end

function Phi0 = phi0At(rate, P, Pdot, Q1, Q2, R, h)
%PHI0AT Evaluate the rate-affine block at a collapsed endpoint.
    n = size(P, 1);
    Z = zeros(n);
    Phi0 = [h * R, Z, Z, P; Z, -Q2, Z, Z; ...
        Z, Z, (1 - rate) * (Q2 - Q1), Z; ...
        P, Z, Z, Pdot + Q1];
end

function out = rateConstant(grid, values, rateBounds)
%RATECONSTANT Store degree-zero values at the two rate vertices.
    leaf = reshape(values, [], 1);
    out = pdmat(grid, {leaf}, Degree=0, RateBounds=rateBounds);
end

function printResult(role, h, result)
%PRINTRESULT Print one fixed-delay solver record.
    fprintf('  %s h=%.14g: problem=%g (%s), class=%s, phase=%s\n', ...
        role, h, result.problem, result.info, result.classification, ...
        result.phase);
    fprintf('    elapsed=%.3f s, gamma=%.6g, min residual=%.3g\n', ...
        result.elapsed, result.gamma, result.minResidual);
    fprintf('    phase chain: %s\n', result.phaseChain);
    for index = 1:numel(result.stages)
        stage = result.stages(index);
        hasException = stage.exceptionOccurred;
        fprintf(['      %s: class=%s/%s, problem=%g, info=%s, ' ...
            'gamma=%.6g, residual=%.3g, elapsed=%.3f s, exception=%d\n'], ...
            stage.phase, stage.classification, stage.sourceClass, ...
            stage.problem, stage.info, stage.gamma, stage.minResidual, ...
            stage.elapsed, hasException);
        if hasException
            fprintf('        exception id=%s, message=%s\n', ...
                stage.exceptionIdentifier, stage.exceptionMessage);
        end
    end
end
