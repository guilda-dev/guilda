function v = variables(net, sct_var, s_method)
% Collect the optimization variables that the Cost and Constraint handles receive (first argument v).
%
% - v.Component.(tag): P (all methods), Q ("AC OPF").
% - v.Bus.(tag): Varg ("DC OPF", "AC OPF"), V ("AC OPF"); no fields in "ELD".
% - v.Branch.(tag): Pfrom, Pto, Vargfrom, Vargto ("DC OPF", "AC OPF"); Qfrom, Qto,
%   Ifrom_re, Ifrom_im, Ito_re, Ito_im, Vfrom, Vto ("AC OPF"); no fields in "ELD".
%   Flows go into the branch at each end (from = a_Bus{1}, to = a_Bus{2}), with the
%   signs of ResultOPF.tab_branch.
    arguments (Input)
        net                    % Network of the problem.
        sct_var  (1,1) struct  % Optimization variables by variable name (from build_problem).
        s_method (1,1) string  % "ELD", "DC OPF" or "AC OPF".
    end
    arguments (Output)
        v                      % Variables by kind and tag (see above).
    end
    v = struct("Component", struct(), "Bus", struct(), "Branch", struct());
    for i = 1:numel(net.a_Bus)
        bus   = net.a_Bus{i};
        s_bus = string(bus);
        sct   = struct();
        if s_method ~= "ELD"
            var = sct_var.(s_bus);
            sct.Varg = var("Varg");
            if s_method == "AC OPF"
                sct.V = var("V");
            end
        end
        v.Bus.(s_bus) = sct;
        for j = 1:numel(bus.a_Component)
            s_com = string(bus.a_Component{j});
            var   = sct_var.(s_com);
            sct   = struct("P", var("P"));
            if s_method == "AC OPF"
                sct.Q = var("Q");
            end
            v.Component.(s_com) = sct;
        end
    end
    for i = 1:numel(net.a_Branch)
        br  = net.a_Branch{i};
        sct = struct();
        if s_method ~= "ELD"
            sv_bus = string(br.a_Bus);
            sv_end = string(br) + "_" + sv_bus;
            busF = sct_var.(sv_bus(1));
            busT = sct_var.(sv_bus(2));
            endF = sct_var.(sv_end(1));
            endT = sct_var.(sv_end(2));
            % The end variables hold the flow into the bus; v holds the flow into the branch.
            sct.Pfrom    = -endF("P");
            sct.Pto      = -endT("P");
            sct.Vargfrom = busF("Varg");
            sct.Vargto   = busT("Varg");
            if s_method == "AC OPF"
                sct.Qfrom    = -endF("Q");
                sct.Qto      = -endT("Q");
                sct.Ifrom_re = -endF("Ireal");
                sct.Ifrom_im = -endF("Iimag");
                sct.Ito_re   = -endT("Ireal");
                sct.Ito_im   = -endT("Iimag");
                sct.Vfrom    = busF("V");
                sct.Vto      = busT("V");
            end
        end
        v.Branch.(string(br)) = sct;
    end
end
