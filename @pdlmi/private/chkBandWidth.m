function bandWidth = chkBandWidth(bandWidth)
    %CHKBANDWIDTH Validate a sparse full-box tensor-window side length.
    %
    %   bandWidth must be a finite positive integer scalar. The certificate
    %   boundary owns this validation so constructor and apply forms share one
    %   stable pdlmi error identifier.

    bandWidth = double(helper.chk(bandWidth, ...
        "pdlmi:InvalidBandWidth", ...
        "BandWidth must be a finite positive integer scalar.", ...
        "numeric", "real", "finite", "integer", "positive", "scalar"));
end
