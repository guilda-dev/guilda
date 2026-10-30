function p = param(obj, str_method)
% Collect the parameters that the set_opffcn handles of obj receive (second argument p).
%
% p.Method ("ELD", "DC OPF" or "AC OPF") and one struct per parameter group of obj,
% e.g. p.OPF.HP, p.operation.Pmax, p.powerflow.P (Component), p.operation.Vmax (Bus),
% p.dynamics.X (Branch), p.base.baseMVA (PowerNetwork).
    p = struct("Method", str_method);
    for str_group = ["OPF","operation","powerflow","dynamics","base"]
        str_prop = "para_" + str_group;
        if isprop(obj, str_prop) && isa(obj.(str_prop), "Parameter")
            p.(str_group) = table2struct(obj.(str_prop).tab_parameter);
        end
    end
end
