function cliqueSize = chkCliqueSize(cliqueSize)
    %CHKCLIQUESIZE Validate a SparsePutinar tensor-window side length.
    %
    %   CliqueSize is a finite positive integer scalar. Validation remains at
    %   the certificate boundary so constructor and apply forms share one
    %   stable pdlmi error identifier.

    cliqueSize = double(helper.chk(cliqueSize, ...
        "pdlmi:InvalidCliqueSize", ...
        "CliqueSize must be a finite positive integer scalar.", ...
        "numeric", "real", "finite", "integer", "positive", "scalar"));
end
