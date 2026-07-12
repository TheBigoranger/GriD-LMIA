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
| Cell-local backend | `dpbase` stores tensor-grid metadata, nested `LocalValues`, local labels, counts, and coefficient inspection. | [`dpbase`](/DP-LMI-package/documents/reference/dpbase/) |
| Known matrix data | `dpmat` supports coefficient grids, explicit local values, function-only evaluation, and function handles with validated Bernstein evidence. | [`dpmat`](/DP-LMI-package/documents/reference/dpmat/) |
| Exact coefficient algebra | Supported coefficient-backed operations use degree elevation, common-grid refinement, and binomial-scaled Bernstein convolution. | [Bernstein utilities](/DP-LMI-package/documents/reference/bernstein-utilities/) |
| Decision expressions | `dpvar` creates continuous YALMIP-backed degree-0 or degree-1 Bernstein decisions; supported affine and known-data algebra can produce higher degrees. | [`dpvar`](/DP-LMI-package/documents/reference/dpvar/) |
| Rate derivatives | `rhodiff` creates discontinuous cell-local derivative expressions with scalar or tensor-grid rate-vertex rows and explicit or stored `RateBounds`. | [`rhodiff`](/DP-LMI-package/documents/reference/dpvar/rhodiff/) |
| Finite LMI assembly | `dplmi` directly constrains every active physical-cell, Bernstein-coefficient, and rate-vertex row, with optional Pólya degree elevation. | [`dplmi`](/DP-LMI-package/documents/reference/dplmi/) |
| Solver handoff | `toYalmip` returns the assembled YALMIP constraints for ordinary `optimize` calls. | [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) |
| Inspection and plots | `bernsteinTable`, `evaluate`, and one-/two-parameter `dpmat/plot` behavior are documented and tested. | [Reference lookup](/DP-LMI-package/documents/reference-index/) |

## Unsupported Public Layers

- Sum-of-squares positivity hierarchies.
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

## Solver Boundary

`dplmi` owns direct and Pólya-elevated coefficient assembly. After `toYalmip`, YALMIP owns
constraint combination, solver selection, `optimize`, and solver status. The
package's solver smoke tests prefer MOSEK when available and otherwise use
`lmilab`, but that test fallback is not a package-owned solver policy.

## See Also

[`Reference lookup`](/DP-LMI-package/documents/reference-index/) ·
[`Install And Download`](/DP-LMI-package/install/) ·
[`Bernstein Polynomial`](/DP-LMI-package/documents/math/bernstein-polynomial/) ·
[`Solver smoke examples`](/DP-LMI-package/examples/solver-smoke/)
