function result = benchmark_relaxations(parameterDimension)
    %BENCHMARK_RELAXATIONS Compare PD-LMI relaxations from the root example.
    %
    %   result = tests.pdlmi.benchmark_relaxations() solves a two-parameter
    %   extension of the root test.m block-PD-LMI for P degrees 1:3 and
    %   grid-node counts 2:3. Pass parameterDimension=1 to run the original
    %   one-parameter sweep (degrees 1:5 and grid-node counts 2:6). It plots
    %   the optimal H-infinity gamma for direct coefficients, Polya elevation
    %   one, Putinar, and FullBox. Solver failures are retained as NaN.
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

    if parameterDimension == 1
        degrees = 1:5;
        gridCounts = 2:6;
    else
        % A 2D full preordering adds four Gram blocks per cell/rate vertex.
        % Keep the default sweep small enough to solve as a manual benchmark.
        degrees = 1:3;
        gridCounts = 2:3;
    end
    relaxations = ["Direct", "Polya", "Putinar", "FullBox"];
    opts = solver_options();

    gammaValues = NaN(numel(degrees), numel(gridCounts), numel(relaxations));
    problemCodes = NaN(size(gammaValues));
    variableCounts = NaN(size(gammaValues));
    constraintCounts = NaN(size(gammaValues));
    freeVariableCounts = NaN(size(gammaValues));
    equalityScalarCounts = NaN(size(gammaValues));
    equalityRanks = NaN(size(gammaValues));
    psdConstraintCounts = NaN(size(gammaValues));
    for relaxIdx = 1:numel(relaxations)
        for degreeIdx = 1:numel(degrees)
            for gridIdx = 1:numel(gridCounts)
                [gammaValues(degreeIdx, gridIdx, relaxIdx), ...
                    problemCodes(degreeIdx, gridIdx, relaxIdx), ...
                    variableCounts(degreeIdx, gridIdx, relaxIdx), ...
                    constraintCounts(degreeIdx, gridIdx, relaxIdx), ...
                    freeVariableCounts(degreeIdx, gridIdx, relaxIdx), ...
                    equalityScalarCounts(degreeIdx, gridIdx, relaxIdx), ...
                    equalityRanks(degreeIdx, gridIdx, relaxIdx), ...
                    psdConstraintCounts(degreeIdx, gridIdx, relaxIdx)] = solve_case( ...
                    degrees(degreeIdx), gridCounts(gridIdx), ...
                    relaxations(relaxIdx), opts, parameterDimension);
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
    layout = tiledlayout(2, 2, TileSpacing="compact", Padding="compact");
    title(layout, "Root test.m H-infinity example: optimal gamma");
    for relaxIdx = 1:numel(relaxations)
        nexttile;
        surf(gridCounts, degrees, gammaValues(:, :, relaxIdx), ...
            EdgeColor="none");
        xlabel("Grid node count");
        ylabel("P degree m");
        zlabel("Optimal gamma");
        title(relaxations(relaxIdx));
        zlim(zLimits);
        clim(zLimits);
        colorbar;
        view(3);
    end
    drawnow;

    [complexity, complexityByRelaxation] = complexity_tables( ...
        degrees, gridCounts, relaxations, gammaValues, variableCounts, ...
        constraintCounts, freeVariableCounts, equalityScalarCounts, ...
        equalityRanks, psdConstraintCounts);
    gammaTolerance = 0.07;
    result = struct( ...
        "degrees", degrees, ...
        "gridCounts", gridCounts, ...
        "parameterDimension", parameterDimension, ...
        "relaxations", relaxations, ...
        "gamma", gammaValues, ...
        "problem", problemCodes, ...
        "complexity", complexity, ...
        "complexityByRelaxation", complexityByRelaxation, ...
        "gammaTolerance", gammaTolerance, ...
        "gammaMatchedComplexity", gamma_matched_complexity( ...
        degrees, gridCounts, relaxations, gammaValues, ...
        freeVariableCounts, psdConstraintCounts, gammaTolerance));
end

function [gammaValue, problem, variableCount, constraintCount, ...
    freeVariableCount, equalityScalarCount, equalityRank, psdConstraintCount] = solve_case( ...
    degree, gridCount, relaxation, opts, parameterDimension)
    % Keep every grid/degree/relaxation point independent in YALMIP state.
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
    end

    constraints = [E1.toYalmip, E2.toYalmip];
    variableCount = numel(allvariables(constraints));
    constraintCount = length(constraints);
    [freeVariableCount, equalityScalarCount, equalityRank, ...
        psdConstraintCount] = reduced_counts(constraints);
    gammaCoeffs = gamma.coeffs(ones(1, parameterDimension));
    objective = gammaCoeffs{1};
    diagnostic = optimize(constraints, objective, opts);
    problem = diagnostic.problem;
    gammaValue = NaN;
    if problem == 0
        gammaValue = value(objective);
    end
end

function [complexity, complexityByRelaxation] = complexity_tables( ...
    degrees, gridCounts, relaxations, ...
    gammaValues, variableCounts, constraintCounts, freeVariableCounts, ...
    equalityScalarCounts, equalityRanks, psdConstraintCounts)
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
        complexity.(variableName) = reshape( ...
            variableCounts(:, :, relaxationIdx), [], 1);
        complexity.(constraintName) = reshape( ...
            constraintCounts(:, :, relaxationIdx), [], 1);
        complexity.(freeVariableName) = reshape( ...
            freeVariableCounts(:, :, relaxationIdx), [], 1);
        complexity.(psdConstraintName) = reshape( ...
            psdConstraintCounts(:, :, relaxationIdx), [], 1);
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
        VariableNames=["Degree", "GridNodeCount", "Relaxation", ...
        "Gamma", "DecisionVariableCount", "ConstraintObjectCount", ...
        "FreeDecisionVariableCount", "EqualityScalarCount", "EqualityRank", ...
        "PsdConstraintCount"]);
end

function [freeVariableCount, equalityScalarCount, equalityRank, ...
    psdConstraintCount] = reduced_counts(constraints)
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
    psdConstraintCount = nnz(is(constraints, "sdp"));
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
    % Use the same preference order as the existing solver smoke test.
    solver = "lmilab";
    if exist("mosekopt", "file") ~= 0
        solver = "mosek";
    end
    opts = sdpsettings('solver', char(solver), 'verbose', 0);
end
