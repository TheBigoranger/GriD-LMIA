function tests = test_solver_smoke
    %TEST_SOLVER_SMOKE Solver-facing pdlmi feasibility regressions.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    % Clear YALMIP global state so each solver smoke test builds fresh LMIs.
    yalmip("clear");
    testCase.TestData.Solver = tests.select_sdp_solver();
    fprintf("GriD-LMIA solver smoke policy selected: %s\n", testCase.TestData.Solver);
end

function testParameterDependentPBeatsConstantP(testCase)
    % This example is feasible only after P is allowed to depend on rho.
    grid = {[0 1]};
    A = pdmat(grid, @(x) (1 - x) * [-1 -1; 1 -1] ...
        + x * [-1 -10; 0.1 -1], Degree=1);
    opts = sdpsettings('solver', testCase.TestData.Solver, 'verbose', 0);

    Pc = pdvar(2, grid, Degree=0);
    Cdecay = Pc * A + A' * Pc <= -1e-10 * eye(2);
    Cpos = Pc >= eye(2);
    solConst = optimize([Cdecay.toYalmip, Cpos.toYalmip], [], opts);

    Pd = pdvar(2, grid);
    Cdecay = Pd * A + A' * Pd <= -1e-10 * eye(2);
    Cpos = Pd >= eye(2);
    solDp = optimize([Cdecay.toYalmip, Cpos.toYalmip], [], opts);

    testCase.verifyEqual(solConst.problem, 1, solConst.info);
    testCase.verifyEqual(solDp.problem, 0, solDp.info);

    % Convert solved symbolic Bernstein coefficients to known data so the
    % existing pdmat plotter can show the parameter-dependent certificate.
    Pplot = value(Pd);
    figure(Name="Parameter-dependent Lyapunov matrix");
    h = plot(Pplot, SamplesPerCell=40, LineWidth=1.5);
    title("Solved parameter-dependent Lyapunov matrix");
    testCase.verifyEqual(numel(h), 4);
end

function testUserBlockLmiSolverExample(testCase)
    % Absorbed from root test.m as a solver-facing block-PD-LMI example.
    yalmip("clear");

    grid = linspace(0, 1, 2);
    A = pdmat(grid, @(x) [-1, 0.5; -1, -2] ...
        + x * [-1.3, -20; 2, -10], Degree=1);
    B = pdmat(grid, @(x) [1, -4; -1, -1] ...
        + x * [2.2, 0.5; -6, -5], Degree=1);
    C = eye(2);
    D = zeros(2);

    P = pdvar(2, grid);
    diffP = rhodiff(P, [-1 1]);
    gamma = pdvar(1, grid, Degree=0);
    E1 = [diffP + P * A + A' * P, P * B, C';
        B' * P, -gamma * eye(2), D';
        C, D, -gamma * eye(2)] <= 0;
    E2 = P >= 0;

    testCase.verifyEqual(numel(E1.Constraints), 6);
    testCase.verifyEqual(numel(E2.Constraints), 2);

    objective = gamma.LocalValues{1}{1};
    solver = testCase.TestData.Solver;
    opts = sdpsettings('solver', solver, 'verbose', 0);
    sol = optimize([E1.toYalmip, E2.toYalmip], objective, opts);

    testCase.verifyEqual(sol.problem, 0, sol.info);
    gammaValue = value(objective);
    testCase.verifyTrue(isfinite(gammaValue));
    fprintf("Optimal H-infinity gamma: %.6g\n", gammaValue);
end

function testRectangularResidualAcrossAllCertificates(testCase)
    % Every public inequality certificate must reach the selected SDP solver.
    yalmip("clear");
    P = pdvar(2, 1, {[0 1]}, "full", Degree=0);
    R = P - ones(2, 1);
    direct = constructEntrywiseSilently(@() R >= 0);
    wrappers = {direct, ...
        constructEntrywiseSilently(@() direct.applyPolya(1)), ...
        constructEntrywiseSilently(@() direct.applyPutinar(0)), ...
        constructEntrywiseSilently(@() ...
            direct.applySparseFullBoxPreorder(2, 2)), ...
        constructEntrywiseSilently(@() direct.applyFullBoxPreorder(0))};

    solver = testCase.TestData.Solver;
    opts = sdpsettings('solver', solver, 'verbose', 0);
    fprintf("Rectangular certificate solver: %s\n", solver);
    for k = 1:numel(wrappers)
        sol = optimize(wrappers{k}.toYalmip, [], opts);
        testCase.verifyEqual(sol.problem, 0, sol.info);
    end
end

function testKnownPdmatGramCertificatesSolve(testCase)
    % Every auxiliary-Gram family for a known residual must be solver feasible.
    yalmip("clear");
    A = pdmat([0 1], @(rho) 1 + 0 * rho, Degree=4);
    direct = A >= 0;
    wrappers = {
        direct.applyPutinar(2), ...
        direct.applySparseFullBoxPreorder(2, 2), ...
        direct.applyFullBoxPreorder(2)
        };

    solver = testCase.TestData.Solver;
    opts = sdpsettings('solver', solver, 'verbose', 0);
    fprintf("Known pdmat Gram certificate solver: %s\n", solver);
    for k = 1:numel(wrappers)
        F = wrappers{k}.toYalmip;
        testCase.verifyTrue(isa(F, "lmi") || isa(F, "constraint"));
        testCase.verifyNotEmpty(getvariables(F));
        sol = optimize(F, [], opts);
        testCase.verifyEqual(sol.problem, 0, sol.info);
    end
end

function out = constructEntrywiseSilently(fun)
    % Solver smoke output should not repeat dispatch warnings covered elsewhere.
    warnId = "pdlmi:ElementwiseInequality";
    state = warning("query", warnId);
    cleanup = onCleanup(@() warning(state.state, warnId)); %#ok<NASGU>
    warning("off", warnId);
    out = fun();
end
