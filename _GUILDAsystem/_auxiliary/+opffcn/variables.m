function v = variables(obj, prob, str_method, s_var)
% Optimization variables that the set_opffcn handles of obj receive (first argument v).
% s_var: optimvars by name (e.g. those the caller just created); other names are taken
% from prob.Variables, which lists only the variables already used in the problem.
%   Component    : P (all methods), Q ("AC OPF")
%   Bus          : Varg ("DC OPF", "AC OPF"), V ("AC OPF"); none in "ELD"
%   Branch       : Pfrom, Pto, Vargfrom, Vargto ("DC OPF", "AC OPF"); Qfrom, Qto,
%                  Ifrom_re, Ifrom_im, Ito_re, Ito_im, Vfrom, Vto ("AC OPF"); none in "ELD".
%                  Flows go into the branch at each end (from = a_Bus{1}, to = a_Bus{2}),
%                  with the signs of OPFResult.tab_branch.
%   PowerNetwork : v.Component.(tag), v.Bus.(tag), v.Branch.(tag) holding the above
    arguments
        obj
        prob
        str_method (1,1) string
        s_var      (1,1) struct = struct()
    end
    get = @(str) lookup(prob, s_var, str);
    switch true
        case isa(obj, "PowerNetwork")
            v = struct("Component", struct(), "Bus", struct(), "Branch", struct());
            for i = 1:numel(obj.a_Bus)
                bus = obj.a_Bus{i};
                v.Bus.(string(bus)) = opffcn.variables(bus, prob, str_method, s_var);
                for j = 1:numel(bus.a_Component)
                    com = bus.a_Component{j};
                    v.Component.(string(com)) = opffcn.variables(com, prob, str_method, s_var);
                end
            end
            for i = 1:numel(obj.a_Branch)
                br = obj.a_Branch{i};
                v.Branch.(string(br)) = opffcn.variables(br, prob, str_method, s_var);
            end

        case isa(obj, "Component")
            var = get(string(obj));
            v.P = var("P");
            if str_method == "AC OPF"
                v.Q = var("Q");
            end

        case isa(obj, "Bus")
            v = struct();
            if str_method == "ELD"
                return
            end
            var = get(string(obj));
            v.Varg = var("Varg");
            if str_method == "AC OPF"
                v.V = var("V");
            end

        case isa(obj, "Branch")
            v = struct();
            if str_method == "ELD"
                return
            end
            str_bus = string(obj.a_Bus);
            str_end = string(obj) + "_" + str_bus;
            busF = get(str_bus(1));
            busT = get(str_bus(2));
            endF = get(str_end(1));
            endT = get(str_end(2));
            % The end variables hold the flow into the bus; v holds the flow into the branch.
            v.Pfrom = -endF("P");
            v.Pto   = -endT("P");
            v.Vargfrom = busF("Varg");
            v.Vargto   = busT("Varg");
            if str_method == "AC OPF"
                v.Qfrom    = -endF("Q");
                v.Qto      = -endT("Q");
                v.Ifrom_re = -endF("Ireal");
                v.Ifrom_im = -endF("Iimag");
                v.Ito_re   = -endT("Ireal");
                v.Ito_im   = -endT("Iimag");
                v.Vfrom    = busF("V");
                v.Vto      = busT("V");
            end
    end
end


function var = lookup(prob, s_var, str)
    if isfield(s_var, str)
        var = s_var.(str);
    else
        var = prob.Variables.(str);
    end
end
