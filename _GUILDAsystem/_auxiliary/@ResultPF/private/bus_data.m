function sct = bus_data(obj)
% Data of each bus that the disp_ and plot_ methods read from the stored result: tags,
% types, set values, limits and bases. Values that the result does not hold are NaN or
% "" (a result without a snapshot or without power flow conditions).
    arguments (Input)
        obj   % The ResultPF.
    end
    arguments (Output)
        sct struct  % Fields sv_tag, sv_type, rv_Vset, rv_Vargset, rv_Pset, rv_Qset, rv_Vmin, rv_Vmax, rv_baseKV (bus order of tab_bus), r_baseMVA.
    end
    sv_tag = string(obj.tab_bus.Properties.RowNames);
    n_bus  = numel(sv_tag);
    sct = struct("sv_tag", sv_tag, "sv_type", strings(n_bus,1), ...
        "rv_Vset", nan(n_bus,1), "rv_Vargset", nan(n_bus,1), "rv_Pset", nan(n_bus,1), "rv_Qset", nan(n_bus,1), ...
        "rv_Vmin", nan(n_bus,1), "rv_Vmax", nan(n_bus,1), "rv_baseKV", nan(n_bus,1), "r_baseMVA", NaN);
    tab_c = obj.tab_PFcondition;
    if height(tab_c) == n_bus
        sct.sv_type    = string(tab_c.Type);
        sct.rv_Vset    = tab_c.V;
        sct.rv_Vargset = tab_c.Varg;
        sct.rv_Pset    = tab_c.P;
        sct.rv_Qset    = tab_c.Q;
    end
    sct_net = obj.sct_network;
    if isfield(sct_net, "tab_parameter") && ismember("base", sct_net.tab_parameter.Properties.VariableNames)
        sct.r_baseMVA = sct_net.tab_parameter.base.baseMVA;
    end
    if isfield(sct_net, "a_Bus") && numel(sct_net.a_Bus) == n_bus
        for i_bus = 1:n_bus
            ope = sct_net.a_Bus{i_bus}.tab_parameter.operation;
            sct.rv_Vmin(i_bus)   = ope.Vmin;
            sct.rv_Vmax(i_bus)   = ope.Vmax;
            sct.rv_baseKV(i_bus) = ope.baseKV;
        end
    end
end
