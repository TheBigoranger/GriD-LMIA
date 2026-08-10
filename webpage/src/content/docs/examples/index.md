---
title: Examples
description: Runnable GriD-LMIA workflows using current public APIs.
---

These examples are intentionally small and deterministic. They complement the reference pages with executable workflows.

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
