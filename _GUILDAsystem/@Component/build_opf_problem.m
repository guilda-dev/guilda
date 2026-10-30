function [prob, x0, const] = build_opf_problem(obj, prob, x0, const, Busvar, option)
% Add the power variables, limits and cost of the component to an OPF problem.
%
% Called by Bus.build_opf_problem for each component of the bus. The power of the
% component is added to the power balance of its bus in `const`. A load keeps the P
% (Q) of tab_parameter.powerflow while its Pmin/Pmax (Qmin/Qmax) are infinite.
%
% See also Bus.build_opf_problem, Component.set_opffcn
    arguments
        obj 
        prob   = optimproblem();   % optimproblem to extend.
        x0     = struct();   % Struct of initial values, extended.
        const  = struct();   % Struct of power-balance expressions, extended.
        Busvar = zeros(2,0);   % Variables of the bus (unused).
        option.methods (1,1) string {mustBeMember(option.methods,["ELD","DC OPF","AC OPF"])} = "AC OPF";   % OPF formulation: "ELD", "DC OPF" or "AC OPF".
    end
    arguments (Output)
        prob    % Extended optimproblem.
        x0      % Extended initial values.
        const   % Extended power-balance expressions.
    end

    % try
    
        opf  = obj.para_OPF;
        ope  = obj.para_operation;
        str  = string(obj);

        % Output limits [P;Q] and initial point.
        % A load is not dispatched: its P (Q) is fixed to the power-flow setting while both
        % Pmin and Pmax (Qmin, Qmax) are infinite (the default). A load with finite bounds
        % is dispatched within them (a price-responsive load, with a cost set explicitly).
        % DefaultConstraint=false (set_opffcn) removes the bounds and the fixing.
        lb = [ope.Pmin; ope.Qmin];
        ub = [ope.Pmax; ope.Qmax];
        PQ0 = [opf.P0; opf.Q0];
        s_fcn = obj.s_opffcn;
        if ~s_fcn.DefaultConstraint
            lb(:) = -inf;
            ub(:) =  inf;
        elseif isa(obj,"component.load.abstract")
            pf  = obj.para_powerflow;
            PQ  = [pf.P; pf.Q];
            l_fix = ~isnan(PQ) & isinf(lb) & isinf(ub);
            lb(l_fix)  = PQ(l_fix);
            ub(l_fix)  = PQ(l_fix);
            PQ0(l_fix) = PQ(l_fix);
        end
        % set_opffcn Cost replaces the default cost
        l_defCost = isempty(s_fcn.Cost);
    
        switch option.methods
            case "AC OPF"
                var  = optimvar(str, {'P','Q'}, 1,      "Type", "continuous"       ,...
                                                  "LowerBound",lb ,...
                                                  "UpperBound",ub );
                Convar  = ["P","Q"] + "_" + string(obj.a_Bus);
                const.(Convar(1)) = const.(Convar(1)) + var("P");
                const.(Convar(2)) = const.(Convar(2)) + var("Q");
                x0.(str) = PQ0;
                if l_defCost
                    prob.Objective.GenCost = prob.Objective.GenCost...
                                      + cost_term(opf.HP, opf.fP, var("P")) ...
                                      + cost_term(opf.HQ, opf.fQ, var("Q"));
                end
                
            case "DC OPF"
                var  = optimvar(str, {'P'}, 1, "Type"      ,"continuous" ,...
                                               "LowerBound",lb(1)        ,...
                                               "UpperBound",ub(1)        );
                Convar  = "P_" + string(obj.a_Bus);
                const.(Convar) = const.(Convar) + var;
                x0.(str)       = PQ0(1);
                if l_defCost
                    prob.Objective.GenCost = prob.Objective.GenCost + cost_term(opf.HP, opf.fP, var);
                end
    
            case "ELD"
                var  = optimvar(str, {'P'}, 1, "Type"      ,"continuous" ,...
                                               "LowerBound",lb(1)        ,...
                                               "UpperBound",ub(1)        );
                const.P = const.P + var;
                x0.(str) = PQ0(1);
                if l_defCost
                    prob.Objective.GenCost = prob.Objective.GenCost + cost_term(opf.HP, opf.fP, var);
                end
        end

        % set_opffcn terms (user cost, user constraints)
        prob = opffcn.apply(obj, prob, option.methods, struct(str, var));

    % catch
    %     error("Error: This method must only be called internally by Bus.build_opf_problem/")
    % end
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
