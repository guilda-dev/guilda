function sct_hook = tab_opf_build(h_panel, sct_app)
% OPF tab: calculate_optimal_powerflow.
%
% The panel is tab_analysis_panel with the form of PowerNetwork.calculate_optimal_powerflow;
% the latest result overwrites res_opf and flag_opf of the history. The diagram is
% tab_opf_diagram (the components with a cost selected, before and after a run).
    arguments (Input)
        h_panel  % Panel of the tab.
        sct_app  % Tab API (see tab_list).
    end
    arguments (Output)
        sct_hook (1,1) struct  % Hooks of the tab (see tab_list).
    end
    sct_hook = tab_analysis_panel(h_panel, sct_app, struct( ...
        "s_signature", "PowerNetwork.calculate_optimal_powerflow", "sv_output", ["res_opf", "flag_opf"], "s_label", "Calculate optimal power flow", ...
        "l_banner", false, "sv_exclude", "Format", "f_value", @(~) struct(), ...
        "s_note", "", "sct_extra", struct([])));
    sct_hook.f_diagram = @(G, h_parent) tab_analysis_diagram(G, h_parent, sct_app.history, @tab_opf_diagram);
    sct_hook.f_legend = @() "Selected: the components with a cost (tab_parameter.OPF). Open Analyze result after a run to see the LMP.";
end
