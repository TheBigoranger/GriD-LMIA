function validateDplmiMatrix(mat)
    %VALIDATEDPLMIMATRIX Enforce the shared square/symmetric LMI contract.

    if ~isequal(size(mat, 1), size(mat, 2))
        error("dplmi:InvalidMatrixSize", ...
            "DP-LMI constraints require square coefficient matrices.");
    end
    if isa(mat, "sdpvar")
        symmetric = ishermitian(mat);
    else
        symmetric = norm(mat - mat', inf) <= 1e-10;
    end
    if ~symmetric
        error("dplmi:NonSymmetricExpression", ...
            "DP-LMI constraints require symmetric or Hermitian coefficient matrices.");
    end
end
