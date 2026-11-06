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
        lv_para = cellfun(@(c) c.s_tag==s_group, obj.a_Parameter);
        if any(lv_para)
            p.(s_group) = table2struct(obj.a_Parameter{lv_para}.tab_parameter);
        end
    end
end
