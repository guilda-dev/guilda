function sct_tab = tab_list()
% The tabs of the GUILDA app, in the order of the tab bar: the only place they are registered.
%
% Each tab is a set of private files of DrawerGUILDA named after its key, tab_<key>_*.m.
% Its build function `sct_hook = tab_<key>_build(h_panel, sct_app)` is called on the first
% show of the tab. It fills h_panel (a uipanel of the right half of the app) and returns its
% hooks, a struct whose fields are all optional:
%
% - `f_show()`: the tab became the active tab (also right after the build). It runs on
%   every switch, so it should be cheap: redraw only what a run changed while the tab was
%   hidden (f_changed sees that the panel of the tab is hidden).
% - `f_changed()`: entries of the history ended (done or failed). The active tab gets it
%   after each entry, before its diagram is drawn again; a hidden tab gets it once on its
%   next show, while its panel is still hidden (before f_show).
% - `G = f_diagram(G, h_parent)`: draw the diagram of the tab. Each tab has a diagram of
%   its own: G is the diagram the hook returned last ([] before the first one) and h_parent
%   the diagram panel of the tab, which only the hook draws into (its UserData is free for
%   the hook). The frame calls it while the tab is active, when a run of the history ended
%   since the last drawing (also on the show of a tab that was hidden then) and on
%   f_redraw; a tab switch without a run in between does not call it. Return the diagram
%   drawn: G itself (e.g. net.plot_diagram(Graph=G, ...), which reuses the graphics objects
%   and keeps the positions, styles and selection; the fastest), or a new one drawn in
%   h_parent after delete(h_parent.Children) (e.g. net.plot_diagram(Parent=h_parent)), or
%   [] for no diagram (the panel shows what the hook drew in it). Without the hook the
%   frame draws net.plot_diagram(State="auto") with no selection (draw_network). The
%   drawing is not logged. The diagram fits itself to its panel; the frame does not change
%   its limits. The diagrams show the network at the equilibrium (or its topology while
%   stale) with the conditions of the tab selected; a result is viewed in the Analyze result
%   window, not in the diagram.
% - `s_legend = f_legend()`: what the colors and selection of the diagram of the tab mean,
%   one line for the info strip (e.g. "Bus colors: slack red, PV blue, PQ gray."), called
%   after each drawing while the tab is active. Without it the frame writes the legend of
%   draw_network.
% - `f_click(data)`: an element of the diagram of the tab was clicked (data:
%   GraphEventData with Tag, Kind and Index).
%
% sct_app, the tab API, holds:
%
% - `app`: the DrawerGUILDA (read app.G, the diagram of the active tab, app.history, app.h_figure).
% - `history`: the HistoryGUILDA of the app; `history.get_variable("net")` is the network.
% - `s_title`: the title of the tab (tab bar).
% - `s_group`: the group of the entries of the tab (a section of the script).
% - `[l_ok, s_detail] = f_run(s_label, s_code, Progress=s_message)`: run code through the
%   history in the group of the tab. With Progress, an indeterminate uiprogressdlg without
%   cancel shows s_message while it runs (visible figure only). Code that runs an analysis
%   passes no Progress: the analysis shows its own progress dialog (ProgressGUILDA) in the
%   app figure (Tag "GUILDA:app"), and two dialogs in one figure would both stay open. A
%   failure shows an alert (visible figure only); the log keeps it in any case.
% - `h_banner = f_stale_banner(h_grid, i_row)`: a banner in row i_row of the uigridlayout
%   h_grid (all columns). While the network is stale it shows the stale tags and the button
%   "Run initialize", which runs `net.initialize();` through the history; otherwise the
%   row height is 0. It follows the history by itself.
% - `f_redraw()`: draw the diagram of the active tab again now (e.g. after the tab changed
%   what it highlights).
    arguments (Input)
    end
    arguments (Output)
        sct_tab (1,:) struct  % s_key, s_title (tab bar), s_group (history group) and f_build of each tab.
    end
    sct_tab = struct( ...
        "s_key",   {"model", "pf", "opf", "cpf", "sim", "lin"}, ...
        "s_title", {"Model", "Power flow", "OPF", "CPF", "Time simulation", "Linearization"}, ...
        "s_group", {"Model building", "Power flow", "Optimal power flow", "Continuation power flow", "Time simulation", "Linearization"}, ...
        "f_build", {@tab_model_build, @tab_pf_build, @tab_opf_build, @tab_cpf_build, @tab_sim_build, @tab_lin_build});
end
