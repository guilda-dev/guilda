function [prob, x0, const, var] = build_component(row, prob, x0, const, s_method, l_defaultCost)
% Add the power variable, bounds and cost of one component to the OPF problem.
%
% Variable <component> = [P; Q] ("AC OPF") or P, bounded by Pmin/Pmax, Qmin/Qmax (±Inf
% removes a bound) and added to the balance of its bus. The fixed P (Q) of a load is
% already in its bounds and start (see PowerNetwork.calculate_optimal_powerflow).
% With l_defaultCost the cost HP*P^2 + fP*P (+ HQ*Q^2 + fQ*Q in "AC OPF") is added to
% the objective.
    arguments (Input)
        row           table          % Row of the component table (Bus, HP, fP, HQ, fQ, P0, Q0, Pmin, ...); row name = tag.
        prob                         % Problem being built.
        x0            (1,1) struct   % Initial values, extended.
        const         (1,1) struct   % Power-balance expressions, extended.
        s_method      (1,1) string   % "ELD", "DC OPF" or "AC OPF".
        l_defaultCost (1,1) logical  % Add the cost of tab_parameter.OPF.
    end
    arguments (Output)
        prob                         % Problem with the cost added.
        x0                           % Extended initial values.
        const                        % Extended power-balance expressions.
        var                          % Variable of the component.
    end
    opf   = row;
    s_com = string(row.Properties.RowNames{1});
    s_at  = row.Bus;
    lb    = [row.Pmin; row.Qmin];
    ub    = [row.Pmax; row.Qmax];
    PQ0   = [row.P0; row.Q0];

    switch s_method
        case "AC OPF"
            var = optimvar(s_com, {'P','Q'}, 1, "Type","continuous", ...
                           "LowerBound",lb, "UpperBound",ub);
            sv_con = ["P","Q"] + "_" + s_at;
            const.(sv_con(1)) = const.(sv_con(1)) + var("P");
            const.(sv_con(2)) = const.(sv_con(2)) + var("Q");
            x0.(s_com) = PQ0;
            if l_defaultCost
                prob.Objective.GenCost = prob.Objective.GenCost ...
                                       + cost_term(opf.HP, opf.fP, var("P")) ...
                                       + cost_term(opf.HQ, opf.fQ, var("Q"));
            end

        otherwise   % "DC OPF", "ELD"
            var = optimvar(s_com, {'P'}, 1, "Type","continuous", ...
                           "LowerBound",lb(1), "UpperBound",ub(1));
            if s_method == "ELD"
                s_con = "P";
            else
                s_con = "P_" + s_at;
            end
            const.(s_con) = const.(s_con) + var;
            x0.(s_com) = PQ0(1);
            if l_defaultCost
                prob.Objective.GenCost = prob.Objective.GenCost + cost_term(opf.HP, opf.fP, var);
            end
    end
end


function expr = cost_term(H, f, var)
% H*var^2 + f*var, leaving out zero coefficients: a zero quadratic term (0*var^2) makes
% the objective generated for fmincon fail when the rest of the objective is linear.
    expr = 0;
    if H ~= 0
        expr = expr + H * var^2;
    end
    if f ~= 0
        expr = expr + f * var;
    end
end

