function rv_g = limit_values(lim, w, xf, Ymat)
% Values that the rows of lim (see limit_set) bound, at the full point xf = [variables; lambda].
    arguments (Input)
        lim  (1,1) struct     % Monitored limits (output of limit_set).
        w    (1,1) struct     % Variable layout (output of build_layout).
        xf   (:,1) double     % Full variable vector of the point, lambda in the last row.
        Ymat                  % [pu] Bus admittance matrix (complex).
    end
    arguments (Output)
        rv_g (:,1) double     % [pu] Q of the generators, |V| or the larger |S| of a branch, per row.
    end
    rv_g = zeros(numel(lim.rv_bound), 1);
    if isempty(rv_g)
        return
    end
    cv_V = xf(w.rv_BusVi(1:2:end)) .* exp(1j*xf(w.rv_BusVi(2:2:end)));
    r_lambda = xf(end);
    for kind = ["Q","V","S"]
        lv  = lim.sv_kind == kind;
        idx = lim.iv_object(lv);
        switch kind
            case "Q"
                cv_S = cv_V(idx) .* conj(Ymat(idx,:) * cv_V);
                rv_g(lv) = imag(cv_S) - lim.rv_Qother(idx) .* (1 + r_lambda * lim.rv_load(idx));
            case "V"
                rv_g(lv) = abs(cv_V(idx));
            case "S"
                rv_S = zeros(numel(idx), 1);
                for k = 1:numel(idx)
                    cv_Vb = cv_V(lim.im_end(idx(k),:));
                    rv_S(k) = max(abs(cv_Vb .* conj(lim.c_Ybranch{idx(k)} * cv_Vb)));
                end
                rv_g(lv) = rv_S;
        end
    end
end
