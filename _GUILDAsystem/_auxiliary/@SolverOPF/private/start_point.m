function x0 = start_point(x0, sv_bus, rm_V, tab_branch, s_method)
% Set the bus and branch-end values of the OPF initial point from bus voltages.
%
% Sets x0.<bus> to the start voltage of each bus ([Varg; V] in "AC OPF", Varg in
% "DC OPF") and x0.<branch>_<bus> of each branch end to its flow at these voltages, so that
% the branch definitions hold at x0 (a zero current is also a non-smooth point of |I|).
% "ELD" has no bus or branch variables. Called by build_problem (the flat start) and solve
% (the warm start).
    arguments (Input)
        x0         (1,1) struct    % Initial values by variable name.
        sv_bus     (:,1) string    % Bus tags (row names of the bus table).
        rm_V       (:,2) double    % [rad, pu] Start Varg and V of each bus of sv_bus.
        tab_branch table           % Branches: From, To, Y (2x2 pages), X, tap, phase, ...; row names = tags.
        s_method   (1,1) string    % "ELD", "DC OPF" or "AC OPF".
    end
    arguments (Output)
        x0                         % Initial values with the bus and branch-end values set.
    end
    if s_method == "ELD"
        return
    end
    for i_bus = 1:numel(sv_bus)
        if s_method == "AC OPF"
            x0.(sv_bus(i_bus)) = rm_V(i_bus,:).';
        else
            x0.(sv_bus(i_bus)) = rm_V(i_bus,1);
        end
    end
    sv_br = string(tab_branch.Properties.RowNames);
    for i_br = 1:height(tab_branch)
        sv_end = [tab_branch.From(i_br); tab_branch.To(i_br)];
        str    = sv_br(i_br) + "_" + sv_end;
        if s_method == "AC OPF"
            % The direction into the bus is positive, hence the minus sign.
            rm_Yij = - reshape(tab_branch.Y(i_br,:,:), 2, 2);
            rm_x0V = [x0.(sv_end(1)), x0.(sv_end(2))];
            cv_V0  = (rm_x0V(2,:) .* exp(1j*rm_x0V(1,:))).';
            cv_I0  = rm_Yij * cv_V0;
            cv_S0  = cv_V0 .* conj(cv_I0);
            x0.(str(1)) = [real(cv_S0(1)); imag(cv_S0(1)); real(cv_I0(1)); imag(cv_I0(1))];
            x0.(str(2)) = [real(cv_S0(2)); imag(cv_S0(2)); real(cv_I0(2)); imag(cv_I0(2))];
        else
            % MATPOWER flow b*(θi - θj - phase) from bus i, b = 1/(X*tap) (see build_branch)
            b     = 1/(tab_branch.X(i_br)*tab_branch.tap(i_br));
            phase = tab_branch.phase(i_br);
            x0.(str(1)) = b *(x0.(sv_end(2))-x0.(sv_end(1))+phase);
            x0.(str(2)) = b *(x0.(sv_end(1))-x0.(sv_end(2))-phase);
        end
    end
end
