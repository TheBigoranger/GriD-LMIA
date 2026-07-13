---
title: dplmi applyFullBoxPreorder
description: Rebuild a DP-LMI residual with a fixed-order full box Bernstein-Gram certificate.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <a href="/DP-LMI-package/documents/reference/dplmi/">dplmi</a>
  <span>/</span>
  <span>applyFullBoxPreorder</span>
</nav>

## Purpose

Create a new `dplmi` that represents the stored residual with the implemented
cell-local full box Bernstein-Gram preordering.

## Syntax

```matlab
Cbox = C.applyFullBoxPreorder()
Cbox = C.applyFullBoxPreorder(order)
```

## Description

The no-argument form selects the smallest admissible absolute order. The
explicit form selects `order`; it does not add `order` to the residual degree.
Both forms rebuild from `C.Residual` and `C.Relation`, return a new object, and
leave `C` unchanged. Reapplication therefore replaces an earlier full-box
order or a Pólya selection instead of compounding either one.

For a one-parameter residual of degree $m$, the minimum is
$\lfloor m/2\rfloor$. Even-degree residuals use an unweighted Gram block plus
an $\alpha(1-\alpha)$-weighted block when that block has a nonempty basis.
Odd-degree residuals use separate $\alpha$- and
$(1-\alpha)$-weighted blocks.

For two or more parameters, the minimum is $\lceil m/2\rceil$. The
certificate contains one Gram term for every subset product of the box
generators $\alpha_s(1-\alpha_s)$. A term whose tensor Gram degree would have
a negative component is omitted.

Assembly creates independent Gram variables for every physical cell and every
active rate-vertex row. Each present Gram matrix is constrained positive
semidefinite, then exact identities match every Bernstein coefficient. For a
`<=` relation, the target coefficients are negated before positive-
semidefinite matching; for `>=`, the residual is matched directly. No implicit
positivity margin is added.

## Arguments And Options

| Input | Description |
| :--- | :--- |
| `C` | Any `dplmi` object. Its stored `Residual` and `Relation` are the source for the rebuilt certificate. |
| `order` | Optional finite nonnegative integer scalar. It is an absolute full-box order and must meet the dimension-dependent minimum. |

## Returned Object

`Cbox` is a new `dplmi` with `UsePolya=false`,
`UseFullBoxPreorder=true`, and `FullBoxOrder` equal to the selected order.
Within each cell and rate row, `Constraints` stores all PSD Gram-block
conditions before the exact coefficient identities. `toYalmip(Cbox)` returns
those stored constraints in the same order.

## Deterministic Transcript Example

```matlab
yalmip('clear')
P = dpvar(1, {[0 1]}, Degree=2);
direct = P >= 0;
boxDefault = direct.applyFullBoxPreorder();
boxHigher = boxDefault.applyFullBoxPreorder(2);
polya = direct.applyPolya(1);
boxFromPolya = polya.applyFullBoxPreorder();
Fbox = toYalmip(boxDefault);

fprintf("direct: fullBox=%d, order=%d, constraints=%d\n", ...
    direct.UseFullBoxPreorder, direct.FullBoxOrder, ...
    numel(direct.Constraints));
fprintf("default: fullBox=%d, order=%d, constraints=%d\n", ...
    boxDefault.UseFullBoxPreorder, boxDefault.FullBoxOrder, ...
    numel(boxDefault.Constraints));
fprintf("higher: order=%d, constraints=%d\n", ...
    boxHigher.FullBoxOrder, numel(boxHigher.Constraints));
fprintf("replacement: polya=%d, fullBox=%d, order=%d\n", ...
    boxFromPolya.UsePolya, boxFromPolya.UseFullBoxPreorder, ...
    boxFromPolya.FullBoxOrder);
fprintf("exported constraints=%d\n", length(Fbox));
```

```text
direct: fullBox=0, order=0, constraints=3
default: fullBox=1, order=1, constraints=5
higher: order=2, constraints=7
replacement: polya=0, fullBox=1, order=1
exported constraints=5
```

For the degree-two scalar residual, order one stores two PSD blocks followed by
three exact coefficient identities. Order two stores two PSD blocks followed
by five identities. The selection made from `polya` replaces Pólya assembly;
it does not use the already elevated constraints.

## Validation And Errors

- A malformed `order` raises `dplmi:InvalidFullBoxOrder`.
- A valid integer below the applicable minimum raises `dplmi:FullBoxOrderTooLow`.
- Rebuilding retains the ordinary `dplmi` expression, relation, square-matrix,
  and symmetry checks.
- Constructor selection errors are documented on the
  [`dplmi constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/)
  page, including `dplmi:InvalidUseFullBoxPreorder` and
  `dplmi:ConflictingRelaxations`.

## Limitations

This method implements the fixed-order full box preordering on each local
parameter box. It is not a general Putinar certificate, a general-domain SOS
interface, a full-space SOS representation, or an automatic hierarchy
selector. The independent `sos_validation/` suite supplies cross-backend
evidence; it is not a MATLAB runtime dependency.

## See Also

[`dplmi constructor`](/DP-LMI-package/documents/reference/dplmi/constructor/) ·
[`applyPolya`](/DP-LMI-package/documents/reference/dplmi/applypolya/) ·
[`toYalmip`](/DP-LMI-package/documents/reference/dplmi/toyalmip/) ·
[`Bernstein Polynomial`](/DP-LMI-package/documents/math/bernstein-polynomial/) ·
[`Status And Limits`](/DP-LMI-package/documents/status-and-limits/)
