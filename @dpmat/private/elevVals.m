function vals = elevVals(obj, vals, fromDeg, toDeg, grid)
    %ELEVVALS Degree-elevate every physical cell in a LocalValues tree.
    %
    %   Syntax:
    %     vals = elevVals(obj, vals, fromDeg, toDeg, grid)
    %
    %   Example (via public algebra):
    %     A = dpmat({[0 1]}, {1}, Degree=0);
    %     B = dpmat({[0 1]}, {2, 3}, Degree=1);
    %     C = A + B;  % Elevates A before combining coefficients.
    %
    %   VALS is nested by physical cell and stores flat local Bernstein
    %   coefficient cells at each leaf. The returned tree has the same grid
    %   and represents the same polynomial at the higher degree. GRID may be
    %   omitted when the object's own grid is being used.

    if fromDeg == toDeg
        return
    end
    if nargin < 5
        grid = obj.GridInfo.Vectors;
    end

    nCell = cellfun(@numel, grid) - 1;
    vals = helper.mkNest(nCell, @(subs) obj.bernElev(helper.cellGet(vals, subs), fromDeg, toDeg));
end
