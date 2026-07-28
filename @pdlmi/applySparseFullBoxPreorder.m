function out = applySparseFullBoxPreorder(obj, varargin)
    %APPLYSPARSEFULLBOXPREORDER Apply a tensor-window full-box certificate.
    %
    %   Syntax:
    %     out = obj.applySparseFullBoxPreorder()
    %     out = obj.applySparseFullBoxPreorder(bandWidth)
    %     out = obj.applySparseFullBoxPreorder(bandWidth, order)
    %
    %   Arguments:
    %     bandWidth - Positive integer tensor-window side length; default 2.
    %     order     - Optional admissible absolute full-box Gram order. The
    %                 default is floor(Residual.Degree/2) for one parameter and
    %                 ceil(Residual.Degree/2) otherwise.
    %
    %   Output:
    %     out - New pdlmi rebuilt with the selected certificate.
    %
    %   Width one always returns actual Direct state. Above that endpoint, a
    %   width at least order+1 returns actual dense FullBox state. Intermediate
    %   widths use one free PSD block per axis-aligned sliding window in every
    %   parity/mask tensor basis, with exact Bernstein coefficient matching.
    %   Widths two and three are the block-tridiagonal and
    %   block-pentadiagonal cases in one parameter. Increasing width gives a
    %   nested sufficient hierarchy, but need not improve a particular problem
    %   strictly.
    %
    %   Every physical cell and active rate row receives an independent
    %   certificate. Entry-wise inequalities additionally receive one
    %   independent scalar certificate per MATLAB column-major matrix entry.
    %   No positivity margin or solver call is inserted. The source wrapper is
    %   unchanged because assembly starts from Residual, so this selection
    %   replaces any earlier Pólya, Putinar, sparse full-box, or FullBox choice.
    %
    %   Invalid widths raise pdlmi:InvalidBandWidth. Invalid orders raise
    %   pdlmi:InvalidSparseFullBoxOrder, and insufficient orders raise
    %   pdlmi:SparseFullBoxOrderTooLow. Coefficient equality raises
    %   pdlmi:UnsupportedEqualityCertificate before width or order validation.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric", Degree=4);
    %     direct = P >= 0;
    %     sparse = direct.applySparseFullBoxPreorder(2, 2);

    if obj.Relation == "=="
        error("pdlmi:UnsupportedEqualityCertificate", ...
            "Coefficient equality supports direct assembly only.");
    end
    [args, validationMode] = parseApplyValidation(varargin);
    if numel(args) > 2
        error("pdlmi:InvalidApplyOptions", ...
            "Too many positional inputs were supplied.");
    end
    if isempty(args)
        bandWidth = 2;
    else
        bandWidth = args{1};
    end
    bandWidth = chkBandWidth(bandWidth);
    if numel(args) < 2
        order = chkSparseFullBoxOrder(obj.Residual);
    else
        order = chkSparseFullBoxOrder(obj.Residual, args{2});
    end

    out = pdlmi(obj.Residual, obj.Relation, ...
        UseSparseFullBoxPreorder=true, BandWidth=bandWidth, ...
        SparseFullBoxOrder=order, ValidationMode=validationMode);
end
