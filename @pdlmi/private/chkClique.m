function sizeOut = chkClique(sizeIn)
    %CHKCLIQUE Validate a positive Putinar tensor-window side length.
    %
    %   Syntax:
    %     sizeOut = chkClique(sizeIn)
    %
    %   Arguments:
    %     sizeIn - User supplied CliqueSize value.
    %
    %   Output:
    %     sizeOut - Positive integer scalar stored as double.
    %
    %   Example:
    %     cliqueSize = chkClique(2);
    %
    %   CliqueSize controls the side length of each sliding tensor-basis
    %   window for SparsePutinar. Endpoint normalization is owned by pdlmi, so
    %   this helper only validates the scalar shape and positivity.
    sizeOut = double(helper.chk(sizeIn, "pdlmi:InvalidCliqueSize", ...
        "CliqueSize", "numeric", "real", "finite", "integer", ...
        "positive", "scalar"));
end
