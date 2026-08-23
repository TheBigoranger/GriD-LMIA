function F = vertcat(varargin)
    %VERTCAT Export and concatenate pdlmi and YALMIP constraint lists.
    %
    %   Syntax:
    %     F = [C1; C2; ...]
    %
    %   Vertical and horizontal YALMIP constraint concatenation have the same
    %   list semantics. See pdlmi/horzcat for accepted inputs and errors.

    F = horzcat(varargin{:});
end
