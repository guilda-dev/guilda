function varargout = disp_bus(obj, opt)
% Display the bus values of the power flow result.
%
% One row per bus: its type (slack, PV or PQ), the values its power flow condition sets
% (slack: V and Varg; PV: P and V; PQ: P and Q), and the solution |V|, the angle [deg],
% P and Q (injections into the network). It reads only the stored result. With
% Unit="SI", |V| is in kV (times baseKV of the bus) and P, Q in MW and Mvar (times
% baseMVA of the network); the set values stay in per unit. With one output it returns
% the text instead of displaying it.
%
% <@Examples>
% ```matlab
% res = network.IEEE9bus().calculate_powerflow();
% res.disp_bus()
% res.disp_bus(Bus=["B001","B005"], Unit="SI")
% res.disp_bus(Sort="V")              % lowest |V| first
% ```
%
% See also ResultPF.disp_summary, ResultPF.disp_branch, ResultPF.plot_voltage
    arguments (Input)
        obj
        opt.Bus  (1,:) string = strings(1,0)   % Tags of the buses to show; empty shows all.
        opt.Unit (1,1) string {mustBeMember(opt.Unit, ["pu","SI"])} = "pu" % "pu", or "SI" for kV, MW and Mvar.
        opt.Sort (1,1) string {mustBeMember(opt.Sort, ["tag","V"])} = "tag" % "tag" keeps the bus order; "V" sorts by |V|, lowest first.
    end
    arguments (Output, Repeating)
        varargout % Table text when one output is requested; displayed otherwise.
    end
    sct = bus_data(obj);
    iv  = pick_rows(sct.sv_tag, opt.Bus, "bus");
    tab = obj.tab_bus(iv,:);
    rv_V = tab.V;
    rv_P = tab.P;
    rv_Q = tab.Q;
    sv_unit = ["pu", "pu", "pu"];
    if opt.Unit == "SI"
        check_bases(sct, iv)
        rv_V = rv_V .* sct.rv_baseKV(iv);
        rv_P = rv_P * sct.r_baseMVA;
        rv_Q = rv_Q * sct.r_baseMVA;
        sv_unit = ["kV", "MW", "Mvar"];
    end
    sv_set = set_text(sct, iv);
    tab_show = table(sct.sv_type(iv), sv_set, rv_V, rad2deg(tab.Varg), rv_P, rv_Q, ...
        'VariableNames', ["Type", "Set (pu)", "|V| (" + sv_unit(1) + ")", "Varg (deg)", ...
                          "P (" + sv_unit(2) + ")", "Q (" + sv_unit(3) + ")"], ...
        'RowNames', sct.sv_tag(iv));
    if opt.Sort == "V"
        [~, iv_sort] = sort(tab.V);
        tab_show = tab_show(iv_sort,:);
    end
    varargout = show_text(table_text(tab_show), nargout);
end


function sv = set_text(sct, iv)
% The values the power flow condition of each bus sets, as text
    sv = strings(numel(iv),1);
    for k = 1:numel(iv)
        i = iv(k);
        switch sct.sv_type(i)
            case "slack"; sv(k) = sprintf("V=%.4g, Varg=%.4g", sct.rv_Vset(i), sct.rv_Vargset(i));
            case "PV";    sv(k) = sprintf("P=%.4g, V=%.4g", sct.rv_Pset(i), sct.rv_Vset(i));
            case "PQ";    sv(k) = sprintf("P=%.4g, Q=%.4g", sct.rv_Pset(i), sct.rv_Qset(i));
        end
    end
end


function check_bases(sct, iv)
% Unit="SI" needs baseMVA and the baseKV of the shown buses from the snapshot
    if isnan(sct.r_baseMVA) || any(isnan(sct.rv_baseKV(iv)))
        error(msg("GUILDA:ResultPF:NoBase"))
    end
end
