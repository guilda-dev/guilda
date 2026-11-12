function varargout = disp_branch(obj, opt)
% Display the branch flows of the power flow result.
%
% One row per branch: its end buses (From = the first bus, To = the second), the power
% flowing into the branch at each end (Pfrom, Qfrom, Pto, Qto), its losses (Ploss,
% Qloss) and its loading, the larger |S| of the two ends over Smax of its operating
% limits (NaN when Smax is infinite or not held). It reads only the stored result. With
% Unit="SI", P and Q are in MW and Mvar (times baseMVA of the network). With one output it
% returns the text instead of displaying it.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% res.disp_branch()
% res.disp_branch(Sort="loss", Unit="SI")     % largest active power loss first
% ```
%
% See also ResultPF.disp_bus, ResultPF.disp_violation, ResultPF.tab_branch
    arguments (Input)
        obj
        opt.Branch (1,:) string = strings(1,0)   % Tags of the branches to show; empty shows all.
        opt.Unit   (1,1) string {mustBeMember(opt.Unit, ["pu","SI"])} = "pu" % "pu", or "SI" for MW and Mvar.
        opt.Sort   (1,1) string {mustBeMember(opt.Sort, ["tag","loss","loading"])} = "tag" % "tag" keeps the branch order; "loss" (Ploss) and "loading" sort the largest first.
    end
    arguments (Output, Repeating)
        varargout % Table text when one output is requested; displayed otherwise.
    end
    tab   = obj.tab_branch;
    sv_br = string(tab.Properties.RowNames);
    iv    = pick_rows(sv_br, opt.Branch, "branch");
    tab   = tab(iv,:);
    [sv_from, sv_to, rv_Smax] = branch_ends(obj, iv);
    rv_load = max(abs([tab.Pfrom + 1j*tab.Qfrom, tab.Pto + 1j*tab.Qto]), [], 2) ./ rv_Smax;
    rv_load(isinf(rv_Smax)) = NaN;
    r_scale = 1;
    s_P = "pu"; s_Q = "pu";
    if opt.Unit == "SI"
        r_scale = bus_data(obj).r_baseMVA;
        if isnan(r_scale)
            error(msg("GUILDA:ResultPF:NoBase"))
        end
        s_P = "MW"; s_Q = "Mvar";
    end
    tab_show = table(sv_from, sv_to, r_scale*tab.Pfrom, r_scale*tab.Qfrom, r_scale*tab.Pto, r_scale*tab.Qto, ...
        r_scale*tab.Ploss, r_scale*tab.Qloss, rv_load, ...
        'VariableNames', ["From", "To", "Pfrom ("+s_P+")", "Qfrom ("+s_Q+")", "Pto ("+s_P+")", "Qto ("+s_Q+")", ...
                          "Ploss ("+s_P+")", "Qloss ("+s_Q+")", "Loading"], ...
        'RowNames', sv_br(iv));
    switch opt.Sort
        case "loss"
            [~, iv_sort] = sort(tab.Ploss, "descend");
            tab_show = tab_show(iv_sort,:);
        case "loading"
            [~, iv_sort] = sort(rv_load, "descend", "MissingPlacement", "last");
            tab_show = tab_show(iv_sort,:);
    end
    varargout = show_text(table_text(tab_show), nargout);
end


function [sv_from, sv_to, rv_Smax] = branch_ends(obj, iv)
% End bus tags and Smax of the branches iv, from the snapshot ("" and Inf without it)
    n = numel(iv);
    sv_from = strings(n,1);
    sv_to   = strings(n,1);
    rv_Smax = inf(n,1);
    sct_net = obj.sct_network;
    if ~isfield(sct_net, "a_Branch")
        return
    end
    sv_bus = string(obj.tab_bus.Properties.RowNames);
    for k = 1:n
        br = sct_net.a_Branch{iv(k)};
        iv_end = bus_index(br.a_Bus, sv_bus);
        sv_from(k) = sv_bus(iv_end(1));
        sv_to(k)   = sv_bus(iv_end(2));
        rv_Smax(k) = br.tab_parameter.operation.Smax;
    end
end
