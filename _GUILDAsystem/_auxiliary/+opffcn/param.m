function p = param(obj, s_method)
% Collect the parameters that the set_opffcn handles of obj receive (second argument p).
%
% p.Method ("ELD", "DC OPF" or "AC OPF") and one struct per parameter group of obj,
% e.g. p.OPF.HP, p.operation.Pmax, p.powerflow.P (Component), p.operation.Vmax (Bus),
% p.dynamics.X (Branch), p.base.baseMVA (PowerNetwork).
    arguments (Input)
        obj         % Component, Bus, Branch or PowerNetwork.
        s_method    % "ELD", "DC OPF" or "AC OPF".
    end
    arguments (Output)
        p           % Method and one struct per parameter group of obj.
    end
    p = struct("Method", s_method);
    for s_group = ["OPF","operation","powerflow","dynamics","base"]
        s_prop = "para_" + s_group;
        if isprop(obj, s_prop) && isa(obj.(s_prop), "Parameter")
            p.(s_group) = table2struct(obj.(s_prop).tab_parameter);
        end
    end
end
