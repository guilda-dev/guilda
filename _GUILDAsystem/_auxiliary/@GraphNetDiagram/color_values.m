function [rm_branch, rm_link, rm_bus] = color_values(obj, iv_k)
% Color values of ColorMode for the branches and links, and of BusColorMode for the buses, at samples iv_k of the state.
%
% BusColorMode "V" gives |V| and "angle" the angle of V in degrees of each bus; then the
% branches and links have no value (NaN), whatever ColorMode is: the bus quantity takes
% the colorbar. With BusColorMode "none" the buses have no value (NaN) and the branches
% and links take the values of ColorMode below.
%
% "Loss": the active-power loss P_from + P_to of each branch, with S_end = V_end*conj(I_end)
% the power into the branch at each end, so the line charging and the tap are included (no
% link value). An end with NaN counts as 0 and both ends NaN give NaN; a value with
% |v| < 1e-12*max(1, |P_from| + |P_to|) (round-off of a lossless branch) is 0.
% "I": |I_from| of each branch and |I| of each component; "P": the mean of |P_from| and
% |P_to| of each branch and P of each component (signed); "Q": |Q_from + Q_to| of each
% branch and Q of each component (signed).
% Other modes ("none", "user") give NaN. The link value is also the color value of the
% component (reflect_color_mode). One sparse product for all samples.
    arguments (Input)
        obj
        iv_k (1,:) double  % Indices of the samples.
    end
    arguments (Output)
        rm_branch (:,:) double  % Values of the branches (n_branch x n_k).
        rm_link (:,:) double    % Values of the links (n_comp x n_k).
        rm_bus (:,:) double     % Values of the buses (n_bus x n_k).
    end
    n_k  = numel(iv_k);
    n_br = obj.n_branch;
    n_c  = obj.n_component;
    s_mode = obj.ColorMode;
    rm_bus = nan(obj.n_bus, n_k);
    if obj.BusColorMode ~= "none" && ~isempty(obj.sct_state)
        cm_V = obj.sct_state.cm_Vbus(:, iv_k);
        if obj.BusColorMode == "V"
            rm_bus = abs(cm_V);
        else
            rm_bus = rad2deg(angle(cm_V));
        end
        rm_bus = reshape(rm_bus, obj.n_bus, n_k);
        s_mode = "none";                                       % one colorbar: the bus quantity
    end
    if ~any(s_mode == ["Loss", "I", "P", "Q"]) || isempty(obj.sct_state)
        rm_branch = nan(n_br, n_k);
        rm_link   = nan(n_c, n_k);
        return
    end
    cm_V   = obj.sct_state.cm_Vbus(:, iv_k);
    cm_I   = obj.sct_state.cm_Icomp(:, iv_k);
    cm_Ibr = obj.sct_state.cm_Ibranch(:, iv_k);           % rows: from, to of each branch
    cm_Sc  = cm_V(obj.tab_component.bus, :) .* conj(cm_I);
    switch s_mode
        case "Loss"
            rm_P      = real(full(obj.cm_Vbus2Vbranch * cm_V) .* conj(cm_Ibr));
            rm_Pf     = rm_P(1:2:end, :);
            rm_Pt     = rm_P(2:2:end, :);
            lm_nan    = isnan(rm_Pf) & isnan(rm_Pt);
            rm_Pf(isnan(rm_Pf)) = 0;                            % sum 'omitnan' of the two ends
            rm_Pt(isnan(rm_Pt)) = 0;
            rm_branch = rm_Pf + rm_Pt;
            rm_branch(abs(rm_branch) < 1e-12*max(1, abs(rm_Pf) + abs(rm_Pt))) = 0;   % round-off
            rm_branch(lm_nan) = NaN;
            rm_link   = nan(n_c, n_k);
        case "I"
            rm_branch = abs(cm_Ibr(1:2:end, :));
            rm_link   = abs(cm_I);
        otherwise
            cm_S = full(obj.cm_Vbus2Vbranch * cm_V) .* conj(cm_Ibr);
            if s_mode == "P"
                rm_branch = (abs(real(cm_S(1:2:end, :))) + abs(real(cm_S(2:2:end, :))))/2;
                lm_nan    = isnan(rm_branch);                  % mean 'omitnan' of the two ends
                rm_one    = max(abs(real(cm_S(1:2:end, :))), abs(real(cm_S(2:2:end, :))));
                rm_branch(lm_nan) = rm_one(lm_nan);
                rm_link   = real(cm_Sc);
            else
                rm_Q      = imag(cm_S);
                rm_Q(isnan(rm_Q)) = 0;                          % sum 'omitnan' of the two ends
                rm_branch = abs(rm_Q(1:2:end, :) + rm_Q(2:2:end, :));
                rm_link   = imag(cm_Sc);
            end
    end
    rm_branch = reshape(rm_branch, n_br, n_k);
    rm_link   = reshape(rm_link, n_c, n_k);
end
