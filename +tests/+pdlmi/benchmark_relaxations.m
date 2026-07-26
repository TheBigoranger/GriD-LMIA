function result = benchmark_relaxations(parameterDimension, bandWidths)
    %BENCHMARK_RELAXATIONS Compare PD-LMI relaxations from the root example.
    %
    %   result = tests.pdlmi.benchmark_relaxations() solves a two-parameter
    %   extension of the root test.m block-PD-LMI for P degrees 1:2 at two
    %   grid nodes. Pass parameterDimension=1 to run the original
    %   one-parameter sweep (degrees 1:5 and grid-node counts 2:6). It plots
    %   the optimal H-infinity gamma for direct coefficients, Polya elevation
    %   one, Putinar, selected SparseFullBox widths, and FullBox. The optional
    %   bandWidths input defaults to [1 2 3]. Solver failures remain NaN and
    %   fail the final sparse-hierarchy sanity gate before results are returned.
    %   result.complexity records raw and equality-reduced sizes for every
    %   (m, grid-node count). result.gammaMatchedComplexity compares the
    %   least costly cases that attain each common gamma target within 7%.

    if nargin < 1
        parameterDimension = 2;
    end
    parameterDimension = double(helper.chk(parameterDimension, ...
        "pdlmi:InvalidBenchmarkDimension", ...
        "parameterDimension must be the integer 1 or 2.", ...
        "numeric", "real", "finite", "integer", "scalar"));
    if ~ismember(parameterDimension, [1, 2])
        error("pdlmi:InvalidBenchmarkDimension", ...
            "parameterDimension must be the integer 1 or 2.");
    end
    if nargin < 2
        bandWidths = [1 2 3];
    end
    if ~isnumeric(bandWidths) || ~isreal(bandWidths) || ...
            isempty(bandWidths) || ~isvector(bandWidths) || ...
            any(~isfinite(bandWidths)) || any(mod(bandWidths, 1) ~= 0) || ...
            any(bandWidths <= 0)
        error("pdlmi:InvalidBenchmarkBandWidths", ...
            "bandWidths must be a nonempty vector of positive finite integers.");
    end
    bandWidths = unique(reshape(double(bandWidths), 1, []), "stable");

    if parameterDimension == 1
        degrees = 1:5;
        gridCounts = 2:6;
    else
        % Two-dimensional dense certificates grow quickly. Keep only the
        % smallest degree/grid cases that exercise an intermediate sparse
        % level and its canonical dense endpoint.
        degrees = 1:2;
        gridCounts = 2;
    end
    sparseNames = "SparseFullBox_b" + string(bandWidths);
    relaxations = ["Direct", "Polya", "Putinar", sparseNames, "FullBox"];
    relaxationWidths = [NaN NaN NaN bandWidths NaN];
    opts = solver_options();

    gammaValues = NaN(numel(degrees), numel(gridCounts), numel(relaxations));
    problemCodes = NaN(size(gammaValues));
    variableCounts = NaN(size(gammaValues));
    constraintCounts = NaN(size(gammaValues));
    freeVariableCounts = NaN(size(gammaValues));
    equalityScalarCounts = NaN(size(gammaValues));
    equalityRanks = NaN(size(gammaValues));
    psdConstraintCounts = NaN(size(gammaValues));
    maximumPsdDimensions = NaN(size(gammaValues));
    assemblyTimes = NaN(size(gammaValues));
    solveTimes = NaN(size(gammaValues));
    effectiveFamilies = strings(size(gammaValues));
    totalCases = numel(relaxations) * numel(degrees) * numel(gridCounts);
    caseIndex = 0;
    for relaxIdx = 1:numel(relaxations)
        for degreeIdx = 1:numel(degrees)
            for gridIdx = 1:numel(gridCounts)
                caseIndex = caseIndex + 1;
                fprintf(1, ['Benchmark START %d/%d: relaxation=%s, degree=%d, ' ...
                    'gridCount=%d, parameterDimension=%d\n'], ...
                    caseIndex, totalCases, char(relaxations(relaxIdx)), ...
                    degrees(degreeIdx), gridCounts(gridIdx), ...
                    parameterDimension);
                drawnow;
                skipPutinar = parameterDimension == 2 && ...
                    degrees(degreeIdx) > 1 && relaxations(relaxIdx) == "Putinar";
                skipFullBox = parameterDimension == 2 && ...
                    degrees(degreeIdx) > 1 && relaxations(relaxIdx) == "FullBox";
                if skipPutinar || skipFullBox
                    % Sparse width three already canonical-dispatches to the
                    % same dense FullBox at degree two, so avoid a duplicate
                    % expensive solve. Putinar is omitted at that level too.
                    effectiveFamilies(degreeIdx, gridIdx, relaxIdx) = "Skipped";
                    if skipPutinar
                        reason = "2D degree>1 Putinar omitted";
                    else
                        reason = "duplicate dense FullBox endpoint omitted";
                    end
                    fprintf(1, ['Benchmark SKIP  %d/%d: relaxation=%s, degree=%d, ' ...
                        'gridCount=%d, parameterDimension=%d, reason=%s\n'], ...
                        caseIndex, totalCases, char(relaxations(relaxIdx)), ...
                        degrees(degreeIdx), gridCounts(gridIdx), ...
                        parameterDimension, char(reason));
                    drawnow;
                    continue
                end
                [gammaValues(degreeIdx, gridIdx, relaxIdx), ...
                    problemCodes(degreeIdx, gridIdx, relaxIdx), ...
                    variableCounts(degreeIdx, gridIdx, relaxIdx), ...
                    constraintCounts(degreeIdx, gridIdx, relaxIdx), ...
                    freeVariableCounts(degreeIdx, gridIdx, relaxIdx), ...
                    equalityScalarCounts(degreeIdx, gridIdx, relaxIdx), ...
                    equalityRanks(degreeIdx, gridIdx, relaxIdx), ...
                    psdConstraintCounts(degreeIdx, gridIdx, relaxIdx), ...
                    maximumPsdDimensions(degreeIdx, gridIdx, relaxIdx), ...
                    effectiveFamilies(degreeIdx, gridIdx, relaxIdx), ...
                    assemblyTimes(degreeIdx, gridIdx, relaxIdx), ...
                    solveTimes(degreeIdx, gridIdx, relaxIdx)] = solve_case( ...
                    degrees(degreeIdx), gridCounts(gridIdx), ...
                    relaxations(relaxIdx), relaxationWidths(relaxIdx), ...
                    opts, parameterDimension);
                fprintf(1, ['Benchmark DONE  %d/%d: relaxation=%s, degree=%d, ' ...
                    'gridCount=%d, parameterDimension=%d, problem=%g, ' ...
                    'gamma=%.9g, effectiveFamily=%s, assemblyTime=%.3fs, ' ...
                    'solveTime=%.3fs\n'], ...
                    caseIndex, totalCases, char(relaxations(relaxIdx)), ...
                    degrees(degreeIdx), gridCounts(gridIdx), ...
                    parameterDimension, ...
                    problemCodes(degreeIdx, gridIdx, relaxIdx), ...
                    gammaValues(degreeIdx, gridIdx, relaxIdx), ...
                    char(effectiveFamilies(degreeIdx, gridIdx, relaxIdx)), ...
                    assemblyTimes(degreeIdx, gridIdx, relaxIdx), ...
                    solveTimes(degreeIdx, gridIdx, relaxIdx));
                drawnow;
            end
        end
    end

    validValues = gammaValues(isfinite(gammaValues));
    assert(~isempty(validValues), ...
        "pdlmi:RelaxationBenchmarkFailed", ...
        "No relaxation benchmark instance was solved successfully.");
    zLimits = [min(validValues), max(validValues)];
    if zLimits(1) == zLimits(2)
        zLimits = zLimits + [-0.1, 0.1];
    end

    figure(Name="PD-LMI relaxation comparison");
    tileColumns = ceil(sqrt(numel(relaxations)));
    tileRows = ceil(numel(relaxations) / tileColumns);
    layout = tiledlayout(tileRows, tileColumns, ...
        TileSpacing="compact", Padding="compact");
    title(layout, "Root test.m H-infinity example: optimal gamma");
    for relaxIdx = 1:numel(relaxations)
        nexttile;
        if numel(gridCounts) == 1
            plot(degrees, gammaValues(:, 1, relaxIdx), "-o");
            xlabel("P degree m");
            ylabel("Optimal gamma");
            ylim(zLimits);
            grid on;
        else
            surf(gridCounts, degrees, gammaValues(:, :, relaxIdx), ...
                EdgeColor="none");
            xlabel("Grid node count");
            ylabel("P degree m");
            zlabel("Optimal gamma");
            zlim(zLimits);
            clim(zLimits);
            colorbar;
            view(3);
        end
        title(relaxations(relaxIdx));
    end
    drawnow;

    [complexity, complexityByRelaxation] = complexity_tables( ...
        degrees, gridCounts, relaxations, gammaValues, variableCounts, ...
        constraintCounts, freeVariableCounts, equalityScalarCounts, ...
        equalityRanks, psdConstraintCounts, maximumPsdDimensions, ...
        assemblyTimes, solveTimes, effectiveFamilies);
    gammaTolerance = 0.07;
    sanity = sparse_hierarchy_sanity( ...
        bandWidths, gammaValues, problemCodes, effectiveFamilies);
    assert(sanity.passed, "pdlmi:SparseBenchmarkSanityFailed", ...
        "%s", strjoin(sanity.failures, newline));
    result = struct( ...
        "degrees", degrees, ...
        "gridCounts", gridCounts, ...
        "parameterDimension", parameterDimension, ...
        "bandWidths", bandWidths, ...
        "relaxations", relaxations, ...
        "gamma", gammaValues, ...
        "problem", problemCodes, ...
        "effectiveFamily", effectiveFamilies, ...
        "assemblyTime", assemblyTimes, ...
        "solveTime", solveTimes, ...
        "decisionVariableCount", variableCounts, ...
        "freeDecisionVariableCount", freeVariableCounts, ...
        "psdConstraintCount", psdConstraintCounts, ...
        "maximumPsdDimension", maximumPsdDimensions, ...
        "sparseHierarchySanity", sanity, ...
        "complexity", complexity, ...
        "complexityByRelaxation", complexityByRelaxation, ...
        "gammaTolerance", gammaTolerance, ...
        "gammaMatchedComplexity", gamma_matched_complexity( ...
        degrees, gridCounts, relaxations, gammaValues, ...
        freeVariableCounts, psdConstraintCounts, gammaTolerance));
end

function sanity = sparse_hierarchy_sanity( ...
    bandWidths, gammaValues, problemCodes, effectiveFamilies)
    % Check only solved values, then lock Direct/dense endpoints and nesting.
    sparseIndices = 4:(3 + numel(bandWidths));
    directIndex = 1;
    fullIndex = size(gammaValues, 3);
    failures = strings(0, 1);
    tolerance = 5e-4;

    for degreeIdx = 1:size(gammaValues, 1)
        for gridIdx = 1:size(gammaValues, 2)
            directCode = problemCodes(degreeIdx, gridIdx, directIndex);
            sparseCodes = reshape( ...
                problemCodes(degreeIdx, gridIdx, sparseIndices), 1, []);
            if directCode ~= 0 || any(sparseCodes ~= 0)
                failures(end + 1, 1) = sprintf( ... %#ok<AGROW>
                    "degree index %d, grid index %d has Direct/Sparse solver codes %s", ...
                    degreeIdx, gridIdx, ...
                    mat2str([directCode, sparseCodes]));
                continue
            end

            directValue = gammaValues(degreeIdx, gridIdx, directIndex);
            sparseValues = reshape( ...
                gammaValues(degreeIdx, gridIdx, sparseIndices), 1, []);
            effective = reshape( ...
                effectiveFamilies(degreeIdx, gridIdx, sparseIndices), 1, []);
            denseWidths = find(effective == "FullBox");
            if isempty(denseWidths)
                failures(end + 1, 1) = sprintf( ... %#ok<AGROW>
                    "degree index %d, grid index %d has no dense endpoint", ...
                    degreeIdx, gridIdx);
                continue
            end

            fullCode = problemCodes(degreeIdx, gridIdx, fullIndex);
            fullFamily = effectiveFamilies(degreeIdx, gridIdx, fullIndex);
            if fullCode == 0
                denseReference = gammaValues(degreeIdx, gridIdx, fullIndex);
            elseif fullFamily == "Skipped"
                % A saturated Sparse width is the actual FullBox formulation,
                % so it is the dense reference when the duplicate is omitted.
                denseReference = sparseValues(denseWidths(1));
            else
                failures(end + 1, 1) = sprintf( ... %#ok<AGROW>
                    "degree index %d, grid index %d has FullBox solver code %g", ...
                    degreeIdx, gridIdx, fullCode);
                continue
            end

            scale = max(1, max(abs( ...
                [directValue, sparseValues, denseReference])));
            absoluteTolerance = tolerance * scale;

            widthOne = find(bandWidths == 1);
            if ~isempty(widthOne) && any(abs( ...
                    sparseValues(widthOne) - directValue) > absoluteTolerance)
                failures(end + 1, 1) = sprintf( ... %#ok<AGROW>
                    "degree index %d, grid index %d misses Direct endpoint", ...
                    degreeIdx, gridIdx);
            end

            if any(abs(sparseValues(denseWidths) - denseReference) > ...
                    absoluteTolerance)
                failures(end + 1, 1) = sprintf( ... %#ok<AGROW>
                    "degree index %d, grid index %d misses FullBox endpoint", ...
                    degreeIdx, gridIdx);
            end

            [~, order] = sort(bandWidths);
            ordered = sparseValues(order);
            if any(diff(ordered) > absoluteTolerance) || ...
                    any(ordered < denseReference - absoluteTolerance)
                failures(end + 1, 1) = sprintf( ... %#ok<AGROW>
                    "degree index %d, grid index %d violates hierarchy order", ...
                    degreeIdx, gridIdx);
            end
        end
    end

    sanity = struct("passed", isempty(failures), ...
        "tolerance", tolerance, "failures", failures);
end

function [gammaValue, problem, variableCount, constraintCount, ...
    freeVariableCount, equalityScalarCount, equalityRank, psdConstraintCount, ...
    maximumPsdDimension, effectiveFamily, assemblyTime, solveTime] = solve_case( ...
    degree, gridCount, relaxation, bandWidth, opts, parameterDimension)
    % Keep every grid/degree/relaxation point independent in YALMIP state.
    assemblyClock = tic;
    yalmip("clear");
    grid = repmat({linspace(0, 1, gridCount)}, 1, parameterDimension);
    if parameterDimension == 1
        A = pdmat(grid, @(rho) [-1, 0.5; -1, -2] ...
            + rho * [-1.3, -20; 2, -10], Degree=1);
        B = pdmat(grid, @(rho) [1, -4; -1, -1] ...
            + rho * [2.2, 0.5; -6, -5], Degree=1);
    else
        A = pdmat(grid, @(rho, eta) [-1, 0.5; -1, -2] ...
            + rho * [-1.3, -20; 2, -10] ...
            + eta * [-0.25, 0.1; -0.1, -0.3], Degree=1);
        B = pdmat(grid, @(rho, eta) [1, -4; -1, -1] ...
            + rho * [2.2, 0.5; -6, -5] ...
            + eta * [0.1, 0; 0, -0.1], Degree=1);
    end
    C = eye(2);
    D = zeros(2);

    P = pdvar(2, grid, Degree=degree);
    diffP = rhodiff(P, repmat([-1, 1], parameterDimension, 1));
    gamma = pdvar(1, grid, Degree=0);
    E1 = [diffP + P * A + A' * P, P * B, C';
        B' * P, -gamma * eye(2), D';
        C, D, -gamma * eye(2)] <= 0;
    E2 = P >= 0;

    % Only the block performance inequality changes certificate family;
    % positivity of P remains the coefficient-wise condition in root test.m.
    switch relaxation
        case "Polya"
            E1 = E1.applyPolya(1);
        case "Putinar"
            E1 = E1.applyPutinar();
        case "FullBox"
            E1 = E1.applyFullBoxPreorder();
        otherwise
            if startsWith(relaxation, "SparseFullBox_b")
                E1 = E1.applySparseFullBoxPreorder(bandWidth);
            end
    end

    constraints = [E1.toYalmip, E2.toYalmip];
    assemblyTime = toc(assemblyClock);
    variableCount = numel(allvariables(constraints));
    constraintCount = length(constraints);
    [freeVariableCount, equalityScalarCount, equalityRank, ...
        psdConstraintCount, maximumPsdDimension] = reduced_counts(constraints);
    effectiveFamily = effective_family(E1, relaxation);
    gammaCoeffs = gamma.coeffs(ones(1, parameterDimension));
    objective = gammaCoeffs{1};
    solveClock = tic;
    diagnostic = optimize(constraints, objective, opts);
    solveTime = toc(solveClock);
    problem = diagnostic.problem;
    gammaValue = NaN;
    if problem == 0
        gammaValue = value(objective);
    end
end

function [complexity, complexityByRelaxation] = complexity_tables( ...
    degrees, gridCounts, relaxations, ...
    gammaValues, variableCounts, constraintCounts, freeVariableCounts, ...
    equalityScalarCounts, equalityRanks, psdConstraintCounts, ...
    maximumPsdDimensions, assemblyTimes, solveTimes, effectiveFamilies)
    [degreeGrid, gridCountGrid] = ndgrid(degrees, gridCounts);
    complexity = table(degreeGrid(:), gridCountGrid(:), ...
        VariableNames=["Degree", "GridNodeCount"]);
    for relaxationIdx = 1:numel(relaxations)
        relaxationName = relaxations(relaxationIdx);
        variableName = matlab.lang.makeValidName( ...
            relaxationName + "DecisionVariableCount");
        constraintName = matlab.lang.makeValidName( ...
            relaxationName + "ConstraintObjectCount");
        freeVariableName = matlab.lang.makeValidName( ...
            relaxationName + "FreeDecisionVariableCount");
        psdConstraintName = matlab.lang.makeValidName( ...
            relaxationName + "PsdConstraintCount");
        maximumPsdName = matlab.lang.makeValidName( ...
            relaxationName + "MaximumPsdDimension");
        assemblyTimeName = matlab.lang.makeValidName( ...
            relaxationName + "AssemblyTime");
        solveTimeName = matlab.lang.makeValidName( ...
            relaxationName + "SolveTime");
        complexity.(variableName) = reshape( ...
            variableCounts(:, :, relaxationIdx), [], 1);
        complexity.(constraintName) = reshape( ...
            constraintCounts(:, :, relaxationIdx), [], 1);
        complexity.(freeVariableName) = reshape( ...
            freeVariableCounts(:, :, relaxationIdx), [], 1);
        complexity.(psdConstraintName) = reshape( ...
            psdConstraintCounts(:, :, relaxationIdx), [], 1);
        complexity.(maximumPsdName) = reshape( ...
            maximumPsdDimensions(:, :, relaxationIdx), [], 1);
        complexity.(assemblyTimeName) = reshape( ...
            assemblyTimes(:, :, relaxationIdx), [], 1);
        complexity.(solveTimeName) = reshape( ...
            solveTimes(:, :, relaxationIdx), [], 1);
    end

    [degreeGrid, gridCountGrid, relaxationGrid] = ndgrid( ...
        degrees, gridCounts, 1:numel(relaxations));
    complexityByRelaxation = table( ...
        degreeGrid(:), ...
        gridCountGrid(:), ...
        reshape(relaxations(relaxationGrid(:)), [], 1), ...
        gammaValues(:), ...
        variableCounts(:), ...
        constraintCounts(:), ...
        freeVariableCounts(:), ...
        equalityScalarCounts(:), ...
        equalityRanks(:), ...
        psdConstraintCounts(:), ...
        maximumPsdDimensions(:), ...
        assemblyTimes(:), ...
        solveTimes(:), ...
        effectiveFamilies(:), ...
        VariableNames=["Degree", "GridNodeCount", "Relaxation", ...
        "Gamma", "DecisionVariableCount", "ConstraintObjectCount", ...
        "FreeDecisionVariableCount", "EqualityScalarCount", "EqualityRank", ...
        "PsdConstraintCount", "MaximumPsdDimension", "AssemblyTime", ...
        "SolveTime", "EffectiveFamily"]);
end

function [freeVariableCount, equalityScalarCount, equalityRank, ...
    psdConstraintCount, maximumPsdDimension] = reduced_counts(constraints)
    % YALMIP exposes one scalar row per upper-triangle matrix equality entry.
    variableIds = getvariables(constraints);
    equalityIndices = find(is(constraints, "equality"));
    equalityRows = cell(numel(equalityIndices), 1);
    for equalityIdx = 1:numel(equalityIndices)
        equalityConstraint = constraints(equalityIndices(equalityIdx));
        equalityBase = getbase(equalityConstraint);
        localVariableIds = getvariables(equalityConstraint);
        [isPresent, columns] = ismember(localVariableIds, variableIds);
        assert(all(isPresent), "pdlmi:BenchmarkVariableMap", ...
            "Every equality variable must occur in the full constraint set.");
        equalityRows{equalityIdx} = sparse(size(equalityBase, 1), ...
            numel(variableIds));
        equalityRows{equalityIdx}(:, columns) = equalityBase(:, 2:end);
    end
    equalityMatrix = vertcat(equalityRows{:});
    equalityScalarCount = size(equalityMatrix, 1);
    equalityRank = sparse_rank(equalityMatrix);
    freeVariableCount = numel(variableIds) - equalityRank;
    psdIndices = find(is(constraints, "sdp"));
    psdConstraintCount = numel(psdIndices);
    maximumPsdDimension = 0;
    for k = 1:numel(psdIndices)
        psdConstraint = constraints(psdIndices(k));
        scalarRows = size(getbase(psdConstraint), 1);
        blockDimension = round(sqrt(scalarRows));
        assert(blockDimension ^ 2 == scalarRows, ...
            "pdlmi:BenchmarkPsdShape", ...
            "An SDP constraint must expose one getbase row per matrix entry.");
        maximumPsdDimension = max(maximumPsdDimension, ...
            blockDimension);
    end
end

function family = effective_family(C, requested)
    % Report endpoint normalization rather than only the requested selector.
    if C.UseSparseFullBoxPreorder
        family = "SparseFullBox";
    elseif C.UseFullBoxPreorder
        family = "FullBox";
    elseif startsWith(requested, "SparseFullBox_b")
        family = "Direct";
    else
        family = requested;
    end
end

function rankValue = sparse_rank(matrix)
    % Sparse LU gives the numerical row rank without forming a dense matrix.
    if isempty(matrix)
        rankValue = 0;
        return
    end

    [~, upper] = lu(matrix);
    tolerance = max(size(matrix)) * eps(norm(upper, inf));
    rankValue = nnz(full(max(abs(upper), [], 2)) > tolerance);
end

function matched = gamma_matched_complexity(degrees, gridCounts, relaxations, ...
    gammaValues, freeVariableCounts, psdConstraintCounts, gammaTolerance)
    targets = sort(gammaValues(isfinite(gammaValues)));
    % Merge solver-level numerical duplicates before forming comparison bands.
    targets = targets([true; diff(targets) > 1e-4 * max(1, targets(1:end - 1))]);
    rows = numel(targets) * numel(relaxations);
    matched = table(NaN(rows, 1), strings(rows, 1), NaN(rows, 1), ...
        NaN(rows, 1), NaN(rows, 1), NaN(rows, 1), NaN(rows, 1), ...
        VariableNames=["TargetGamma", "Relaxation", "Degree", ...
        "GridNodeCount", "AchievedGamma", "FreeDecisionVariableCount", ...
        "PsdConstraintCount"]);

    row = 0;
    for targetIdx = 1:numel(targets)
        target = targets(targetIdx);
        feasible = false(1, numel(relaxations));
        for relaxIdx = 1:numel(relaxations)
            feasible(relaxIdx) = any(gammaValues(:, :, relaxIdx) ...
                <= (1 + gammaTolerance) * target, "all");
        end
        if ~all(feasible)
            continue
        end

        for relaxIdx = 1:numel(relaxations)
            gammaSlice = gammaValues(:, :, relaxIdx);
            candidateIndices = find(gammaSlice <= (1 + gammaTolerance) * target);
            candidateData = [freeVariableCounts(candidateIndices + ...
                numel(gammaSlice) * (relaxIdx - 1)), ...
                psdConstraintCounts(candidateIndices + ...
                numel(gammaSlice) * (relaxIdx - 1)), gammaSlice(candidateIndices)];
            [~, order] = sortrows(candidateData, [1, 2, 3]);
            best = candidateIndices(order(1));
            [degreeIdx, gridIdx] = ind2sub(size(gammaSlice), best);

            row = row + 1;
            matched.TargetGamma(row) = target;
            matched.Relaxation(row) = relaxations(relaxIdx);
            matched.Degree(row) = degrees(degreeIdx);
            matched.GridNodeCount(row) = gridCounts(gridIdx);
            matched.AchievedGamma(row) = gammaSlice(best);
            matched.FreeDecisionVariableCount(row) = ...
                freeVariableCounts(degreeIdx, gridIdx, relaxIdx);
            matched.PsdConstraintCount(row) = ...
                psdConstraintCounts(degreeIdx, gridIdx, relaxIdx);
        end
    end
    matched = matched(1:row, :);
end

function opts = solver_options
    % This comparison is anchored to MOSEK so solver changes cannot obscure
    % certificate-family timing or numerical differences.
    if exist("mosekopt", "file") == 0
        error("pdlmi:BenchmarkMosekUnavailable", ...
            "The relaxation benchmark requires an available MOSEK installation.");
    end
    opts = sdpsettings('solver', 'mosek', 'verbose', 0);
    yalmip("clear");
    cleanup = onCleanup(@() yalmip("clear")); %#ok<NASGU>
    probe = sdpvar(2, 2, 'symmetric');
    diagnostic = optimize(probe >= eye(2), trace(probe), opts);
    if diagnostic.problem ~= 0
        error("pdlmi:BenchmarkMosekUnavailable", ...
            "The MOSEK SDP probe failed with problem %d: %s", ...
            diagnostic.problem, diagnostic.info);
    end
    fprintf(1, 'PD-LMI relaxation benchmark solver: mosek\n');
    drawnow;
end
