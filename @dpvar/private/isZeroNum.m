function tf = isZeroNum(val)
    %ISZERONUM True for finite real numeric zero arrays.

    tf = isnumeric(val) && isreal(val) && all(isfinite(val(:))) && ...
        ~isempty(val) && all(val(:) == 0);
end
