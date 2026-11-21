function flow_values(obj)
% Compute the flow of every branch and link at every sample of the state (FlowMode) and its scale.
%
% The flow q of a branch is signed, positive from its "from" end to its "to" end:
% (P_from - P_to)/2 ("P") or (Q_from - Q_to)/2 ("Q") of the powers into the branch at its
% two ends, or the larger |I| of its two ends ("I") with the sign of the "P" flow (of the
% "Q" flow when it is 0). The flow of a link is positive from the component to its bus:
% P, Q, or |I| with the sign of P (of Q when it is 0) of the injection of the component.
% "none" and a state of NaN give NaN. The scale r_qmax is the largest finite |q| over the
% branches, the links and all samples (NaN when there is none). The rows of rm_q are the
% branches, then the links; its columns the samples.
    arguments (Input)
        obj
    end
    if isempty(obj.sct_state)
        return
    end
    cm_V  = obj.sct_state.cm_Vbus;
    cm_I  = obj.sct_state.cm_Icomp;
    n_t   = size(cm_V, 2);
    n_all = obj.n_branch + obj.n_component;
    s_mode = obj.FlowMode;
    if s_mode == "none"
        rm_q = nan(n_all, n_t);
    else
        cm_Vbr = full(obj.cm_Vbus2Vbranch * cm_V);
        cm_Ibr = obj.sct_state.cm_Ibranch;
        cm_S   = cm_Vbr .* conj(cm_Ibr);
        cm_Sbr = (cm_S(1:2:end, :) - cm_S(2:2:end, :))/2;       % from -> to
        cm_Sc  = cm_V(obj.tab_component.bus, :) .* conj(cm_I);   % component -> bus
        cm_Sbr = reshape(cm_Sbr, obj.n_branch, n_t);
        cm_Sc  = reshape(cm_Sc, obj.n_component, n_t);
        switch s_mode
            case "P"
                rm_q = [real(cm_Sbr); real(cm_Sc)];
            case "Q"
                rm_q = [imag(cm_Sbr); imag(cm_Sc)];
            otherwise
                rm_mag = [reshape(max(abs(cm_Ibr(1:2:end, :)), abs(cm_Ibr(2:2:end, :))), obj.n_branch, n_t); abs(cm_I)];
                cm_Sall = [cm_Sbr; cm_Sc];
                rm_sign = sign(real(cm_Sall));
                lm_zero = rm_sign == 0;
                rm_sign(lm_zero) = sign(imag(cm_Sall(lm_zero)));
                rm_q = rm_mag .* rm_sign;
        end
    end
    rv_q = abs(rm_q(isfinite(rm_q)));
    obj.sct_flow.rm_q   = rm_q;
    obj.sct_flow.r_qmax = max([rv_q; NaN]);
end
