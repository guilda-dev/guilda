function [prob, x0, const, sct_var] = build_branch(row, prob, x0, const, sct_var, s_method)
% Add the flow variables, definitions and limits of one branch to the OPF problem.
%
% The variables of each end are "<branch>_<bus>" and hold the flow from the branch into
% that bus, which is added to the balance of the bus. Limits at both ends: -Pmax <= P <= Pmax, -Qmax <= Q <= Qmax, |I|^2 <= Imax^2,
% P^2 + Q^2 <= Smax^2 ("AC OPF") and |Varg_i - Varg_j| <= Vargmax; NaN or Inf adds no
% limit. "DC OPF" uses P only, with the MATPOWER flow b*(θi - θj - phase),
% b = 1/(X*tap). "ELD" ignores branches.
    arguments (Input)
        row      table           % Row of the branch table (From, To, Y, X, tap, phase, Pmax, ...); row name = tag.
        prob                     % Problem being built.
        x0       (1,1) struct    % Initial values (with the end buses), extended.
        const    (1,1) struct    % Power-balance expressions, extended.
        sct_var  (1,1) struct    % Variables by name (with the end buses), extended.
        s_method (1,1) string    % "ELD", "DC OPF" or "AC OPF".
    end
    arguments (Output)
        prob                     % Problem with the definitions and limits added.
        x0                       % Extended initial values.
        const                    % Extended power-balance expressions.
        sct_var                  % Variables with the two branch ends added.
    end
    if s_method == "ELD"
        return
    end

    ope    = row;
    s_br   = string(row.Properties.RowNames{1});
    sv_bus = [row.From; row.To];       % column: sm_con below is 2x2 (end, P/Q)
    Vbusi  = sct_var.(sv_bus(1));
    Vbusj  = sct_var.(sv_bus(2));
    if ~isnan(ope.Vargmax) && ~isinf(ope.Vargmax)
        prob.Constraints.("VargMax1_"+s_br) = (Vbusi("Varg")-Vbusj("Varg")) <=  ope.Vargmax;
        prob.Constraints.("VargMax2_"+s_br) = (Vbusi("Varg")-Vbusj("Varg")) >= -ope.Vargmax;
    end

    % str(1): end at bus i, str(2): end at bus j
    str    = s_br + "_" + sv_bus;
    sm_con = ["P_","Q_"] + sv_bus;
    switch s_method
        case "AC OPF"
            ub = [ ope.Pmax;  ope.Qmax;  inf;  inf];
            lb = [-ope.Pmax; -ope.Qmax; -inf; -inf];
            ub(isnan(ub)) =  inf;
            lb(isnan(lb)) = -inf;
            varji = optimvar(str(1), {'P','Q','Ireal','Iimag'}, 1, "LowerBound",lb, "UpperBound",ub);
            varij = optimvar(str(2), {'P','Q','Ireal','Iimag'}, 1, "LowerBound",lb, "UpperBound",ub);
            sct_var.(str(1)) = varji;
            sct_var.(str(2)) = varij;

            % The direction into the bus is positive, hence the minus sign.
            rm_Yij = - reshape(row.Y, 2, 2);
            rm_Yex = tools.complex2matrix(rm_Yij);

            % Initial point: the end values at the initial bus voltages, so that the
            % definitions below hold at x0 (a zero current is also a non-smooth point of |I|).
            rm_x0V = [x0.(sv_bus(1)), x0.(sv_bus(2))];
            cv_V0  = (rm_x0V(2,:) .* exp(1j*rm_x0V(1,:))).';
            cv_I0  = rm_Yij * cv_V0;
            cv_S0  = cv_V0 .* conj(cv_I0);
            x0.(str(1)) = [real(cv_S0(1)); imag(cv_S0(1)); real(cv_I0(1)); imag(cv_I0(1))];
            x0.(str(2)) = [real(cv_S0(2)); imag(cv_S0(2)); real(cv_I0(2)); imag(cv_I0(2))];

            c_end = {varji, varij};
            for k = 1:2
                var = c_end{k};
                prob.Constraints.("defIre_"+str(k)) = var("Ireal") == current(rm_Yex(2*k-1,:), Vbusi, Vbusj);
                prob.Constraints.("defIim_"+str(k)) = var("Iimag") == current(rm_Yex(2*k,:),   Vbusi, Vbusj);
            end

            Vb = {Vbusi, Vbusj};
            for k = 1:2
                var = c_end{k};
                V   = Vb{k};
                prob.Constraints.("defP_"+str(k)) = var("P") == ( var("Ireal")*V("V") * cos(V("Varg")) + var("Iimag")*V("V") * sin(V("Varg")) );
            end
            for k = 1:2
                var = c_end{k};
                V   = Vb{k};
                prob.Constraints.("defQ_"+str(k)) = var("Q") == ( var("Ireal")*V("V") * sin(V("Varg")) - var("Iimag")*V("V") * cos(V("Varg")) );
            end

            const.(sm_con(1,1)) = const.(sm_con(1,1)) + varji("P");
            const.(sm_con(1,2)) = const.(sm_con(1,2)) + varji("Q");
            const.(sm_con(2,1)) = const.(sm_con(2,1)) + varij("P");
            const.(sm_con(2,2)) = const.(sm_con(2,2)) + varij("Q");

            % Squared limits: smooth everywhere, unlike sqrt(), whose derivative is
            % undefined at zero.
            if ~isnan(ope.Imax) && ~isinf(ope.Imax)
                prob.Constraints.("Imax_"+str(1)) = varji("Ireal")^2 + varji("Iimag")^2 <= ope.Imax^2;
                prob.Constraints.("Imax_"+str(2)) = varij("Ireal")^2 + varij("Iimag")^2 <= ope.Imax^2;
            end
            if ~isnan(ope.Smax) && ~isinf(ope.Smax)
                prob.Constraints.("Smax_"+str(1)) = varji("P")^2 + varji("Q")^2 <= ope.Smax^2;
                prob.Constraints.("Smax_"+str(2)) = varij("P")^2 + varij("Q")^2 <= ope.Smax^2;
            end

        case "DC OPF"
            ub =  ope.Pmax;
            lb = -ope.Pmax;
            if isnan(ub); ub = inf; lb = -inf; end
            P_i = optimvar(str(1), {'P'}, 1, "LowerBound",lb, "UpperBound",ub);
            P_j = optimvar(str(2), {'P'}, 1, "LowerBound",lb, "UpperBound",ub);
            sct_var.(str(1)) = P_i;
            sct_var.(str(2)) = P_j;

            % |V| = 1, lossless, MATPOWER convention (makeBdc): the flow from bus i to
            % bus j is b*(θi - θj - phase); the power into bus i is its negative.
            % b = 1/(X*tap) as in MATPOWER, with the off-nominal tap ratio and the phase
            % shift [rad] at the from end; tap = 1 and phase = 0 for lines.
            b     = 1/(row.X*row.tap);
            phase = row.phase;
            prob.Constraints.("defP_"+str(1)) = P_i == b *(Vbusj("Varg")-Vbusi("Varg")+phase);
            prob.Constraints.("defP_"+str(2)) = P_j == b *(Vbusi("Varg")-Vbusj("Varg")-phase);

            x0.(str(1)) = b *(x0.(sv_bus(2))-x0.(sv_bus(1))+phase);
            x0.(str(2)) = b *(x0.(sv_bus(1))-x0.(sv_bus(2))-phase);

            const.(sm_con(1,1)) = const.(sm_con(1,1)) + P_i;
            const.(sm_con(2,1)) = const.(sm_con(2,1)) + P_j;
    end
end


function expr = current(rv_Y, Vbusi, Vbusj)
% One row of the real form of I = Y*V in the end-bus voltages (V, Varg).
    expr = rv_Y(1) * Vbusi("V") * cos(Vbusi("Varg")) ...
         + rv_Y(2) * Vbusi("V") * sin(Vbusi("Varg")) ...
         + rv_Y(3) * Vbusj("V") * cos(Vbusj("Varg")) ...
         + rv_Y(4) * Vbusj("V") * sin(Vbusj("Varg")) ;
end

