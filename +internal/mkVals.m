function vals = mkVals(nCell, nCoeff, sz)
    %MKVALS Allocate nested physical cells of zero payloads.

    vals = internal.mkNest(nCell, @(~) zeroCoeff(nCoeff, sz));
end

function coeffs = zeroCoeff(nCoeff, sz)
    % Allocate an ordinary numeric zero for each local Bernstein label.
    coeffs = cell(1, nCoeff);
    for k = 1:nCoeff
        coeffs{k} = zeros(sz);
    end
end
