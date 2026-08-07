function band = chkBand(band)
    %CHKBAND Validate a positive tensor-window side length.
    %
    %   Syntax:
    %     band = chkBand(band)
    %
    %   Arguments:
    %     band - User supplied BandWidth value.
    %
    %   Output:
    %     band - Positive integer scalar stored as double.
    %
    %   Example:
    %     bandWidth = chkBand(3);
    %
    %   BandWidth controls the side length of each sparse full-box tensor
    %   window. Endpoint normalization is owned by pdlmi, so this helper only
    %   validates the scalar shape and positivity.
    band = double(helper.chk(band, "pdlmi:InvalidBandWidth", ...
        "BandWidth", "numeric", "real", "finite", "integer", ...
        "positive", "scalar"));
end
