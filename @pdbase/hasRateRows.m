function tf = hasRateRows(obj)
    %HASRATEROWS True when LocalValues contains explicit rate-vertex rows.
    %
    %   Nonempty RateBounds alone is metadata and does not make an ordinary
    %   one-row coefficient tree into rate-row storage.

    tf = false;
    cells = obj.cells();
    for k = 1:size(cells, 1)
        coeffs = obj.coeffs(cells(k, :));
        hasRows = size(coeffs, 1) > 1;
        if k > 1 && hasRows ~= tf
            error("pdbase:InvalidCoefficientRows", ...
                "LocalValues cannot mix ordinary and rate-vertex rows across physical cells.");
        end
        tf = hasRows;
    end
end
