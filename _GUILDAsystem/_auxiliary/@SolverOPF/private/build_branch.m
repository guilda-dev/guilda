function [prob, const, sct_var] = build_branch(row, prob, const, sct_var, s_method)
% Add the flows and limits of one branch to the OPF problem.
%
% The flow at each end ("<branch>_<bus>", from the branch into that bus) is an expression
% of the voltages of the end buses (branch_flow), added to the power balance of the bus;
% a branch has no variables. Limits at both ends: |P| <= Pmax and, in "AC OPF",
% |Q| <= Qmax, |I|^2 <= Imax^2, P^2 + Q^2 <= Smax^2; and |Varg_i - Varg_j| <= Vargmax.
% NaN or Inf adds no limit. "DC OPF" has P only (MATPOWER flow b*(θi - θj - phase),
% b = 1/(X*tap)). "ELD" ignores branches.
    arguments (Input)
        row      table         % Row of the branch table (From, To, Y, X, tap, phase, Pmax, ...); row name = tag.
        prob                   % Problem being built.
        const    (1,1) struct  % Power-balance expressions, extended.
        sct_var  (1,1) struct  % Variables by name (with the end buses), extended.
        s_method (1,1) string  % "ELD", "DC OPF" or "AC OPF".
    end
    arguments (Output)
        prob     % Problem with the limits added.
        const    % Extended power-balance expressions.
        sct_var  % With the flows of the two ends (struct of P, Q, Ireal, Iimag; P in "DC OPF") by end name.
    end
    if s_method == "ELD"
        return
    end

    ope    = row;
    s_br   = string(row.Properties.RowNames{1});
    sv_bus = [row.From; row.To];
    Vbusi  = sct_var.(sv_bus(1));
    Vbusj  = sct_var.(sv_bus(2));
    if ~isnan(ope.Vargmax) && ~isinf(ope.Vargmax)
        prob.Constraints.("VargMax1_"+s_br) = (Vbusi("Varg")-Vbusj("Varg")) <=  ope.Vargmax;
        prob.Constraints.("VargMax2_"+s_br) = (Vbusi("Varg")-Vbusj("Varg")) >= -ope.Vargmax;
    end

    % str(k): the end at bus sv_bus(k)
    str = s_br + "_" + sv_bus;
    if s_method == "AC OPF"
        rm_flow = branch_flow(row, [Vbusi("V"), Vbusj("V")], [Vbusi("Varg"), Vbusj("Varg")], s_method);
    else
        rm_flow = branch_flow(row, [1, 1], [Vbusi("Varg"), Vbusj("Varg")], s_method);
    end
    for k = 1:2
        P = rm_flow(1,k);
        const.("P_"+sv_bus(k)) = const.("P_"+sv_bus(k)) + P;
        if ~isnan(ope.Pmax) && ~isinf(ope.Pmax)
            prob.Constraints.("Pmax_"+str(k)) = [P; -P] <= ope.Pmax;
        end
        if s_method == "DC OPF"
            sct_var.(str(k)) = struct("P", P);
            continue
        end
        [Q, Ire, Iim] = deal(rm_flow(2,k), rm_flow(3,k), rm_flow(4,k));
        const.("Q_"+sv_bus(k)) = const.("Q_"+sv_bus(k)) + Q;
        sct_var.(str(k)) = struct("P", P, "Q", Q, "Ireal", Ire, "Iimag", Iim);
        if ~isnan(ope.Qmax) && ~isinf(ope.Qmax)
            prob.Constraints.("Qmax_"+str(k)) = [Q; -Q] <= ope.Qmax;
        end
        % Squared limits: smooth everywhere, unlike sqrt(), whose derivative is
        % undefined at zero.
        if ~isnan(ope.Imax) && ~isinf(ope.Imax)
            prob.Constraints.("Imax_"+str(k)) = Ire^2 + Iim^2 <= ope.Imax^2;
        end
        if ~isnan(ope.Smax) && ~isinf(ope.Smax)
            prob.Constraints.("Smax_"+str(k)) = P^2 + Q^2 <= ope.Smax^2;
        end
    end
end
