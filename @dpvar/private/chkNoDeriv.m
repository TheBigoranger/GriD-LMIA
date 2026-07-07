function chkNoDeriv(val, errId)
    %CHKNODERIV Reject derivative rows in ordinary coefficient algebra.

    if isDeriv(val)
        error(errId, ...
            "Derivative-row dpvar expressions are not supported in ordinary dpvar algebra yet.");
    end
end
