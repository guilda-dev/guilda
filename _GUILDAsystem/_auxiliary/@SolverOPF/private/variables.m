function v = variables(tab_bus, tab_component, tab_branch, sct_var, s_method)
% Collect the optimization variables that the Cost and Constraint handles receive (first argument v).
%
% - v.Component.(tag): P (all methods), Q ("AC OPF").
% - v.Bus.(tag): Varg ("DC OPF", "AC OPF"), V ("AC OPF"); no fields in "ELD".
% - v.Branch.(tag): Pfrom, Pto, Vargfrom, Vargto ("DC OPF", "AC OPF"); Qfrom, Qto,
%   Ifrom_re, Ifrom_im, Ito_re, Ito_im, Vfrom, Vto ("AC OPF"); no fields in "ELD".
%   Flows go into the branch at each end (from = From, to = To of the branch table), with
%   the signs of ResultOPF.tab_branch.
    arguments (Input)
        tab_bus       table    % Bus table (row names = bus tags).
        tab_component table    % Component table (row names = tags; Bus).
        tab_branch    table    % Branch table (row names = tags; From, To).
        sct_var  (1,1) struct  % Optimization variables by variable name (from build_problem).
        s_method (1,1) string  % "ELD", "DC OPF" or "AC OPF".
    end
    arguments (Output)
        v                      % Variables by kind and tag (see above).
    end
    v = struct("Component", struct(), "Bus", struct(), "Branch", struct());
    sv_bus = string(tab_bus.Properties.RowNames);
    sv_com = string(tab_component.Properties.RowNames);
    for i = 1:numel(sv_bus)
        s_bus = sv_bus(i);
        sct   = struct();
        if s_method ~= "ELD"
            var = sct_var.(s_bus);
            sct.Varg = var("Varg");
            if s_method == "AC OPF"
                sct.V = var("V");
            end
        end
        v.Bus.(s_bus) = sct;
        for j = reshape(find(tab_component.Bus == s_bus), 1, [])
            s_com = sv_com(j);
            var   = sct_var.(s_com);
            sct   = struct("P", var("P"));
            if s_method == "AC OPF"
                sct.Q = var("Q");
            end
            v.Component.(s_com) = sct;
        end
    end
    sv_br = string(tab_branch.Properties.RowNames);
    for i = 1:numel(sv_br)
        sct = struct();
        if s_method ~= "ELD"
            sv_end_bus = [tab_branch.From(i), tab_branch.To(i)];
            sv_end = sv_br(i) + "_" + sv_end_bus;
            busF = sct_var.(sv_end_bus(1));
            busT = sct_var.(sv_end_bus(2));
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
        v.Branch.(sv_br(i)) = sct;
    end
end
