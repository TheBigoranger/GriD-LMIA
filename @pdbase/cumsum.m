function out = cumsum(obj, varargin)
    %CUMSUM Cumulative sum of every coefficient payload.
    %
    %   Syntax:
    %     C = cumsum(A)
    %     C = cumsum(A, dim)
    %     C = cumsum(A, direction)
    %     C = cumsum(A, dim, direction)
    %
    %   direction is "forward" or "reverse", case-insensitively.
    %
    %   Example:
    %     A = pdmat({[0 1]}, {[1 2; 3 4], [2 4; 6 8]}, Degree=1);
    %     C = cumsum(A, 2, "reverse");

    if isempty(varargin)
        out = unOp(obj, @(a) cumsum(a));
        return
    end

    prefix = string(class(obj));
    errId = prefix + ":InvalidCumsum";
    if numel(varargin) > 2
        error(errId, ...
            "%s cumsum accepts an optional dimension and direction.", prefix);
    end

    % A lone text argument is the direction form; otherwise the first
    % argument is the cumulative-sum dimension.
    arg = varargin{1};
    isDirection = (ischar(arg) && isrow(arg)) || ...
        (isstring(arg) && isscalar(arg));
    if numel(varargin) == 1 && isDirection
        dim = find(obj.MatrixSize ~= 1, 1);
        if isempty(dim)
            dim = 1;
        end
        direction = arg;
    else
        dim = helper.chk(arg, errId, ...
            "Cumulative-sum dimension must be a positive integer scalar.", ...
            "numeric", "real", "scalar", "finite", "integer", "positive");
        dim = double(dim);
        direction = "forward";
        if numel(varargin) == 2
            direction = varargin{2};
        end
    end

    if ~((ischar(direction) && isrow(direction)) || ...
            (isstring(direction) && isscalar(direction)))
        error(errId, ...
            "Cumulative-sum direction must be ""forward"" or ""reverse"".");
    end
    direction = lower(string(direction));
    if ~any(direction == ["forward", "reverse"])
        error(errId, ...
            "Cumulative-sum direction must be ""forward"" or ""reverse"".");
    end

    % Matrix payloads are singleton beyond dimension two. Short-circuiting
    % also avoids asking YALMIP to flip an sdpvar along an unsupported axis.
    if dim > 2
        out = unOp(obj, @(a) a, obj.MatrixSize);
    elseif direction == "forward"
        out = unOp(obj, @(a) cumsum(a, dim), obj.MatrixSize);
    else
        out = unOp(obj, ...
            @(a) flip(cumsum(flip(a, dim), dim), dim), obj.MatrixSize);
    end
end
