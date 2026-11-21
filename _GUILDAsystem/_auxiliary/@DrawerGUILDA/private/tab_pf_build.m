function sct_hook = tab_pf_build(h_panel, sct_app)
% Power flow tab: calculate_powerflow, and the form of net.initialize.
%
% The panel is tab_analysis_panel with the form of PowerNetwork.calculate_powerflow; the
% latest result overwrites res_pf and flag_pf of the history. Under it, the form of
% PowerNetwork.initialize and the button "Set equilibrium" (Tag "pf_initialize") run
% net.initialize(...); (no outputs). Its options whose default is written in words (the
% settings of the analysis that Method runs) start empty and are left out. The diagram is
% tab_pf_diagram (the buses colored by type, before and after a run).
    arguments (Input)
        h_panel  % Panel of the tab.
        sct_app  % Tab API (see tab_list).
    end
    arguments (Output)
        sct_hook (1,1) struct  % Hooks of the tab (see tab_list).
    end
    sct_hook = tab_analysis_panel(h_panel, sct_app, struct( ...
        "s_signature", "PowerNetwork.calculate_powerflow", "sv_output", ["res_pf", "flag_pf"], "s_label", "Calculate power flow", ...
        "l_banner", false, "sv_exclude", "Format", "f_value", @(~) struct(), ...
        "s_note", "", ...
        "sct_extra", struct("s_signature", "PowerNetwork.initialize", "s_title", "Equilibrium (net.initialize)", ...
            "s_text", "Set equilibrium", "s_tag", "pf_initialize", "s_label", "Initialize")));
    sct_hook.f_diagram = @(G, h_parent) tab_analysis_diagram(G, h_parent, sct_app.history, @tab_pf_diagram);
    sct_hook.f_legend = @() "Bus colors: slack red, PV blue, PQ gray. Open Analyze result after a run to see the flows.";
end
