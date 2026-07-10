---
title: Bernstein Backend Utilities
description: Backend degree, product, and grid-refinement operations.
---

<nav class="manual-trail">
  <a href="/DP-LMI-package/documents/">Documents</a>
  <span>/</span>
  <span>Bernstein backend utilities</span>
</nav>

These methods belong to the protected `dpbase` layer. They explain how
`dpmat` and `dpvar` share storage; ordinary modeling workflows should start
with those two user-facing classes.

## <span id="bernElev"></span>`bernElev`

### Purpose

Elevate a local Bernstein coefficient family from one degree to a higher
degree without changing the represented polynomial. It is used internally when
compatible operands need a common degree before addition or comparison.

### Syntax

```matlab
coeffsOut = bernElev(obj, coeffsIn, fromDegree, toDegree)
```

`toDegree` must be at least `fromDegree`; the coefficient payload must match
the object's parameter count and local label order. This is backend behavior,
not a supported standalone user entry point.

## <span id="bernProd"></span>`bernProd`

### Purpose

Multiply two local Bernstein coefficient families by adding multi-index labels
and accumulating the corresponding convolution terms. The output degree is the
sum of the operand degrees.

### Syntax

```matlab
coeffsOut = bernProd(obj, lhs, lhsDegree, rhs, rhsDegree)
```

The operands must have compatible parameter dimensions and matrix payload
sizes. `dpmat` and `dpvar` expose this behavior through their `mtimes` methods.

## <span id="mergeGrid"></span>`mergeGrid`

### Purpose

Find a common physical tensor grid for compatible coefficient-backed operands.
This includes function-backed `dpmat` objects constructed with an explicit
`Degree`, because those objects carry validated Bernstein coefficient evidence.
Operands must have the same parameter count, and the first and last grid node
must match exactly on every parameter axis. The result is the per-axis sorted
union of all interior nodes together with the shared endpoints.

### Syntax

```matlab
grid = mergeGrid(obj, errorId, otherGrid1, otherGrid2, ...)
```

After the union grid is formed, each operand is re-expressed on every physical
cell of that grid. Public algebra then performs degree elevation and addition,
or tensor Bernstein product convolution, on the aligned cell-local data. A
function-only `dpmat` constructed without explicit `Degree` has no coefficient
evidence and cannot enter this coefficient algebra.

## Example

The helpers are exercised through public algebra methods:

```matlab
A = dpmat({[0 1]}, {1, 2}, Degree=1);
B = dpmat({[0 0.5 1]}, {10, 20, 30}, Degree=1);
C = A + B;
C.GridInfo.Vectors{1}

P = dpmat({[0 1]}, {1, 2}, Degree=1) * ...
    dpmat({[0 1]}, {1, 2}, Degree=1);
P.Degree
```

```text
ans =
         0    0.5000    1.0000

ans =
     2
```

`bernElev`, `bernProd`, and `mergeGrid` are protected backend helpers; users
should invoke the corresponding public `dpmat` or `dpvar` operations instead
of calling these methods directly.

## See Also

[`dpmat matrix operations`](/DP-LMI-package/documents/reference/dpmat/matrix-operations/) ·
[`dpvar matrix operations`](/DP-LMI-package/documents/reference/dpvar/matrix-operations/) ·
[`dpbase storage inspection`](/DP-LMI-package/documents/reference/dpbase/storage-inspection/)
