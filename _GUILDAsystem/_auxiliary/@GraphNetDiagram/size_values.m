function sct_v = size_values(obj, iv_k)
% Values of the size quantities (BranchWidthMode, MarkerSizeMode) at samples iv_k of the state.
%
% A branch has |P_from - P_to|/2 ("P"), |Q_from - Q_to|/2 ("Q"), the larger |I| of its two
% ends ("I") or its admittance quantity ("G", "B", "Y", "Ysvd"), from the power and
% current into the branch at each end. A component has |P|, |Q| or |P + jQ| of its
% injection ("P", "Q", "S"), and a bus those of the sum of the currents of its components
% (NaN, a tripped unit, counts as 0) at its voltage. "none" and a state of NaN give NaN.
    arguments (Input)
        obj
        iv_k (1,:) double  % Indices of the samples.
    end
    arguments (Output)
        sct_v (1,1) struct  % Fields Branch (n_branch x n_k), Bus (n_bus x n_k) and Comp (n_comp x n_k).
    end
    n_k  = numel(iv_k);
    cm_V = obj.sct_state.cm_Vbus(:, iv_k);
    cm_I = obj.sct_state.cm_Icomp(:, iv_k);
    n_br = obj.n_branch;

    s_mode = obj.BranchWidthMode;
    switch s_mode
        case {"P", "Q", "I"}
            cm_Vbr = full(obj.cm_Vbus2Vbranch * cm_V);
            cm_Ibr = obj.sct_state.cm_Ibranch(:, iv_k);
            cm_S   = cm_Vbr .* conj(cm_Ibr);
            if s_mode == "P"
                rm_br = abs(real(cm_S(1:2:end, :)) - real(cm_S(2:2:end, :)))/2;
            elseif s_mode == "Q"
                rm_br = abs(imag(cm_S(1:2:end, :)) - imag(cm_S(2:2:end, :)))/2;
            else
                rm_br = max(abs(cm_Ibr(1:2:end, :)), abs(cm_Ibr(2:2:end, :)));
            end
        case {"G", "B", "Y"}
            pd = obj.tab_branch.dynamics;
            cv_y = 1 ./ (pd.R + 1j*pd.X);
            rv = abs(cv_y);
            if s_mode == "G"
                rv = abs(real(cv_y));
            elseif s_mode == "B"
                rv = abs(imag(cv_y));
            end
            rm_br = repmat(rv, 1, n_k);
        case "Ysvd"
            rm_br = repmat(obj.tab_branch.dynamics.Ysvd, 1, n_k);
        otherwise
            rm_br = nan(n_br, n_k);
    end

    s_mode = obj.MarkerSizeMode;
    if s_mode == "none"
        rm_bus  = nan(obj.n_bus, n_k);
        rm_comp = nan(obj.n_component, n_k);
    else
        iv_bus  = obj.tab_component.bus;
        cm_Sc   = cm_V(iv_bus, :) .* conj(cm_I);
        cm_I0   = cm_I;
        cm_I0(isnan(cm_I0)) = 0;
        cm_Sb   = cm_V .* conj(sparse(iv_bus, 1:obj.n_component, 1, obj.n_bus, obj.n_component) * cm_I0);
        cm_Sb   = full(cm_Sb);
        switch s_mode
            case "P"; f = @(x) abs(real(x));
            case "Q"; f = @(x) abs(imag(x));
            otherwise; f = @abs;
        end
        rm_bus  = f(cm_Sb);
        rm_comp = f(cm_Sc);
    end
    sct_v = struct("Branch", reshape(rm_br, n_br, n_k), "Bus", reshape(rm_bus, obj.n_bus, n_k), ...
                   "Comp", reshape(rm_comp, obj.n_component, n_k));
end
