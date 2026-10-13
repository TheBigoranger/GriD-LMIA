---
title: Examples
description: Runnable GriD-LMIA workflows using current public APIs.
---

These examples complement the reference pages with executable workflows. The
root [`example/`](https://github.com/TheBigoranger/GriD-LMIA/tree/main/example)
catalog contains seven independent, source-grounded reproduction scripts.

## Setup And Verification

```matlab
projectRoot = "path/to/GriD-LMIA";
cd(projectRoot)
report = install_pd_lmi();
results = tests.run_all();
```

The installer adds `projectRoot` directly at the end of the MATLAB path. The
test entry point runs installation, helper, `pdbase`,
`pdmat`, `pdvar`, and `pdlmi` tests. `pdvar` and `pdlmi` workflows require
YALMIP on the MATLAB path.

## Source-Grounded Reproduction Catalog

Each script starts with its publication provenance, exact model setting,
certificate choice, numerical target, comparison rule, measured runtime, and
named parameters that users may tune. Run one script at a time after package
installation.

| Script and source | Default certificate setting | Expected outcome | Primary tunables |
| :--- | :--- | :--- | :--- |
| [`lpv_l2_gain_univariate.m`](https://github.com/TheBigoranger/GriD-LMIA/blob/main/example/lpv_l2_gain_univariate.m), Masubuchi, Kume, and Shimemura (1998), Example 1 | One cell, degree-one $P$, univariate [`usePutinar(5)`](/GriD-LMIA/documents/reference/pdlmi/useputinar/) | $gamma=6.05101324526206$ within $5\times10^{-4}$ | Grid nodes, decision degree, Gram order, solver, tolerance |
| [`lpv_l2_gain_three_parameter.m`](https://github.com/TheBigoranger/GriD-LMIA/blob/main/example/lpv_l2_gain_three_parameter.m), Agulhari et al. (2019) and ROLMIP manual §7.2 | One cell per axis, degree-one $P$, Direct | Rate-dependent bound $gamma=1.69895266198667$ within $5\times10^{-4}$ | Per-axis grid nodes, decision degree, solver, margin |
| [`delay_stability_basic.m`](https://github.com/TheBigoranger/GriD-LMIA/blob/main/example/delay_stability_basic.m), delay-system manuscript, Case A and Theorem 2 | Degree-two $P$, one cell, univariate [`useFullBox`](/GriD-LMIA/documents/reference/pdlmi/usefullbox/) Markov–Lukács certificate | Accepted endpoint $3.68676263203714$ rounds to $3.687$ and the prescribed upper probes lose the accepted margin | Degree, rate bound, endpoint probes, solver, margins |
| [`delay_stability_augmented.m`](https://github.com/TheBigoranger/GriD-LMIA/blob/main/example/delay_stability_augmented.m), delay-system manuscript, Case A and Theorem 3 | $(N,d)=(3,3)$, ten cells, Direct | $h=5.151$ accepted and $h=5.152$ rejected or lacking the accepted margin | Integral order, degree, cells, rate bound, solver |
| [`discrete_time_robust_stability.m`](https://github.com/TheBigoranger/GriD-LMIA/blob/main/example/discrete_time_robust_stability.m), [ROLMIP manual §7.1](https://rolmip.github.io/) | Affine $P$, one cell, Direct | Positive optimized margin and strict-feasibility conclusion | Decision degree and solver |
| [`continuous_time_robust_stability.m`](https://github.com/TheBigoranger/GriD-LMIA/blob/main/example/continuous_time_robust_stability.m), Yu and Duan (2013), Example 4.9 | Constant $P$, one cell, Direct | Positive endpoint residual for the printed certificate | Parameter bounds, solver, normalization |
| [`mass_spring_damper_stability.m`](https://github.com/TheBigoranger/GriD-LMIA/blob/main/example/mass_spring_damper_stability.m), Yu and Duan (2013), Example 4.10 | Constant $P$, one cell per axis, Direct | One parameter box certified and absence of a common quadratic certificate reported for the second | Parameter boxes, decision degree, solver |

The first four scripts exercise the same terminal bracket composition described
by [`pdlmi.horzcat`](/GriD-LMIA/documents/reference/pdlmi/#api-horzcat) and
[`pdlmi.vertcat`](/GriD-LMIA/documents/reference/pdlmi/#api-vertcat). The full
behavior contract is on the
[`pdlmi` reference](/GriD-LMIA/documents/reference/pdlmi/#pdlmi-concatenation).
The delay examples separate the matrix Markov–Lukács SOS path from a ten-cell
Direct path, while the ROLMIP and textbook examples compare feasibility margins
or residual signs because the decision matrices are nonunique.

## Manual Reproduction Boundary

The root examples are intentionally excluded from `+tests` and from
`tests.run_all()`. Their solver-specific runs are manual reproduction checks.
A nonzero YALMIP code is classified through `yalmiperror`. Resource and
numerical outcomes retain the `unknown` classification.
The scripts compare objectives, margins, or residual signs instead of requiring
identical nonunique decision matrices.

<span id="known-scalar-data"></span>

## Scalar `pdmat`

```matlab
A = pdmat({[0 1]}, {1, 3}, Degree=1);
val = A.evaluate(0.25)
```

```text
val =
    1.5000
```

<span id="known-matrix-data"></span>

## Tensor-Grid `pdmat`

```matlab
A = pdmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=[1 1]);
A.lbls()
```

```text
ans =
     0     0
     0     1
     1     0
     1     1
```

## Function-Backed `pdmat`

```matlab
F = pdmat({[0 pi]}, @(rho) sin(rho));
F.evaluate(pi/2)
```

```text
ans =
     1
```

Function-backed objects that omit explicit `Degree` preserve the exact function
handle and stay in evaluation workflows.

<span id="rate-derivative"></span>

## `pdvar` And `rhodiff`

```matlab
yalmip('clear')
P = pdvar(1, {[0 1 2]}, RateBounds=[-1 1]);
D = rhodiff(P);

D.NumRateRows
D.RateBounds
```

```text
ans =
     2

ans =
    -1     1
```

<span id="direct-constraint"></span>

## `pdlmi.toYalmip`

```matlab
yalmip('clear')
P = pdvar(2, {[0 1]}, "symmetric");
C = P >= 0;
F = toYalmip(C);
isa(F, "lmi") || isa(F, "constraint")
length(F)
```

```text
ans =
  logical
   1

ans =
     2
```

`F` is a YALMIP constraint array. Use ordinary YALMIP solver calls such as `optimize(F, objective, sdpsettings(...))`.

## Deterministic Full-Box Selection

Start with the [certificate-selection workflow](/GriD-LMIA/examples/certificate-selection/)
for a complete Direct-to-Pólya selection, stable six-constraint export, and the
boundary between deterministic assembly and solver execution.

The [`useFullBox` reference](/GriD-LMIA/documents/reference/pdlmi/usefullbox/#deterministic-transcript-example)
contains a solver-independent transcript that compares direct assembly, the
minimum full-box order, an explicit higher order, replacement of a Pólya
selection, and `toYalmip` export counts.

## Deterministic Putinar Selection

The [`usePutinar` reference](/GriD-LMIA/documents/reference/pdlmi/useputinar/#deterministic-transcript-example)
contains a solver-independent transcript that compares direct assembly, the
minimum Putinar order, an explicit higher order, replacement of a Pólya
selection, and `toYalmip` export counts.

## Deterministic SparseFullBox Selection

The [`useSpBox` reference](/GriD-LMIA/documents/reference/pdlmi/usespbox/#deterministic-transcript)
compares an intermediate sliding tensor-window certificate with its exact Direct and
FullBox endpoints, and records the corresponding read-only state.

## Deterministic SparsePutinar Selection

The [`useSpPut` reference](/GriD-LMIA/documents/reference/pdlmi/usespput/#examples)
compares an intermediate tensor-window certificate with its Direct and dense
Putinar endpoints. It also records the two-dimensional size-one behavior and
the read-only `CliqueSize` state.

## Solver Smoke Cases

The solver-facing smoke examples from [`+tests/+pdlmi/test_solver_smoke.m`](https://github.com/TheBigoranger/GriD-LMIA/blob/main/%2Btests/%2Bpdlmi/test_solver_smoke.m) are documented on a dedicated page:

- [Parameter-dependent Lyapunov variable](/GriD-LMIA/examples/solver-smoke/#parameter-dependent-lyapunov-variable)
- [Block PD-LMI objective](/GriD-LMIA/examples/solver-smoke/#block-pd-lmi-objective)

## Current Solver Boundary

The package currently assembles direct or Pólya-elevated coefficient-wise
constraints and the opt-in fixed-order Putinar, SparsePutinar, SparseFullBox, and FullBox
Gram certificates. Solver calls and residual diagnostics use YALMIP's public interfaces.

## See Also

[LPV induced-L2-gain modeling guide](/GriD-LMIA/documents/math/modeling-and-analysis/dpd-lmi-and-lpv-l2-gain/) ·
[Certificate map](/GriD-LMIA/documents/math/sos-certificates/) ·
[`toYalmip`](/GriD-LMIA/documents/reference/pdlmi/toyalmip/)
