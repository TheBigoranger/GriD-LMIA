function object = fixture(owner, rates, bounds)
    %FIXTURE Distinct matrix controls on unequal cells; symbolic rows stay affine.
    if nargin < 3, bounds = [-2 3]; end
    grid = {[0 2 5]};
    if owner == "pdvar"
        object = pdvar(2, grid, 'full', Degree=2, RateBounds=bounds);
    else
        values = {[1 2; 7 11], [3 -5; 13 17], [19 23; -29 31], ...
            [37 -41; 43 47], [53 59; 61 -67]};
        if owner == "pdmat"
            object = pdmat(grid, values, Degree=2, RateBounds=bounds);
        else
            object = pdbase(grid, [2 2], 2, ...
                {values(1:3), values(3:5)}, RateBounds=bounds);
        end
    end
    if rates, object = rhodiff(object); end
end
