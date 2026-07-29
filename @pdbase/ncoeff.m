function n = ncoeff(obj)
    %NCOEFF Number of local Bernstein coefficients per cell.
    %
    %   Syntax:
    %     n = ncoeff(obj)
    %     n = obj.ncoeff()
    %
    %   Example:
    %     obj = pdbase({[0 1], [10 20]}, [1 1], 2);
    %     n = obj.ncoeff();

    n = prod(obj.Degree + 1);
end
