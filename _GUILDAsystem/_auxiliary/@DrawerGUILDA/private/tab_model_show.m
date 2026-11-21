function tab_model_show(h_panel)
% Hook f_show of the model tab: draw the model GUI again when a run ended while the tab was hidden.
%
% The model GUI draws itself after its own actions; a run from another tab or the log while
% the model tab is hidden marks it out of date (l_stale, tab_model_build).
    arguments (Input)
        h_panel  % Panel of the tab (UserData: the model GUI and l_stale).
    end
    arguments (Output)
    end
    if ~isstruct(h_panel.UserData) || ~h_panel.UserData.l_stale
        return
    end
    h_panel.UserData.l_stale = false;
    h_panel.UserData.gui.render();
end
