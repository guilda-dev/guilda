function s_legend = tab_sim_legend(h_panel)
% Legend of the diagram of the time simulation tab: the targets of the scenario selected.
    arguments (Input)
        h_panel  % Panel of the tab (UserData: the state).
    end
    arguments (Output)
        s_legend (1,1) string  % One line for the info strip.
    end
    sct = h_panel.UserData;
    if ~isempty(sct.sc) && isvalid(sct.sc)
        s_legend = "Selected: the targets of scenario " + string(sct.sc.s_tag) + ". Colors: branch current |I| [pu] at the equilibrium.";
    else
        s_legend = "Colors: branch current |I| [pu] at the equilibrium. Add a scenario to simulate.";
    end
end
