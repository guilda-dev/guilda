function [prob, x0, const, var] = build_component(com, prob, x0, const, s_method, l_defaultCost)
% Add the power variable, bounds and cost of one component to the OPF problem.
%
% Variable <component> = [P; Q] ("AC OPF") or P, bounded by Pmin/Pmax, Qmin/Qmax of
% tab_parameter.operation (±Inf removes a bound) and added to the balance of its bus.
% A load is not dispatched: its P (Q) is fixed to tab_parameter.powerflow while both
% bounds are infinite; with a finite bound it is dispatched within the bounds.
% With l_defaultCost the cost HP*P^2 + fP*P (+ HQ*Q^2 + fQ*Q in "AC OPF") of
% tab_parameter.OPF is added to the objective.
    arguments (Input)
        com                          % Component to add.
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
    opf   = group(com, "OPF");
    ope   = group(com, "operation");
    s_com = string(com);

    lb  = [ope.Pmin; ope.Qmin];
    ub  = [ope.Pmax; ope.Qmax];
    PQ0 = [opf.P0; opf.Q0];
    if isa(com, "component.load.abstract")
        pf = group(com, "powerflow");
        PQ = [pf.P; pf.Q];
        lv_fix = ~isnan(PQ) & isinf(lb) & isinf(ub);
        lb(lv_fix)  = PQ(lv_fix);
        ub(lv_fix)  = PQ(lv_fix);
        PQ0(lv_fix) = PQ(lv_fix);
    end

    switch s_method
        case "AC OPF"
            var = optimvar(s_com, {'P','Q'}, 1, "Type","continuous", ...
                           "LowerBound",lb, "UpperBound",ub);
            sv_con = ["P","Q"] + "_" + string(com.a_Bus);
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
                s_con = "P_" + string(com.a_Bus);
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


function tab = group(obj, s_group)
    tab = obj.a_Parameter{cellfun(@(p) p.s_tag==s_group, obj.a_Parameter)}.tab_parameter;
end
