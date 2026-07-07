function sz = scanMats(vals, errId, msg)
    %SCANMATS Validate finite real numeric matrices and infer common size.
    %
    %   Syntax:
    %     sz = helper.scanMats(vals, errId)
    %     sz = helper.scanMats(vals, errId, msg)
    %
    %   Example:
    %     sz = helper.scanMats({eye(2), zeros(2)}, "pkg:BadMatrix");

    if nargin < 3
        msg = "Each payload must be a nonempty finite real numeric matrix.";
    end
    if isempty(vals)
        error(errId, "Data cells must not be empty.");
    end

    sz = [];
    for k = 1:numel(vals)
        oneSz = size(helper.chk(vals{k}, errId, msg, ...
            "numeric", "real", "finite", "matrix", "nonempty"));
        if isempty(sz)
            sz = oneSz;
        elseif ~isequal(sz, oneSz)
            error(errId, "All payloads must have the same matrix size.");
        end
    end
end
