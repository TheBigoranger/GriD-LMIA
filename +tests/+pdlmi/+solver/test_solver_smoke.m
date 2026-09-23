function tests = test_solver_smoke
    % Behavioral regressions for pdlmi.solver_smoke.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    % Clear YALMIP global state so each solver smoke test builds fresh LMIs.
    yalmip("clear");
    testCase.TestData.Solver = tests.infrastructure.select_sdp_solver();
    fprintf("GriD-LMIA solver smoke policy selected: %s\n", testCase.TestData.Solver);
end

function test_example_feasible_only_p_allowed_depend(testCase)
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
    tests.infrastructure.verify_solved(testCase,[Cdecay.toYalmip,Cpos.toYalmip]);
    for rho=linspace(0,1,13)
        pv=value(evaluate(Pd,rho)); av=evaluate(A,rho);
        testCase.verifyTrue(all(isfinite(pv(:))));
        testCase.verifyLessThanOrEqual(max(eig(pv*av+av'*pv))/max(1,norm(pv*av+av'*pv,'fro')),1e-7);
    end

    % Convert solved symbolic Bernstein coefficients to known data so the
    % existing pdmat plotter can show the parameter-dependent certificate.
    Pplot = value(Pd);
    fig=figure(Visible="off",Name="Parameter-dependent Lyapunov matrix");
    cleanup=onCleanup(@() close(fig)); %#ok<NASGU>
    h = plot(Pplot, SamplesPerCell=40, LineWidth=1.5);
    title("Solved parameter-dependent Lyapunov matrix");
    testCase.verifyEqual(numel(h), 4);
end

function test_absorbed_root_test_m_as_solver(testCase)
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
    tests.infrastructure.verify_solved(testCase,[E1.toYalmip,E2.toYalmip]);
    gammaValue = value(objective);
    testCase.verifyTrue(isfinite(gammaValue));
    fprintf("Optimal H-infinity gamma: %.6g\n", gammaValue);
end

function test_public_inequality_certificate_reach_selected_sdp(testCase)
    % Every public inequality certificate must reach the selected SDP solver.
    yalmip("clear");
    P = pdvar(2, 1, {[0 1]}, "full", Degree=0);
    R = P - ones(2, 1);
    direct = consEntSil(@() R >= 0);
    wrappers = {direct, ...
        consEntSil(@() direct.usePolya(1)), ...
        consEntSil(@() direct.usePutinar(0)), ...
        consEntSil(@() direct.useSpPut(2, 0)), ...
        consEntSil(@() ...
            direct.useSpBox(2, 2)), ...
        consEntSil(@() direct.useFullBox(0))};

    solver = testCase.TestData.Solver;
    opts = sdpsettings('solver', solver, 'verbose', 0);
    fprintf("Rectangular certificate solver: %s\n", solver);
    for k = 1:numel(wrappers)
        sol = optimize(wrappers{k}.toYalmip, [], opts);
        testCase.verifyEqual(sol.problem, 0, sol.info);
        tests.infrastructure.verify_solved(testCase,wrappers{k}.toYalmip);
    end
end

function test_auxiliary_gram_family_known_residual_solver(testCase)
    % Every auxiliary-Gram family for a known residual must be solver feasible.
    yalmip("clear");
    A = pdmat([0 1], @(rho) 1 + 0 * rho, Degree=4);
    direct = A >= 0;
    wrappers = {
        direct.usePutinar(2), ...
        direct.useSpPut(2, 2), ...
        direct.useSpBox(2, 2), ...
        direct.useFullBox(2)
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
        tests.infrastructure.verify_solved(testCase,wrappers{k}.toYalmip);
    end
end

function out = consEntSil(fun)
    % Solver smoke output should not repeat dispatch warnings covered elsewhere.
    warnId = "pdlmi:ElementwiseInequality";
    state = warning("query", warnId);
    cleanup = onCleanup(@() warning(state.state, warnId)); %#ok<NASGU>
    warning("off", warnId);
    out = fun();
end

function test_multicell_cubic_continuity_bounded_real_certificate(testCase)
    % Each fixed continuity order solves the same nonuniform-grid problem.
    % Compare physical residuals as well as the assembled solver constraints.
    grid = [0 .2 .65 1];
    options = sdpsettings('solver',testCase.TestData.Solver,'verbose',0);
    for q = [0 1 2 Inf]
        yalmip('clear');
        A = pdmat(grid,@(x) [-1 .5;-1 -2]+x*[-1.3 -20;2 -10],Degree=1);
        B = pdmat(grid,@(x) [1 -4;-1 -1]+x*[2.2 .5;-6 -5],Degree=1);
        P = pdvar(2,grid,Degree=3,Continuity=q);
        gamma = pdvar(1,grid,Degree=0);
        derivative = rhodiff(P,[-1 1]);
        boundedReal = [derivative+P*A+A'*P,P*B,eye(2); ...
            B'*P,-gamma*eye(2),zeros(2); ...
            eye(2),zeros(2),-gamma*eye(2)] <= 0;
        positive = P >= 0;
        constraints = [boundedReal.toYalmip,positive.toYalmip];
        objective = gamma.LocalValues{1}{1};
        solution = optimize(constraints,objective,options);
        testCase.assertEqual(solution.problem,0,solution.info);
        tests.infrastructure.verify_solved(testCase,constraints);
        gammaValue = value(objective);
        testCase.verifyTrue(isfinite(gammaValue));
        fprintf('Multicell cubic C%g gamma: %.12g\n',q,gammaValue);
        for c = 1:3
            coefficients = P.coeffs(c);
            coefficients = cellfun(@value,coefficients,'UniformOutput',false);
            width = grid(c+1)-grid(c);
            for t = [0 .19 .61 1]
                rho = grid(c)+t*width;
                pv = zeros(2); dp = zeros(2);
                for k = 0:3
                    pv = pv+nchoosek(3,k)*t^k*(1-t)^(3-k)*coefficients{k+1};
                end
                for k = 0:2
                    dp = dp+3/width*nchoosek(2,k)*t^k*(1-t)^(2-k)* ...
                        (coefficients{k+2}-coefficients{k+1});
                end
                av = [-1 .5;-1 -2]+rho*[-1.3 -20;2 -10];
                bv = [1 -4;-1 -1]+rho*[2.2 .5;-6 -5];
                testCase.verifyTrue(all(isfinite(pv(:))));
                testCase.verifyGreaterThanOrEqual(min(eig(pv))/max(1,norm(pv,'fro')),-1e-7);
                for rate = [-1 1]
                    residual = [rate*dp+pv*av+av'*pv,pv*bv,eye(2); ...
                        bv'*pv,-gammaValue*eye(2),zeros(2); ...
                        eye(2),zeros(2),-gammaValue*eye(2)];
                    testCase.verifyLessThanOrEqual(max(eig((residual+residual')/2))/ ...
                        max(1,norm(residual,'fro')),1e-7);
                end
            end
        end
        impossible = optimize([P>=2*eye(2),P<=eye(2)],[],options);
        testCase.verifyEqual(impossible.problem,1,impossible.info);
    end
end

function test_composed_fixed_rate_certificate_and_infeasible_control(testCase)
    % Solve a derivative/matrix/certificate pipeline and independently sample it.
    yalmip('clear');
    grid = [0 1 4];
    P = pdvar(2, grid, Degree=2, RateBounds=[0.2 0.2]);
    A = pdmat(grid, @(rho) [-2 0.1; 0 -3] + rho * [-0.1 0; 0 -0.2], Degree=1);
    D = rhodiff(P);
    decay = D + A' * P + P * A <= -eye(2);
    decay = decay.usePutinar(2);
    decay = decay.useSpBox(2, 2);
    positive = P >= eye(2);
    F = [positive, decay];
    options = sdpsettings('solver', testCase.TestData.Solver, 'verbose', 0);
    solution = optimize(F, [], options);
    testCase.assertEqual(solution.problem, 0, solution.info);
    tests.infrastructure.verify_solved(testCase, F);
    for c = 1:2
        controls = P.coeffs(c);
        controls = cellfun(@value, controls, 'UniformOutput', false);
        for alpha = [0 0.17 0.63 1]
            rho = grid(c) + alpha * (grid(c + 1) - grid(c));
            pv = (1 - alpha)^2 * controls{1} + ...
                2 * alpha * (1 - alpha) * controls{2} + alpha^2 * controls{3};
            dv = 0.4 / (grid(c + 1) - grid(c)) * ...
                ((1 - alpha) * (controls{2} - controls{1}) + ...
                alpha * (controls{3} - controls{2}));
            av = [-2 0.1; 0 -3] + rho * [-0.1 0; 0 -0.2];
            residual = dv + av' * pv + pv * av + eye(2);
            testCase.verifyTrue(all(isfinite(pv(:))));
            testCase.verifyLessThanOrEqual(max(eig(residual)) / ...
                max(1, norm(residual, 'fro')), 1e-7);
            testCase.verifyGreaterThanOrEqual(min(eig(pv - eye(2))) / ...
                max(1, norm(pv, 'fro')), -1e-7);
        end
    end
    impossible = optimize([P >= 2 * eye(2), P <= eye(2)], [], options);
    testCase.verifyEqual(impossible.problem, 1, impossible.info);
end
