function varargout = disp_binding(obj, opt)
% Display the binding constraints of the optimal power flow solution.
%
% Lists the constraints that hold with equality at the solution: the bounds of the
% variables (e.g. Vmax of a bus, Pmax of a generator; a fixed value such as the P of a
% load is left out) and the inequalities of OPFprob (branch limits Pmax_, Qmax_, Imax_,
% Smax_, VargMax1_, VargMax2_, and those of Constraint). Columns: Constraint (the name;
% "(k)" for element k of a constraint with several), Object (the tag of the bus,
% component, branch end "<branch>_<bus>" or branch), Value, Limit and Multiplier (the
% Lagrange multiplier of lambda, cost per unit of the constraint). A constraint counts as
% binding when its value is within 1e-4 * max(1, |Limit|) of its limit. The values of the
% branch limits are physical (P, Q, |I|, |S| of the branch end; the angle difference From -
% To), with the limits of tab_parameter.operation of the branch in sct_network; for a
% constraint of Constraint, Value is the left-hand side minus the right-hand side (<= 0)
% and Limit is 0. The power balance equations always hold and are not listed. It reads
% only the stored result. With one output it returns the text instead of displaying it.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.a_Branch{1}.tab_parameter.operation.Smax = 1;
% res = net.calculate_optimal_powerflow(Method="AC OPF");
% res.disp_binding()
% res.disp_binding(Kind="Branch")
% ```
%
% See also ResultOPF.disp_summary, ResultOPF.get_lmp
    arguments (Input)
        obj
        opt.Kind (1,:) string {mustBeMember(opt.Kind, ["Bound","Branch","Other"])} = ["Bound","Branch","Other"]  % Kinds shown: bounds of the variables, branch limits, other inequalities.
    end
    arguments (Output, Repeating)
        varargout  % Text when one output is requested; displayed otherwise.
    end
    tab = binding_table(obj);
    lv_branch = startsWith(tab.Constraint, ["Pmax_","Qmax_","Imax_","Smax_","VargMax1_","VargMax2_"]);
    lv_bound  = ~lv_branch & tab.Object ~= "";      % the other inequalities have no object
    lv_show   = (ismember("Bound", opt.Kind) & lv_bound) | (ismember("Branch", opt.Kind) & lv_branch) ...
              | (ismember("Other", opt.Kind) & ~lv_bound & ~lv_branch);
    tab = tab(lv_show, :);
    if height(tab) == 0
        s = "No binding constraints (" + join(opt.Kind, ", ") + ") in the OPF result of " + obj.s_network + ".";
    else
        s = "Binding constraints (" + height(tab) + ") of the OPF result of " + obj.s_network + newline ...
          + string(formattedDisplayText(tab, "SuppressMarkup", true));
    end
    if nargout == 1
        varargout = {s};
    else
        disp(s)
    end
end
