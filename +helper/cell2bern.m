function [flatCoeffs, cellSubs] = cell2bern(gridVectors, data, varargin)
    %HELPER.CELL2BERN Convert global Bernstein grid cells to local coefficients.
    %
    %   Syntax:
    %     flatCoeffs = helper.cell2bern(gridVectors, data)
    %     flatCoeffs = helper.cell2bern(gridVectors, data, Degree=m)
    %     [flatCoeffs, cellSubs] = helper.cell2bern(___)
    %
    %   Example:
    %     c = helper.cell2bern({[0 1 2]}, {10, 11, 12, 13, 14}, Degree=2);

    degOpt = parseOptions(varargin{:});
    info = internal.mkGrid(gridVectors, "cell2bern");
    [~, ~, ~, flatCoeffs, cellSubs] = internal.gridToLocal(data, info.Vectors, degOpt, "cell2bern");
end

function degOpt = parseOptions(varargin)
    degOpt = [];
    if mod(numel(varargin), 2) ~= 0
        error("cell2bern:InvalidOptions", "cell2bern options must be Name=Value pairs.");
    end

    for k = 1:2:numel(varargin)
        name = varargin{k};
        if ~(ischar(name) || (isstring(name) && isscalar(name)))
            error("cell2bern:InvalidOptions", "cell2bern option names must be strings or character vectors.");
        end
        name = string(name);
        switch name
            case "Degree"
                degOpt = varargin{k + 1};
            otherwise
                error("cell2bern:UnknownOption", "Unsupported cell2bern option: %s.", name);
        end
    end
end
