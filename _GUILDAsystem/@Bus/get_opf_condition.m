function varargout = get_opf_condition(obj, opt)
% Return the optimal-power-flow condition of the bus and its components.
%
% The tables hold exactly what net.calculate_optimal_powerflow and net.build_opf_problem
% use for this bus; row names are the tags.
%
% - tab_bus (one row): Vmin, Vmax (tab_parameter.operation), Gshunt, Bshunt (dynamics),
%   Type ("slack", "PV" or "PQ", from get_pf_condition), V, Varg (powerflow: the set
%   values of the start and of the reference angle).
% - tab_component (one row per component): Bus (tag of this bus), HP, fP, HQ, fQ, P0, Q0
%   (OPF), Pmin, Pmax, Qmin, Qmax (operation). A load whose Pmin and Pmax (Qmin and Qmax)
%   are both infinite is fixed to its P (Q) of tab_parameter.powerflow: both bounds and
%   the start show that value.
%
% With Display=true (default) the tables are printed under the headings "Bus" and
% "Component"; with no output nothing is returned.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% net.a_Bus{2}.get_opf_condition();                      % print the tables
% [tab_bus, tab_com] = net.a_Bus{2}.get_opf_condition(Display=false);
% ```
%
% See also PowerNetwork.get_opf_condition, Branch.get_opf_condition, Bus.get_pf_condition
%
% <@Group> OPF
    arguments (Input)
        obj
        opt.Display (1,1) logical = true   % Print the tables.
    end
    arguments (Output, Repeating)
        varargout   % tab_bus (one-row table of the bus), then tab_component (one row per component).
    end
    s_bus = string(obj);
    tp = obj.tab_parameter;
    tab_bus = [array2table([tp.operation.Vmin, tp.operation.Vmax, tp.dynamics.Gshunt, tp.dynamics.Bshunt], "VariableNames", ["Vmin","Vmax","Gshunt","Bshunt"]), ...
               table(obj.get_pf_condition().Type, 'VariableNames', "Type"), ...
               array2table([tp.powerflow.V, tp.powerflow.Varg], "VariableNames", ["V","Varg"])];
    tab_bus.Properties.RowNames = s_bus;

    a_com  = reshape(obj.a_Component, [], 1);
    n_com  = numel(a_com);
    rm_com = nan(n_com, 10);
    for k = 1:n_com
        com = a_com{k};
        tp  = com.tab_parameter;
        lb  = [tp.operation.Pmin; tp.operation.Qmin];
        ub  = [tp.operation.Pmax; tp.operation.Qmax];
        PQ0 = [tp.OPF.P0; tp.OPF.Q0];
        if isa(com, "component.load.abstract")
            % a load without bounds keeps its power-flow P (Q)
            PQ = [tp.powerflow.P; tp.powerflow.Q];
            lv_fix = ~isnan(PQ) & isinf(lb) & isinf(ub);
            lb(lv_fix)  = PQ(lv_fix);
            ub(lv_fix)  = PQ(lv_fix);
            PQ0(lv_fix) = PQ(lv_fix);
        end
        rm_com(k,:) = [tp.OPF.HP, tp.OPF.fP, tp.OPF.HQ, tp.OPF.fQ, PQ0(1), PQ0(2), lb(1), ub(1), lb(2), ub(2)];
    end
    tab_component = [table(repmat(s_bus, n_com, 1), 'VariableNames', "Bus"), ...
                     array2table(rm_com, "VariableNames", ["HP","fP","HQ","fQ","P0","Q0","Pmin","Pmax","Qmin","Qmax"])];
    tab_component.Properties.RowNames = reshape(string(a_com), [], 1);

    if opt.Display
        fprintf("%s\n%s\n", "Bus", formattedDisplayText(tab_bus));
        fprintf("%s\n%s\n", "Component", formattedDisplayText(tab_component));
    end
    if ~opt.Display || nargout > 0
        varargout = {tab_bus, tab_component};
        varargout = varargout(1:max(nargout,1));
    end
end
