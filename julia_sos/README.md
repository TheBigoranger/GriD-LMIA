# Julia SOS Comparison Baseline

This directory contains an optional Julia oracle for small SOS and interval
nonnegativity comparisons. It is independent of the MATLAB/YALMIP runtime and
is not required for normal DP-LMI package use.

## Setup

From the repository root, instantiate and precompile the isolated environment:

```powershell
julia --project=julia_sos -e 'using Pkg; Pkg.resolve(); Pkg.instantiate(); Pkg.precompile(); Pkg.status()'
```

SCS is the required solver. `jump_smoke.jl` reports whether the optional
`Mosek` and `MosekTools` packages are visible, but neither is required.

## Run

```powershell
julia --project=julia_sos julia_sos/jump_smoke.jl
julia --project=julia_sos julia_sos/sos_smoke.jl
julia --project=julia_sos julia_sos/run_all.jl
```

## Markov-Lukacs comparison

`add_markov_lukacs!` adds an explicit Gram-matrix representation for a scalar
polynomial nonnegative on `[a,b]`. It accepts either ascending physical-variable
power coefficients or Bernstein coefficients in DP-LMI endpoint-label order.
The implementation normalizes to `t=(rho-a)/(b-a)` and independently matches
power coefficients; it does not call the SumOfSquares certificate compiler.

The current scope is deliberately small: scalar polynomials, one interval, and
dense PSD Gram matrices. Matrix polynomials, multivariate domains, MATLAB data
exchange, and production SOS assembly remain outside this comparison baseline.
