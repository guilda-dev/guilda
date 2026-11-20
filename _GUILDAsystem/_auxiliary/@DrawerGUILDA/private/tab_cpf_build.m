function sct_hook = tab_cpf_build(h_panel, sct_app)
% CPF tab: calculate_continuation_powerflow, with the stale banner.
%
% The panel is tab_analysis_panel with the form of
% PowerNetwork.calculate_continuation_powerflow; the latest result overwrites res_cpf and
% flag_cpf of the history. While net.solver_CPF.LoadBus is empty, LoadBus starts with the
% buses that have a load (component.load.*), so the form runs as it is. The diagram is
% tab_cpf_diagram.
    arguments (Input)
        h_panel  % Panel of the tab.
        sct_app  % Tab API (see tab_list).
    end
    arguments (Output)
        sct_hook (1,1) struct  % Hooks of the tab (see tab_list).
    end
    sct_hook = tab_analysis_panel(h_panel, sct_app, struct( ...
        "s_signature", "PowerNetwork.calculate_continuation_powerflow", "sv_output", ["res_cpf", "flag_cpf"], "s_label", "Calculate continuation power flow", ...
        "l_banner", true, "sv_exclude", "Format", "f_value", @tab_cpf_value, ...
        "s_note", "LoadBus starts with the buses that have a load (component.load.*) while net.solver_CPF.LoadBus is empty.", ...
        "sct_extra", struct([])));
    sct_hook.f_diagram = @(G, h_parent) tab_analysis_diagram(G, h_parent, sct_app.history, @tab_cpf_diagram);
    sct_hook.f_legend = @() tab_analysis_legend(sct_app.history, "res_cpf", "ResultCPF", ...
        "Selected: the LoadBus buses of the last run. Colors: branch current |I| [pu] at the equilibrium.", ...
        "Colors: branch current |I| [pu] at the equilibrium. After a run the LoadBus buses are selected.");
end
