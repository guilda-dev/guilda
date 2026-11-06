function p = param(net, s_method)
% Collect the parameters that the Cost and Constraint handles receive (second argument p).
%
% p.Method ("ELD", "DC OPF" or "AC OPF") and p.base (baseMVA, Hz of the network).
% Parameters of single objects are read from the objects when the handle is written,
% e.g. gen.tab_parameter.operation.Pmax.
    arguments (Input)
        net                    % Network of the problem.
        s_method (1,1) string  % "ELD", "DC OPF" or "AC OPF".
    end
    arguments (Output)
        p                      % Method and base.
    end
    p = struct("Method", s_method);
    lv_base = cellfun(@(c) c.s_tag=="base", net.a_Parameter);
    p.base = table2struct(net.a_Parameter{lv_base}.tab_parameter);
end
