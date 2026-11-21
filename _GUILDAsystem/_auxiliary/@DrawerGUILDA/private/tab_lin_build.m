function sct_hook = tab_lin_build(h_panel, sct_app)
% Linearization tab: get_sys, with the stale banner.
%
% The panel is tab_analysis_panel with the form of PowerSystemModel.get_sys; the latest result
% overwrites res_lin and flag_lin of the history. The point input keeps its default [] (the
% equilibrium of net.initialize). The diagram is the default one (draw_network: the
% equilibrium, or the topology while stale).
    arguments (Input)
        h_panel  % Panel of the tab.
        sct_app  % Tab API (see tab_list).
    end
    arguments (Output)
        sct_hook (1,1) struct  % Hooks of the tab (see tab_list).
    end
    sct_hook = tab_analysis_panel(h_panel, sct_app, struct( ...
        "s_signature", "PowerSystemModel.get_sys", "sv_output", ["res_lin", "flag_lin"], "s_label", "Linearize", ...
        "l_banner", true, "sv_exclude", "Format", "f_value", @(~) struct(), ...
        "s_note", "The default point [] linearizes at the equilibrium (the result of net.initialize).", ...
        "sct_extra", struct([])));
end
