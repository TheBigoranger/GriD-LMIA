---
title: Deterministic Certificate Selection
description: Compare Direct, Pólya, Putinar, SparsePutinar, SparseFullBox, and FullBox assembly before solver execution.
---

<nav class="manual-trail">
  <a href="/GriD-LMIA/examples/">Examples</a>
  <span>/</span>
  <span>Deterministic Certificate Selection</span>
</nav>

This workflow selects each implemented certificate family before any
optimization solve. The states and counts follow the public assembly contract
and remain independent of session-local YALMIP variable identifiers.

## Anisotropic Pólya Elevation

```matlab
yalmip('clear')
Pa = pdvar(1, {[0 1], [10 20]}, Degree=[2 0]);
directA = Pa >= 0;
polyaA = directA.usePolya([0 1]);
decisionDegree = Pa.Degree
polyaIncrement = polyaA.PolyaDegree
elevatedDegree = polyaA.Residual.Degree + polyaA.PolyaDegree
constraintCount = numel(polyaA.Constraints)
```

```text
decisionDegree = 1×2 double
     2     0

polyaIncrement = 1×2 double
     0     1

elevatedDegree = 1×2 double
     2     1

constraintCount = 6
```

The decision has three original labels and six labels after direction-wise
elevation. The zero second component of `Pa.Degree` keeps the decision constant
in that parameter, while `PolyaDegree=[0 1]` changes only the certificate
representation.

## Default, Higher-Order, And Replacement States

```matlab
yalmip('clear')
P = pdvar(1, {[0 1]}, Degree=2);
direct = P >= 0;
putinarDefault = direct.usePutinar();
boxDefault = direct.useFullBox();
boxHigher = boxDefault.useFullBox(2);
polya = direct.usePolya(1);
boxFromPolya = polya.useFullBox();
putinarFromBox = boxHigher.usePutinar();
Fbox = toYalmip(boxDefault);

directState = [direct.UseFullBoxPreorder, direct.FullBoxOrder, ...
    numel(direct.Constraints)]
defaultState = [boxDefault.UseFullBoxPreorder, boxDefault.FullBoxOrder, ...
    numel(boxDefault.Constraints)]
putinarState = [putinarDefault.UsePutinar, putinarDefault.PutinarOrder, ...
    numel(putinarDefault.Constraints)]
higherState = [boxHigher.FullBoxOrder, numel(boxHigher.Constraints)]
replacementState = [boxFromPolya.UsePolya, ...
    boxFromPolya.UseFullBoxPreorder, boxFromPolya.FullBoxOrder]
putinarReplacementState = [putinarFromBox.UsePutinar, ...
    putinarFromBox.UseFullBoxPreorder, putinarFromBox.PutinarOrder]
exportedConstraintCount = length(Fbox)
```

```text
directState = 1×3 double
     0     0     3
defaultState = 1×3 double
     1     1     5
putinarState = 1×3 double
     1     1     5
higherState = 1×2 double
     2     7
replacementState = 1×3 double
     0     1     1
putinarReplacementState = 1×3 double
     1     0     1
exportedConstraintCount = 5
```

For the degree-two residual, the default Putinar and FullBox states use two
PSD Gram blocks followed by three exact coefficient identities. FullBox order
two uses two PSD blocks followed by five identities. Selecting FullBox from the
Pólya wrapper clears the Pólya state, while selecting Putinar from the higher
FullBox wrapper clears the full-box state. The original `direct` object remains
unchanged.

## Sparse Certificates And Canonical Endpoints

```matlab
yalmip('clear')
P4 = pdvar(1, {[0 1]}, Degree=4);
direct4 = P4 >= 0;
sparsePutinar4 = direct4.useSpPut(2, 2);
sparse4 = direct4.useSpBox(2, 2);
direct4Endpoint = sparse4.useSpBox(1, 2);
full4Endpoint = sparse4.useSpBox(3, 2);
sparsePutinar4State = [sparsePutinar4.UseSparsePutinar, ...
    sparsePutinar4.SparsePutinarOrder, sparsePutinar4.CliqueSize, ...
    numel(sparsePutinar4.Constraints)]
sparse4State = [sparse4.UseSparseFullBoxPreorder, ...
    sparse4.SparseFullBoxOrder, sparse4.BandWidth, ...
    numel(sparse4.Constraints)]
direct4State = [direct4Endpoint.UseSparseFullBoxPreorder, ...
    direct4Endpoint.UseFullBoxPreorder, ...
    numel(direct4Endpoint.Constraints)]
full4State = [full4Endpoint.UseSparseFullBoxPreorder, ...
    full4Endpoint.UseFullBoxPreorder, full4Endpoint.FullBoxOrder, ...
    numel(full4Endpoint.Constraints)]
```

```text
sparsePutinar4State = 1×4 double
     1     2     2     8
sparse4State = 1×4 double
     1     2     2     8
direct4State = 1×3 double
     0     0     5
full4State = 1×4 double
     0     1     2     7
```

The two intermediate sparse wrappers each store three PSD blocks followed by
five identities, although they use distinct sliding tensor-window bases.
SparseFullBox width one rebuilds Direct state with five coefficient constraints.
Width three spans the order-two basis and rebuilds FullBox state with two dense
PSD blocks followed by the same five identities. Every selector is
value-semantic and rebuilds from the stored original residual.

## Solver And Equality Boundaries

`toYalmip` completes GriD-LMIA assembly, while YALMIP owns solver execution.
Read recovered decisions or objectives only after `sol.problem == 0`. A failed
solve at a fixed certificate order remains inconclusive for the continuous
inequality. Equality wrappers use Direct assembly, and every strict theoretical
margin must appear explicitly in the residual.

## See Also

[`usePolya`](/GriD-LMIA/documents/reference/pdlmi/usepolya/) ·
[`usePutinar`](/GriD-LMIA/documents/reference/pdlmi/useputinar/) ·
[`useSpPut`](/GriD-LMIA/documents/reference/pdlmi/usespput/) ·
[`useSpBox`](/GriD-LMIA/documents/reference/pdlmi/usespbox/) ·
[`useFullBox`](/GriD-LMIA/documents/reference/pdlmi/usefullbox/) ·
[`toYalmip`](/GriD-LMIA/documents/reference/pdlmi/toyalmip/) ·
[Solver Smoke Cases](/GriD-LMIA/examples/solver-smoke/)
