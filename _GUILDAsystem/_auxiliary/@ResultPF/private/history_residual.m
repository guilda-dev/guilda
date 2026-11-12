function rv = history_residual(cm_V, cm_Y, tab_PFcondition)
% Largest residual of the power equations at each column of cm_V
%
% The residuals of private power_equation of SolverPF: P - Pset (the angle - Varg at the
% slack bus) and Q - Qset at PQ buses, |V| - Vset at PV and slack buses.
    arguments (Input)
        cm_V            double  % [pu] Bus voltages, one column per iterate.
        cm_Y            double  % [pu] Bus admittance matrix.
        tab_PFcondition table   % Power flow conditions (Type, Varg, V, P, Q).
    end
    arguments (Output)
        rv (1,:) double         % [pu, rad] Largest |residual| of each column.
    end
    sv_type  = string(tab_PFcondition.Type);
    lv_slack = sv_type == "slack";
    lv_PQ    = sv_type == "PQ";
    cm_S = cm_V .* conj(cm_Y*cm_V);
    rm_r1 = real(cm_S) - tab_PFcondition.P;
    rm_r1(lv_slack,:) = angle(cm_V(lv_slack,:) .* exp(-1j*tab_PFcondition.Varg(lv_slack)));
    rm_r2 = abs(cm_V) - tab_PFcondition.V;
    rm_r2(lv_PQ,:) = imag(cm_S(lv_PQ,:)) - tab_PFcondition.Q(lv_PQ);
    rv = max(abs([rm_r1; rm_r2]), [], 1);
end
