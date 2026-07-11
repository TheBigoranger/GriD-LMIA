# DP-LMI

This context describes parameter-dependent matrix inequalities represented by cell-local Bernstein polynomials and the certificates used to establish them.

## Language

**Residual**:
The `dpvar` matrix expression constrained relative to zero and retained as the source evidence for rebuilding a certificate.
_Avoid_: LMI expression, constraint expression

**Pólya degree**:
A nonnegative elevation increment applied in every parameter direction. It is distinct from the residual or decision polynomial degree and from physical grid refinement.
_Avoid_: Target degree, decision degree, grid-refinement level

## Example dialogue

**Developer**: “The Residual has degree two. Which Pólya degree should this certificate use?”

**Domain expert**: “Use Pólya degree one, so the same Residual is tested in a degree-three Bernstein basis without changing its decision degree or physical grid.”
