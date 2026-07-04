function varargout = size(obj, dim)
    %SIZE Matrix size of the coefficient payloads stored by a dpbase object.
    %
    %   Syntax:
    %     sz = size(obj)
    %     n = size(obj, dim)
    %     [m, n] = size(obj)
    %
    %   Example:
    %     obj = dpbase({[0 1]}, [2 3], 0);
    %     sz = size(obj);

    sz = obj.MatrixSize;
    if nargin == 2
        % Match MATLAB matrix behavior: dimensions after row/column are singleton.
        if dim <= 2
            varargout{1} = sz(dim);
        else
            varargout{1} = 1;
        end
        return
    end

    if nargout <= 1
        % size(obj) returns the stored 1x2 payload shape as one output.
        varargout{1} = sz;
        return
    end

    % [m,n,...] = size(obj) splits the matrix shape across outputs, with
    % trailing dimensions reported as singleton.
    varargout = cell(1, nargout);
    for k = 1:nargout
        if k <= 2
            varargout{k} = sz(k);
        else
            varargout{k} = 1;
        end
    end
end
