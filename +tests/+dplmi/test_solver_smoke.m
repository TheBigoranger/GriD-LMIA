function tests = test_solver_smoke
    %TEST_SOLVER_SMOKE Solver-facing dplmi feasibility regressions.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    % Clear YALMIP global state so each solver smoke test builds fresh LMIs.
    yalmip("clear");
end

function testParameterDependentPBeatsConstantP(testCase)
    % This example is feasible only after P is allowed to depend on rho.
    A = dpmat({[0 1]}, @(x) (1 - x) * [-1 -1; 1 -1] ...
        + x * [-1 -10; 0.1 -1], Degree=1);
    useMosek = exist('mosekopt', 'file') ~= 0;
    solver = 'lmilab';
    if useMosek
        solver = 'mosek';
    end
    opts = sdpsettings('solver', solver, 'verbose', 0);

    Pc = dpvar(2, {[0 1]}, Degree=0);
    Cdecay = Pc * A + A' * Pc <= -1e-10 * eye(2);
    Cpos = Pc >= eye(2);
    solConst = optimize([Cdecay.toYalmip, Cpos.toYalmip], [], opts);

    Pd = dpvar(2, {[0 1]});
    Cdecay = Pd * A + A' * Pd <= -1e-10 * eye(2);
    Cpos = Pd >= eye(2);
    solDp = optimize([Cdecay.toYalmip, Cpos.toYalmip], [], opts);

    if useMosek
        testCase.verifyEqual(solConst.problem, 1, solConst.info);
    else
        % LMILAB is only a fallback smoke path; do not use it to certify the
        % infeasibility distinction that MOSEK reports for this example.
        testCase.verifyTrue(any(solConst.problem == [0 1]), solConst.info);
    end
    testCase.verifyEqual(solDp.problem, 0, solDp.info);
end

function testUserBlockLmiSolverExample(testCase)
    % Absorbed from root test.m as a solver-facing block-DP-LMI example.
    yalmip("clear");

    grid = linspace(0, 1, 2);
    A = dpmat(grid, @(x) [-1, 0.5; -1, -2] ...
        + x * [-1.3, -20; 2, -10], Degree=1);
    B = dpmat(grid, @(x) [1, -4; -1, -1] ...
        + x * [2.2, 0.5; -6, -5], Degree=1);
    C = eye(2);
    D = zeros(2);

    P = dpvar(2, grid);
    diffP = rhodiff(P, [-1 1]);
    gamma = dpvar(1, grid, Degree=0);
    E1 = [diffP + P * A + A' * P, P * B, C';
        B' * P, -gamma * eye(2), D';
        C, D, -gamma * eye(2)] <= 0;
    E2 = P >= 0;

    testCase.verifyEqual(numel(E1.Constraints), 6);
    testCase.verifyEqual(numel(E2.Constraints), 2);

    objective = gamma.LocalValues{1}{1};
    solver = 'lmilab';
    if exist('mosekopt', 'file') ~= 0
        solver = 'mosek';
    end
    opts = sdpsettings('solver', solver, 'verbose', 0);
    sol = optimize([E1.toYalmip, E2.toYalmip], objective, opts);

    testCase.verifyEqual(sol.problem, 0, sol.info);
    testCase.verifyTrue(isfinite(value(objective)));
end
