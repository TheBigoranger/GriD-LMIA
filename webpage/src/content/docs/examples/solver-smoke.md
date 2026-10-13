---
title: Solver Smoke Cases
description: Two solver-facing examples mirrored from +tests/+pdlmi/test_solver_smoke.m.
---

<nav class="manual-trail">
  <a href="/GriD-LMIA/examples/">Examples</a>
  <span>/</span>
  <span>Solver Smoke Cases</span>
</nav>

These examples mirror the tested solver-facing workflows in `+tests/+pdlmi/test_solver_smoke.m`. They use the package to assemble YALMIP constraints. Solver selection and execution still happen through ordinary YALMIP calls.
They are non-strict regression constraints. Strict analysis requires an
explicit $\varepsilon I$ margin as described in the
[global notation](/GriD-LMIA/documents/math/notation/#strict-theory-and-software-constraints).

<span id="parameter-dependent-lyapunov-feasibility"></span>

## Parameter-Dependent Lyapunov Variable

The first smoke test compares a constant Lyapunov matrix against a parameter-dependent Lyapunov matrix for

<div className="solver-one-line">

$$
A(\rho)=(1-\rho)\begin{bmatrix}-1&-1\\1&-1\end{bmatrix}
+\rho\begin{bmatrix}-1&-10\\0.1&-1\end{bmatrix},
\qquad \rho\in[0,1].
$$

</div>

The tested constraints are

$$
\begin{aligned}
P(\rho)A(\rho)+A(\rho)^\top P(\rho)
&\preceq -10^{-10}I,\\
P(\rho)&\succeq I.
\end{aligned}
$$

With `Degree=0`, `P` is constant over the cell. With the default degree, `P` is parameter-dependent.

```matlab
yalmip('clear')
grid = {[0 1]};
A = pdmat(grid, @(x) (1 - x) * [-1 -1; 1 -1] ...
    + x * [-1 -10; 0.1 -1], Degree=1);

solver = "lmilab";
if exist("mosekopt", "file") ~= 0
    solver = "mosek";
end
opts = sdpsettings("solver", solver, "verbose", 0);

Pc = pdvar(2, grid, Degree=0);
Cdecay = Pc * A + A' * Pc <= -1e-10 * eye(2);
Cpos = Pc >= eye(2);
solConst = optimize([Cdecay.toYalmip, Cpos.toYalmip], [], opts);

Pd = pdvar(2, grid);
Cdecay = Pd * A + A' * Pd <= -1e-10 * eye(2);
Cpos = Pd >= eye(2);
solDp = optimize([Cdecay.toYalmip, Cpos.toYalmip], [], opts);

if solDp.problem ~= 0
    error("GriD-LMIA:ExampleSolveFailed", "%s", solDp.info)
end

% Convert the solved decision object into known data for plotting.
Pplot = value(Pd);
figure(Name="Parameter-dependent Lyapunov matrix");
plot(Pplot, SamplesPerCell=40, LineWidth=1.5);
title("Solved parameter-dependent Lyapunov matrix");
```

In the regression, MOSEK reports the constant case as infeasible and the
parameter-dependent case as feasible. `lmilab` supplies a fallback execution
path, while MOSEK provides the stated infeasibility distinction.

After the feasible solve, the smoke test opens **Parameter-dependent Lyapunov matrix** and plots the four entries of the solved $2\times2$ matrix $P(\rho)$ across $[0,1]$. `Pd` is symbolic decision data, so its cell-wise Bernstein coefficients are evaluated with `value` and used to construct a known `pdmat` (`Pplot`) before calling [`plot`](/GriD-LMIA/documents/reference/pdmat/plot/). The plot uses 40 samples per cell and a line width of 1.5.

<span id="induced-l2-gain-with-rate-vertex-derivatives"></span>

## Block PD-LMI Objective

The second smoke test assembles a block residual with a rate-dependent derivative term. The parameter-dependent matrices are

<div className="solver-one-line">

$$
A(\rho)=\begin{bmatrix}-1&0.5\\-1&-2\end{bmatrix}
+\rho\begin{bmatrix}-1.3&-20\\2&-10\end{bmatrix}.
$$

</div>

<div className="solver-one-line">

$$
B(\rho)=\begin{bmatrix}1&-4\\-1&-1\end{bmatrix}
+\rho\begin{bmatrix}2.2&0.5\\-6&-5\end{bmatrix}.
$$

</div>

With $C=I$, $D=0$, $\dot{P}=\mathrm{rhodiff}(P,[-1,1])$, and scalar $\gamma$, the tested block condition is

$$
\begin{aligned}
&
\Biggl[\begin{matrix}
\dot{P}+PA+A^\top P & PB & C^\top \\
B^\top P & -\gamma I & D^\top \\
C & D & -\gamma I
\end{matrix}\Biggr]
\\
&\preceq 0,\\
&P(\rho)\succeq 0.
\end{aligned}
$$

```matlab
yalmip('clear')
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

objective = gamma.LocalValues{1}{1};
solver = "lmilab";
if exist("mosekopt", "file") ~= 0
    solver = "mosek";
end
opts = sdpsettings("solver", solver, "verbose", 0);
sol = optimize([E1.toYalmip, E2.toYalmip], objective, opts);

if sol.problem ~= 0
    error("GriD-LMIA:ExampleSolveFailed", "%s", sol.info)
end

gammaValue = value(objective)
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

The numeric value is solver- and tolerance-dependent, so the regression target uses solver status and finite recovered values.

The release-gate smoke suite also exports one representative inequality from
each implemented family—Direct, Pólya, Putinar, SparsePutinar, SparseFullBox, and
FullBox—through the same solver policy, which prefers MOSEK when available.

## Boundary

These examples call YALMIP directly for solver selection and optimization. They document the
current boundary: GriD-LMIA builds direct, Pólya-elevated,
[`Putinar box`](/GriD-LMIA/documents/reference/pdlmi/useputinar/), or
[`SparsePutinar`](/GriD-LMIA/documents/reference/pdlmi/usespput/), or
[`SparseFullBox`](/GriD-LMIA/documents/reference/pdlmi/usespbox/), or
[`full-box`](/GriD-LMIA/documents/reference/pdlmi/usefullbox/)
YALMIP constraints, and users call `optimize` directly.
