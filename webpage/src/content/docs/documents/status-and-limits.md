---
title: Status And Limits
description: Central implemented-versus-reserved boundary for the DP-LMI MATLAB/YALMIP package.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <span>Status And Limits</span>
</nav>

Use this page before choosing a modeling or refinement workflow. It summarizes
the current code and test boundary; the class reference pages remain the
source for call forms, options, examples, and validation errors.

## Implemented And Tested

| Area | Current behavior | Reference |
| :--- | :--- | :--- |
| Cell-local backend | `pdbase` stores tensor-grid metadata, nested `LocalValues`, local labels, counts, and coefficient inspection. | [`pdbase`](/DP-LMI-package/documents/reference/pdbase/) |
| Known matrix data | `pdmat` supports coefficient grids, explicit local values, function-only evaluation, and function handles with validated Bernstein evidence. | [`pdmat`](/DP-LMI-package/documents/reference/pdmat/) |
| Exact coefficient algebra | Supported coefficient-backed operations use degree elevation, common-grid refinement, and binomial-scaled Bernstein convolution. | [Bernstein utilities](/DP-LMI-package/documents/reference/bernstein-utilities/) |
| Decision expressions | `pdvar` accepts every finite nonnegative constructor degree. Degree zero is parameter-independent; every positive degree shares complete coefficient faces across adjacent cells. | [`pdvar`](/DP-LMI-package/documents/reference/pdvar/) |
| Rate derivatives | `rhodiff` creates discontinuous cell-local derivative expressions with scalar or tensor-grid rate-vertex rows and explicit or stored `RateBounds`. | [`rhodiff`](/DP-LMI-package/documents/reference/pdvar/rhodiff/) |
| Finite LMI assembly | `pdlmi` directly constrains every active physical-cell, Bernstein-coefficient, and rate-vertex row. Pólya degree elevation is opt-in through `UsePolya`/`PolyaDegree` or `applyPolya`. | [`pdlmi`](/DP-LMI-package/documents/reference/pdlmi/) |
| Full box preordering assembly | `applyFullBoxPreorder([order])` is an opt-in dense Gram certificate: parity-specific Markov-Lukács blocks in one parameter and the complete subset-product box preordering in multiple parameters. | [`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/) |
| Solver handoff | `toYalmip` returns the assembled YALMIP constraints for ordinary `optimize` calls. | [`toYalmip`](/DP-LMI-package/documents/reference/pdlmi/toyalmip/) |
| Inspection and plots | `bernsteinTable`, `evaluate`, and one-/two-parameter `pdmat/plot` behavior are documented and tested. | [Reference lookup](/DP-LMI-package/documents/reference-index/) |

## Independent SOS Comparison Suite

The repository's optional
[`sos_validation/`](https://github.com/TheBigoranger/DP-LMI-package/tree/main/sos_validation)
suite compares the implemented certificate using SumOfSquares.jl 0.8.0,
explicit YALMIP, isolated SOSTOOLS 4.00, and the package assembler. It is not
required for normal package use and is not loaded by the MATLAB runtime.

## Unsupported Public Layers

- General-purpose MATLAB/YALMIP sum-of-squares hierarchies, automatic hierarchy
  selection, and package-owned solver wrappers remain unsupported. The fixed
  full box preordering certificate listed above is the supported opt-in
  SOS-family feature.
- A public de Casteljau subdivision or adaptive grid-refinement command.
- Package-owned strictness margins or strict-inequality options.
- Residual-bound certificates, post-solve certificate diagnostics, or an
  automatic conservatism report.
- Package-owned solver selection, solver wrappers, or replacement SDP plumbing.
- Nonlinear products with decision dependence on both operands.
- A public `dpdiff` class or removed node-grid storage contracts.

YALMIP and an SDP solver are dependencies for decision-variable and solver
workflows. ROLMIP, LPVTools, and ROMULOC are comparison and documentation
references only; they are not package runtime dependencies.

## Interpreting A Failed Coefficient Test

The direct coefficient condition is sufficient, not necessary. If one
coefficient constraint fails, the result says only that the current finite
certificate did not establish the continuous inequality. It does not prove
the underlying DP-LMI infeasible.

The [Bernstein background](/DP-LMI-package/documents/math/bernstein-polynomial/#four-different-refinements)
distinguishes pure degree elevation, physical subdivision, higher decision
degree, and a different relaxation hierarchy. Only use a refinement through a
documented public call; research context is not an executable package feature.

For the mathematical relationships among global SOS, Bernstein coefficient
tests, Pólya elevation, Putinar modules, Schmüdgen preorderings, and exact
one-dimensional interval forms, use
[SOS Certificates On A Hypercube](/DP-LMI-package/documents/math/sos-certificates/).

## Solver Boundary

`pdlmi` owns direct and opt-in Pólya-elevated coefficient assembly plus the
opt-in fixed-order full box preordering. After `toYalmip`, YALMIP owns
constraint combination, solver selection, `optimize`, and solver status. The
package's solver smoke tests prefer MOSEK when available and otherwise use
`lmilab`, but that test fallback is not a package-owned solver policy.

## See Also

[`Reference lookup`](/DP-LMI-package/documents/reference-index/) ·
[`Install And Download`](/DP-LMI-package/install/) ·
[`Bernstein Polynomial`](/DP-LMI-package/documents/math/bernstein-polynomial/) ·
[`SOS Certificates`](/DP-LMI-package/documents/math/sos-certificates/) ·
[`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/pdlmi/applyfullboxpreorder/) ·
[`Solver smoke examples`](/DP-LMI-package/examples/solver-smoke/)
