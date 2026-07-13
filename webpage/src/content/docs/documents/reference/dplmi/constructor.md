---
title: dplmi Constructor
description: Select direct, Pólya-elevated, or full-box DP-LMI assembly.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dplmi/">dplmi</a>
  <span>/</span>
  <span>constructor</span>
</nav>

## Purpose

Build a `dplmi` object from a square `dpvar` residual expression.

## Syntax

```matlab
C = dplmi(expr, relation)
C = dplmi(expr, relation, "UsePolya")
C = dplmi(expr, relation, UsePolya=true, PolyaDegree=d)
C = dplmi(expr, relation, "UsePolya", "PolyaDegree", d)
C = dplmi(expr, relation, "UseFullBoxPreorder")
C = dplmi(expr, relation, UseFullBoxPreorder=true)
C = dplmi(expr, relation, FullBoxOrder=r)
C = dplmi(expr, relation, UseFullBoxPreorder=true, FullBoxOrder=r)
C = dplmi(expr, relation, UseFullBoxPreorder=false, FullBoxOrder=r)
C = lhs <= rhs
C = lhs >= rhs
```

## Description

Direct coefficient-wise assembly is the default. `UsePolya` selects exact
degree elevation before coefficient constraints. `UseFullBoxPreorder` selects
a box-specific Bernstein-Gram certificate with positive-semidefinite Gram
blocks and exact coefficient identities. Pólya and full-box assembly are
mutually exclusive.

## Arguments And Options

| Input | Description |
| :--- | :--- |
| `expr` | Square `dpvar` residual expression, such as `P` or `diffP + P*A + A'*P`. |
| `relation` | Either `"<="` or `">="`. |
| `UsePolya` | Logical option. Default `false`. The bare flag `"UsePolya"` enables Pólya assembly with increment one. |
| `PolyaDegree` | Finite nonnegative integer scalar. Default `0`. Supplying it without `UsePolya` enables Pólya and warns `dplmi:ImplicitUsePolya`. |
| `UseFullBoxPreorder` | Logical scalar. Default `false`. The bare flag and explicit `true` select full-box assembly at the minimum admissible order. |
| `FullBoxOrder` | Finite nonnegative integer scalar. This is an absolute order, not a degree increment. Supplying it alone enables full-box assembly without a warning. |

When full-box assembly is active, the minimum order is
`floor(expr.Degree/2)` for one parameter and `ceil(expr.Degree/2)` for two or
more parameters. Explicitly pairing `UseFullBoxPreorder=false` with
`FullBoxOrder=r` keeps direct assembly active while retaining `r` as
inspectable metadata. This combination is valid and is not a relaxation
conflict.

## Returned Object

`C` is a `dplmi` object with private-set, inspectable `Constraints`, `Residual`,
`Relation`, `UsePolya`, `PolyaDegree`, `UseFullBoxPreorder`, and `FullBoxOrder`
properties. `Constraints` contains direct coefficient inequalities, Pólya-
elevated coefficient inequalities, or full-box PSD blocks and exact identities,
according to the selected mode.

## Examples

### Direct constructor form

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
C = dplmi(P, ">=");
class(C)
numel(C.Constraints)
```

```text
ans =
    'dplmi'

ans =
     2
```

The direct constructor is useful when code already has a residual expression
and a relation string.

### Comparison-overload form

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
C = P >= 0;
class(C)
numel(C.Constraints)
```

```text
ans =
    'dplmi'

ans =
     2
```

A scalar grid with one physical cell and degree 1 has two local Bernstein coefficients, so this direct constraint has two stored coefficient entries.

### Pólya option forms

```matlab
yalmip('clear')
P = dpvar(2, {[0 1]}, "symmetric");
one = dplmi(P, "<=", "UsePolya");
two = dplmi(P, "<=", UsePolya=true, PolyaDegree=2);
implicit = dplmi(P, "<=", PolyaDegree=2);
```

`one` uses an increment of one. `two` uses two, while `implicit` also uses two
and emits `dplmi:ImplicitUsePolya`. Pólya assembly rebuilds the stored residual
at the selected degree, constraining every elevated coefficient and active
rate-vertex row. It does not mutate the input expression.

### Full-box option forms

```matlab
yalmip('clear')
P = dpvar(1, {[0 1]}, Degree=2);
bare = dplmi(P, ">=", "UseFullBoxPreorder");
named = dplmi(P, ">=", UseFullBoxPreorder=true, FullBoxOrder=2);
implicit = dplmi(P, ">=", FullBoxOrder=2);
directWithMetadata = dplmi(P, ">=", ...
    UseFullBoxPreorder=false, FullBoxOrder=2);

fprintf("bare: fullBox=%d, order=%d\n", ...
    bare.UseFullBoxPreorder, bare.FullBoxOrder);
fprintf("named: fullBox=%d, order=%d\n", ...
    named.UseFullBoxPreorder, named.FullBoxOrder);
fprintf("implicit: fullBox=%d, order=%d\n", ...
    implicit.UseFullBoxPreorder, implicit.FullBoxOrder);
fprintf("explicit false: fullBox=%d, order=%d, constraints=%d\n", ...
    directWithMetadata.UseFullBoxPreorder, ...
    directWithMetadata.FullBoxOrder, ...
    numel(directWithMetadata.Constraints));
```

```text
bare: fullBox=1, order=1
named: fullBox=1, order=2
implicit: fullBox=1, order=2
explicit false: fullBox=0, order=2, constraints=3
```

`FullBoxOrder` alone selects full-box assembly without a warning. The final
form deliberately suppresses that implicit selection: it records order two,
but its three constraints are the direct degree-two coefficient conditions.

## Validation And Errors

- Nonsquare residual coefficient matrices raise `dplmi:InvalidMatrixSize`.
- Nonsymmetric or non-Hermitian coefficient matrices raise `dplmi:NonSymmetricExpression`.
- A non-`dpvar` residual raises `dplmi:InvalidExpression`; an unsupported relation raises `dplmi:InvalidRelation`.
- Nonlogical selectors raise `dplmi:InvalidUsePolya` or `dplmi:InvalidUseFullBoxPreorder`.
- Invalid Pólya increments or full-box orders raise `dplmi:InvalidPolyaDegree` or `dplmi:InvalidFullBoxOrder`.
- When full-box assembly is enabled, a valid integer below the applicable minimum raises `dplmi:FullBoxOrderTooLow`.
- `UsePolya=false` with a positive `PolyaDegree` raises `dplmi:ConflictingPolyaOptions`.
- Enabling both Pólya and full-box assembly raises `dplmi:ConflictingRelaxations`.
- Malformed, duplicate, or unknown options raise `dplmi:InvalidOptions`, `dplmi:DuplicateOption`, or `dplmi:UnknownOption`.

## Limitations

Full-box assembly is the implemented fixed-order box preordering. It is not a
general Putinar certificate, a general-domain SOS interface, or an automatic
hierarchy selector. No assembly mode adds an implicit positivity margin.

## See Also

[`applyPolya`](/DP-LMI-package/documents/reference/dplmi/applypolya/) · [`applyFullBoxPreorder`](/DP-LMI-package/documents/reference/dplmi/applyfullboxpreorder/) · [`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) · [`dpvar comparisons`](/DP-LMI-package/documents/reference/dpvar/comparisons/)
