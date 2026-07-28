function F = toYalmip(obj)
    %TOYALMIP Concatenate stored pdlmi entries into YALMIP constraints.
    %
    %   Syntax:
    %     F = toYalmip(C)
    %     F = C.toYalmip()
    %
    %   Arguments:
    %     C - pdlmi wrapper containing assembled constraint entries.
    %
    %   Output:
    %     F - Concatenated YALMIP constraint object for optimize, or one
    %         logical for a known pdmat Direct/Pólya certificate.
    %
    %   Example:
    %     P = pdvar(2, {[0 1]}, "symmetric");
    %     F = toYalmip(P <= 0);
    %     known = pdmat([0 1], {1, 2}, Degree=1);
    %     tf = toYalmip(known >= 0);
    %
    %   A false known-data result issues pdlmi:InconclusiveCertificate once
    %   per call; it does not prove violation on the continuous parameter box.

    if isa(obj.Residual, "pdmat") && ...
            ~isempty(obj.Constraints) && ...
            all(cellfun(@islogical, obj.Constraints))
        % Known Direct/Pólya certificates export one scalar logical. Keep this
        % path class-gated so decision-free pdvar expressions retain their
        % established YALMIP concatenation and warning behavior.
        F = all(cellfun(@(val) all(logical(val), "all"), ...
            obj.Constraints));
        if ~F
            warning('pdlmi:InconclusiveCertificate', ...
                ['The selected sufficient coefficient certificate failed. ' ...
                'This does not prove a violation or indefiniteness over the continuous parameter domain.']);
        end
        return
    end

    % Keep storage inspectable as one constraint per coefficient and perform
    % the solver-facing concatenation once, in the same stored order.
    F = [obj.Constraints{:}];
end
