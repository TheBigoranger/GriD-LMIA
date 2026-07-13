---
title: Solver Smoke Cases
description: Two solver-facing examples mirrored from +tests/+dplmi/test_solver_smoke.m.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/examples/">Examples</a>
  <span>/</span>
  <span>Solver Smoke Cases</span>
</nav>

These examples mirror the tested solver-facing workflows in `+tests/+dplmi/test_solver_smoke.m`. They use the package to assemble YALMIP constraints; solver selection and execution still happen through ordinary YALMIP calls.

## Parameter-Dependent Lyapunov Variable

The first smoke test compares a constant Lyapunov matrix against a parameter-dependent Lyapunov matrix for

$$
A(\rho)=(1-\rho)
\begin{bmatrix}
-1 & -1 \\
1 & -1
\end{bmatrix}
+\rho
\begin{bmatrix}
-1 & -10 \\
0.1 & -1
\end{bmatrix},
\qquad \rho\in[0,1].
$$

The tested constraints are

$$
P(\rho)A(\rho)+A(\rho)^\top P(\rho)\preceq -10^{-10}I,
\qquad
P(\rho)\succeq I.
$$

With `Degree=0`, `P` is constant over the cell. With the default degree, `P` is parameter-dependent.

```matlab
yalmip('clear')
grid = {[0 1]};
A = dpmat(grid, @(x) (1 - x) * [-1 -1; 1 -1] ...
    + x * [-1 -10; 0.1 -1], Degree=1);

solver = "lmilab";
if exist("mosekopt", "file") ~= 0
    solver = "mosek";
end
opts = sdpsettings("solver", solver, "verbose", 0);

Pc = dpvar(2, grid, Degree=0);
Cdecay = Pc * A + A' * Pc <= -1e-10 * eye(2);
Cpos = Pc >= eye(2);
solConst = optimize([Cdecay.toYalmip, Cpos.toYalmip], [], opts);

Pd = dpvar(2, grid);
Cdecay = Pd * A + A' * Pd <= -1e-10 * eye(2);
Cpos = Pd >= eye(2);
solDp = optimize([Cdecay.toYalmip, Cpos.toYalmip], [], opts);

% Convert the solved symbolic Bernstein coefficients into known data for plotting.
Pplot = dpmat(grid, {cellfun(@value, Pd.LocalValues{1}, ...
    UniformOutput=false)}, Degree=Pd.Degree);
figure(Name="Parameter-dependent Lyapunov matrix");
plot(Pplot, SamplesPerCell=40, LineWidth=1.5);
title("Solved parameter-dependent Lyapunov matrix");
```

In the regression, MOSEK reports the constant case as infeasible and the parameter-dependent case as feasible. `lmilab` is used only as a fallback smoke path, not as the certificate for the infeasibility distinction.

After the feasible solve, the smoke test opens **Parameter-dependent Lyapunov matrix** and plots the four entries of the solved $2\times2$ matrix $P(\rho)$ across $[0,1]$. `Pd` is symbolic decision data, so its cell-local Bernstein coefficients are evaluated with `value` and used to construct a known `dpmat` (`Pplot`) before calling [`plot`](/DP-LMI-package/documents/reference/dpmat/plot/). The plot uses 40 samples per cell and a line width of 1.5.

## Block DP-LMI Objective

The second smoke test assembles a block residual with a rate-dependent derivative term. The parameter-dependent matrices are

$$
A(\rho)=
\begin{bmatrix}
-1 & 0.5 \\
-1 & -2
\end{bmatrix}
+\rho
\begin{bmatrix}
-1.3 & -20 \\
2 & -10
\end{bmatrix},
$$

$$
B(\rho)=
\begin{bmatrix}
1 & -4 \\
-1 & -1
\end{bmatrix}
+\rho
\begin{bmatrix}
2.2 & 0.5 \\
-6 & -5
\end{bmatrix}.
$$

With $C=I$, $D=0$, $\dot{P}=\mathrm{rhodiff}(P,[-1,1])$, and scalar $\gamma$, the block residual is

$$
\begin{bmatrix}
\dot{P}+PA+A^\top P & PB & C^\top \\
B^\top P & -\gamma I & D^\top \\
C & D & -\gamma I
\end{bmatrix}
\preceq 0,
\qquad P(\rho)\succeq 0.
$$

```matlab
yalmip('clear')
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

objective = gamma.LocalValues{1}{1};
solver = "lmilab";
if exist("mosekopt", "file") ~= 0
    solver = "mosek";
end
opts = sdpsettings("solver", solver, "verbose", 0);
sol = optimize([E1.toYalmip, E2.toYalmip], objective, opts);

gammaValue = value(objective);
fprintf("Optimal H-infinity gamma: %.6g\n", gammaValue);
```

The regression verifies that the assembled constraint counts are stable:

```matlab
numel(E1.Constraints)
numel(E2.Constraints)
```

```text
ans =
     6

ans =
     2
```

The solver smoke path checks `sol.problem == 0`, verifies that `gammaValue` is finite, and prints the attained objective in this format:

```text
Optimal H-infinity gamma: <solver result>
```

The numeric value is solver- and tolerance-dependent, so the manual does not present a fixed value as a regression target.

## Boundary

These examples do not call a package-owned solver wrapper. They document the
current boundary: DP-LMI builds direct, Pólya-elevated, or
[`full-box`](/DP-LMI-package/documents/reference/dplmi/applyfullboxpreorder/)
YALMIP constraints, and users call `optimize` directly.
