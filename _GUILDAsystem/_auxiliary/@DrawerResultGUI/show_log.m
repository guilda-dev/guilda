function show_log(obj, h_tab)
% Draw the view of the log in the Log tab when it is opened first (HistoryGUILDA.attach_view).
%
% The view costs a draw of its own, so render leaves the tab empty and the tab group calls
% this when a tab is selected; another tab, or a Log tab that already has its view, is left
% as it is.
    arguments (Input)
        obj
        h_tab  % Tab selected (matlab.ui.container.Tab).
    end
    arguments (Output)
    end
    if isvalid(h_tab) && string(h_tab.Tag) == "log" && isempty(h_tab.Children)
        obj.history.attach_view(h_tab);
    end
end
