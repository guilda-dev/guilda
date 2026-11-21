function sct_hook = tab_model_build(h_panel, sct_app)
% Model tab: the model GUI of the element selected in the diagram.
%
% The panel holds net.launch_gui(<panel>, History=<history of the app>), a DrawerModelGUI
% that shows the network first. Its state is in h_panel.UserData: the GUI, the network it
% shows and its listeners. A click on the diagram shows the element (tab_model_click); the
% element shown is selected in the diagram after each drawing, after a navigation in the
% model GUI (TargetChanged) and after its actions (ModelChanged) (tab_model_select).
%
% It is also the hook f_changed: when `net` of the history is another network than the one
% shown (e.g. `net = network.IEEE14bus();` from the start screen or the log), the GUI is
% built again for it. A run that ends while the tab is hidden marks the GUI out of date
% (l_stale), and the hook f_show (tab_model_show) draws it again on the next show; a show
% without a run in between draws nothing.
    arguments (Input)
        h_panel  % Panel of the tab.
        sct_app  % Tab API (see tab_list).
    end
    arguments (Output)
        sct_hook (1,1) struct  % Hooks f_show, f_changed, f_diagram and f_click.
    end
    sct_hook = struct( ...
        "f_show",    @() tab_model_show(h_panel), ...
        "f_changed", @() tab_model_build(h_panel, sct_app), ...
        "f_diagram", @(G, h_parent) tab_model_diagram(G, h_parent, h_panel, sct_app.history), ...
        "f_click",   @(data) tab_model_click(data, h_panel));
    try
        net = sct_app.history.get_variable("net");
    catch    % no network
        return
    end
    sct_state = h_panel.UserData;
    if ~(isa(net, "PowerNetwork") && isscalar(net) && isvalid(net))
        return
    elseif isstruct(sct_state) && isvalid(sct_state.gui) && sct_state.net == net
        h_panel.UserData.l_stale = sct_state.l_stale || ~h_panel.Visible;
        return
    end
    if isstruct(sct_state)
        delete(sct_state.a_listener);
    end
    delete(h_panel.Children);
    sct_color = tools.gui_palette();
    h_grid = uigridlayout(h_panel, [1 1], "Padding", 0, "BackgroundColor", sct_color.rv_background);
    h_gui = net.launch_gui(h_grid, History=sct_app.history);
    f_select = @(~, ~) tab_model_select(sct_app.app.G, h_gui.a_target, net);
    h_panel.UserData = struct("gui", h_gui, "net", net, "l_stale", false, "a_listener", ...
        [listener(h_gui, "TargetChanged", f_select), listener(h_gui, "ModelChanged", f_select)]);
end
