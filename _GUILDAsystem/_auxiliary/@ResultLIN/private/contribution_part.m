function S_part = contribution_part(S, sv_selected)
% Part of elements in one section: the connected model S (a section of c_section) with
% only the terms of the owners sv_selected (sct_term of SolverLIN.solve), summed.
%
% The fields A ... E (and, for the network, cm_Y) are those of the terms of the owners; the
% other fields (names, sizes, the bus voltages cv_V, tab_owner) are those of S. sct_term
% keeps the terms of the owners, so that the part of a part is again a sum of terms; the
% energy-function blocks (sct_hessian) are left out. sv_selected marks the part for
% section_model (the outputs that are a state or a bus voltage). Used by get_contribution
% and plot_contribution.
    arguments (Input)
        S struct                     % Connected model of a section (with sct_term).
        sv_selected (:,1) string     % Owners of the part.
    end
    arguments (Output)
        S_part struct                % Connected model of the part.
    end
    T = S.sct_term;
    lv_sel = ismember(T.sv_owner, sv_selected);
    S_part = S;
    if isfield(S_part, "sct_hessian")
        S_part = rmfield(S_part, "sct_hessian");
    end
    S_part.A = gather_terms(T.A, lv_sel, size(S.A));
    S_part.B = gather_terms(T.B, lv_sel, size(S.B));
    S_part.C = gather_terms(T.C, lv_sel, size(S.C));
    S_part.D = gather_terms(T.D, lv_sel, size(S.D));
    S_part.E = gather_terms(T.E, lv_sel, size(S.E));
    if isfield(S, "cm_Y")
        n_v = S.n_v;
        Yr = gather_terms(T.Y, lv_sel, [n_v, n_v]);
        S_part.cm_Y = Yr(1:2:end, 1:2:end) + 1j*Yr(2:2:end, 1:2:end);
    end
    % the terms of the owners only
    iv_keep = find(lv_sel);
    for s = string(fieldnames(T))'
        if s ~= "sv_owner" && isnumeric(T.(s)) && size(T.(s), 2) == 4
            T.(s) = T.(s)(ismember(T.(s)(:, 3), iv_keep), :);
        end
    end
    S_part.sct_term = T;
    S_part.sv_selected = sv_selected;
end


function M = gather_terms(rm_term, lv_owner, iv_size)
% Sum of the terms [Row, Column, Owner, Value] of the selected owners
    arguments (Input)
        rm_term (:,4) double         % Terms: row, column, owner (index in sv_owner), value.
        lv_owner (:,1) logical       % Selected owners.
        iv_size (1,2) double         % Size of the matrix.
    end
    arguments (Output)
        M double                     % Sum of the selected terms.
    end
    lv = lv_owner(rm_term(:,3));
    M = full(sparse(rm_term(lv,1), rm_term(lv,2), rm_term(lv,4), iv_size(1), iv_size(2)));
end
