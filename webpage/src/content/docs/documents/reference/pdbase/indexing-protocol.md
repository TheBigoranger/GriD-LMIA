---
title: pdbase Indexing Protocol
description: Shared MATLAB end-index and scalar subscript-dispatch behavior.
---

<nav class="manual-trail"><a href="/GriD-LMIA/documents/">Documents</a><span>/</span><a href="/GriD-LMIA/documents/reference/pdbase/">pdbase</a><span>/</span><span>indexing protocol</span></nav>

## <span id="pdbase-end"></span>`end`

**Syntax:** `obj(:,end)`, `obj(end,:)`, and `k = end(obj,indexPosition,numberOfIndices)`.

**Returned value:** the selected matrix-payload dimension. Indexing applies to
the matrix payload and preserves the grid, physical cells, coefficient labels,
and rate rows.

`pdbase` supplies this protocol for the `pdmat` and `pdvar` `subsref` and
`subsasgn` implementations. Matrix parentheses indexing belongs to those
derived classes.

## <span id="pdbase-numArgumentsFromSubscript"></span>`numArgumentsFromSubscript`

**Syntax:** `n = numArgumentsFromSubscript(obj,subscript,context)`.

**Returned value:** always `1`. This tells MATLAB that a matrix subscript
produces one scalar object for subsequent dot dispatch, such as
`A(1,2).Degree`.

The method is infrastructure for MATLAB indexing with a fixed protocol.
Malformed matrix subscripts are validated by the derived `pdmat` or `pdvar`
method. This dispatch hook reports argument counts.

## Example

```matlab
A = pdmat({[0 1]}, {[1 2; 3 4], [5 6; 7 8]}, Degree=1);
last = A(1,end);
lastSize = size(last)
lastAtOne = last.evaluate(1)
```

```text
lastSize =
     1     1

lastAtOne =
     6
```

## Limitations and See Also

Only two-dimensional matrix-payload indexing is implemented by the derived
classes. See [`pdmat indexing`](/GriD-LMIA/documents/reference/pdmat/indexing-and-inspection/)
and [`pdvar indexing`](/GriD-LMIA/documents/reference/pdvar/indexing-and-inspection/)
for subscript forms, assignments, dynamic error prefixes, and modeling
boundaries.
