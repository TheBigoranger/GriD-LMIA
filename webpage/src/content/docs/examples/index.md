---
title: Examples
description: Runnable DP-LMI workflows using current public APIs.
---

These examples are intentionally small and deterministic. They complement the reference pages without replacing them.

## Setup And Verification

```matlab
projectRoot = "path/to/Differential Parameter-Dependent Linear Matrix Inequality";
addpath(genpath(projectRoot));
rmpath(genpath(fullfile(projectRoot, "doc")));

results = tests.run_all();
```

The test entry point runs helper, `dpbase`, `dpmat`, `dpvar`, and `dplmi` tests. `dpvar` and `dplmi` workflows require YALMIP on the MATLAB path.

## Scalar `dpmat`

```matlab
A = dpmat({[0 1]}, {1, 3}, Degree=1);
val = A.evaluate(0.25)
```

```text
val =
    1.5000
```

## Tensor-Grid `dpmat`

```matlab
A = dpmat({[0 1], [10 20]}, {1, 3; 5, 7}, Degree=1);
A.lbls()
```

```text
ans =
     0     0
     0     1
     1     0
     1     1
```

## Function-Backed `dpmat`

```matlab
F = dpmat({[0 pi]}, @(rho) sin(rho));
F.evaluate(pi/2)
```

```text
ans =
     1
```

Function-backed objects without explicit `Degree` preserve the exact function handle and are not coefficient evidence for algebra.

## `dpvar` And `rhodiff`

```matlab
P = dpvar(1, {[0 1 2]}, RateBounds=[-1 1]);
D = rhodiff(P);

D.HasRateDependence
D.RateBounds
```

```text
ans =
  logical
   1

ans =
    -1     1
```

## `dplmi.toYalmip`

```matlab
P = dpvar(2, {[0 1]}, "symmetric");
C = P >= 0;
F = toYalmip(C);
```

`F` is a YALMIP constraint array. Use ordinary YALMIP solver calls such as `optimize(F, objective, sdpsettings(...))`.

## Current Solver Boundary

The package currently assembles direct coefficient-wise constraints. It does not provide a package-owned solver wrapper, relaxation-lemma assembler, Polya assembler, or residual diagnostic layer.
