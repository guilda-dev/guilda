function varargout = disp_formulation(obj, opt)
% Display the formulation of the optimal power flow: objective and constraints by Method.
%
% Shows the general form that build_problem builds for Method: the variables, the
% objective GenCost and each kind of constraint with its name in the problem (<bus>,
% <component>, <branch> and the branch end <branch>_<bus> stand for the tags). "AC OPF":
% min sum of C_g(P_g, Q_g) subject to P_i(V, Varg) = sum of P_g and Q_i(V, Varg) = sum of
% Q_g at every bus (the injections of the components: generation positive, load
% negative), the bounds of P_g, Q_g and V_i, the reference angle and the branch limits
% Pmax, Qmax, Imax, Smax, Vargmax; "DC OPF" the same with |V| = 1, P only and the
% MATPOWER flows; "ELD" one balance of P. With Problem (e.g. prob of net.build_opf_problem)
% each line also shows how many constraints of that kind the problem has (bounds: the
% variables with a finite bound), and the constraints of other names (Constraint, or added
% by the user) are counted on a last line. The solver is not read or changed. With one
% output it returns the text instead of displaying it.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.solver_OPF.disp_formulation(Method="DC OPF")
% prob = net.build_opf_problem(Method="AC OPF");
% net.solver_OPF.disp_formulation(Method="AC OPF", Problem=prob)   % with the counts
% ```
%
% See also SolverOPF.build_problem, PowerNetwork.build_opf_problem
    arguments (Input)
        obj                                                     %#ok<INUSA>
        opt.Method (1,1) string {mustBeMember(opt.Method, ["ELD","DC OPF","AC OPF"])} = GUILDA.config("OptimalPowerFlow", "Method")  % Formulation shown.
        opt.Problem (1,1) optim.problemdef.OptimizationProblem  % Problem whose constraints are counted (built for the same Method).
    end
    arguments (Output, Repeating)
        varargout  % Text when one output is requested; displayed otherwise.
    end
    % one row per kind: formula, names in the problem, name prefixes counted ("" for bounds:
    % "bus" or "component" variables with a finite bound)
    switch opt.Method
        case "AC OPF"
            s_var = "V_i, Varg_i of every bus i; P_g, Q_g of every component g";
            s_obj = "sum_g HP_g*P_g^2 + fP_g*P_g + HQ_g*Q_g^2 + fQ_g*Q_g + c_g (+ Cost)";
            c_row = {"P_i(V, Varg) = sum of P_g at bus i", "balancedP_<bus>", "balancedP_"; ...
                     "Q_i(V, Varg) = sum of Q_g at bus i", "balancedQ_<bus>", "balancedQ_"; ...
                     "  P_i + jQ_i = V_i*conj(sum_k Y_ik*V_k)", "(branch Y with tap, phase; shunts)", []; ...
                     "Pmin_g <= P_g <= Pmax_g, Qmin_g <= Q_g <= Qmax_g", "bounds of <component>", "component"; ...
                     "Vmin_i <= V_i <= Vmax_i (Varg_i free)", "bounds of <bus>", "bus"; ...
                     "Varg_ref = Varg of ReferenceBus", "VargRef", "VargRef"; ...
                     "|P_e| <= Pmax at each branch end e", "Pmax_<branch>_<bus>", "Pmax_"; ...
                     "|Q_e| <= Qmax", "Qmax_<branch>_<bus>", "Qmax_"; ...
                     "|I_e|^2 <= Imax^2", "Imax_<branch>_<bus>", "Imax_"; ...
                     "P_e^2 + Q_e^2 <= Smax^2", "Smax_<branch>_<bus>", "Smax_"; ...
                     "|Varg_from - Varg_to| <= Vargmax", "VargMax1_/VargMax2_<branch>", ["VargMax1_","VargMax2_"]};
        case "DC OPF"
            s_var = "Varg_i of every bus i (|V| = 1); P_g of every component g";
            s_obj = "sum_g HP_g*P_g^2 + fP_g*P_g + c_g (+ Cost)";
            c_row = {"P_i(Varg) = sum of P_g at bus i", "balancedP_<bus>", "balancedP_"; ...
                     "  P_i = Gshunt_i + sum_e b_e*(Varg_i - Varg_j - phase_e)", "(b = 1/(X*tap), MATPOWER)", []; ...
                     "Pmin_g <= P_g <= Pmax_g", "bounds of <component>", "component"; ...
                     "Varg_ref = Varg of ReferenceBus", "VargRef", "VargRef"; ...
                     "|P_e| <= Pmax at each branch end e", "Pmax_<branch>_<bus>", "Pmax_"; ...
                     "|Varg_from - Varg_to| <= Vargmax", "VargMax1_/VargMax2_<branch>", ["VargMax1_","VargMax2_"]};
        case "ELD"
            s_var = "P_g of every component g (branches ignored)";
            s_obj = "sum_g HP_g*P_g^2 + fP_g*P_g + c_g (+ Cost)";
            c_row = {"sum of P_g = 0", "balancedP", "balancedP"; ...
                     "Pmin_g <= P_g <= Pmax_g", "bounds of <component>", "component"};
    end
    l_count = isfield(opt, "Problem");
    if l_count
        sv_con = string(fieldnames(opt.Problem.Constraints));
        lv_seen = false(size(sv_con));
        c_var = struct2cell(opt.Problem.Variables);
        sv_kind = cellfun(@(v) string(ismember("V", string(v.IndexNames{1})) || ismember("Varg", string(v.IndexNames{1}))), c_var);
        sv_kind(sv_kind == "true") = "bus";
        sv_kind(sv_kind == "false") = "component";
        lv_bounded = cellfun(@(v) any(isfinite(v.LowerBound(:)) & v.LowerBound(:) ~= v.UpperBound(:)) ...
                               || any(isfinite(v.UpperBound(:)) & v.LowerBound(:) ~= v.UpperBound(:)), c_var);
    end

    sv = opt.Method + " (" + s_var + ")";
    sv(end+1) = sprintf("  minimize   %s   GenCost", s_obj);
    sv(end+1) = "  subject to";
    for i = 1:height(c_row)
        s_n = "";
        if l_count && ~isempty(c_row{i,3})
            if any(c_row{i,3} == ["bus","component"])
                s_n = sprintf("%d", sum(lv_bounded & sv_kind == c_row{i,3}));
            else
                lv = startsWith(sv_con, c_row{i,3}) | any(sv_con == c_row{i,3}, 2);
                lv_seen = lv_seen | lv;
                s_n = sprintf("%d", sum(lv));
            end
        end
        sv(end+1) = sprintf("    %-56s %-36s %s", c_row{i,1}, c_row{i,2}, s_n); %#ok<AGROW>
    end
    if l_count
        sv(end+1) = sprintf("    %-56s %-36s %d", "other constraints (Constraint, added by the user)", ...
            strjoin(cellstr(sv_con(~lv_seen)), ", "), sum(~lv_seen));
    else
        sv(end+1) = sprintf("    %-56s %s", "constraints of Constraint(v, p)", "<name>");
    end
    s = join(sv, newline);
    if nargout == 1
        varargout = {s};
    else
        disp(s)
    end
end
