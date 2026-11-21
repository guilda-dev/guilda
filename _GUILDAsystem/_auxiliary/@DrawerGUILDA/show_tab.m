function show_tab(obj, s_key)
% Make a tab active: press its button, show its panel and its diagram (building the tab on
% its first show), call its hook f_show and draw its diagram when it is out of date.
%
% A built tab that missed runs of the history while hidden gets its hook f_changed first,
% once, before its panel is shown. Only the button, panel and diagram panel of the tab left
% and of the tab shown change. The
% diagram of the tab left stops its flow animation (its FlowAnimation is kept and given back
% on its next show). The build function of the tab (tab_list) gets the tab API (see
% tab_list) and returns the hooks; a hook it leaves out stays [].
    arguments (Input)
        obj
        s_key (1,1) string  % Key of the tab (tab_list).
    end
    arguments (Output)
    end
    sct_color = tools.gui_palette();
    sv_key = [obj.sct_tab.s_key];
    i_tab = find(sv_key == s_key, 1);
    i_old = find(sv_key == obj.s_active, 1);
    % A run ended while the tab was hidden: its f_changed, still hidden (a tab can tell by its panel)
    if obj.sct_tab(i_tab).l_built && obj.sct_tab(i_tab).n_changed < obj.n_change
        obj.sct_tab(i_tab).n_changed = obj.n_change;
        if ~isempty(obj.sct_tab(i_tab).f_changed)
            obj.sct_tab(i_tab).f_changed();
        end
    end
    for i = unique([i_old, i_tab])
        l_active = i == i_tab;
        h_button = obj.sct_tab(i).h_button;
        h_button.Value = l_active;
        if l_active
            h_button.BackgroundColor = sct_color.rv_background;
            h_button.FontColor = sct_color.rv_blue;
        else
            h_button.BackgroundColor = sct_color.rv_blue;
            h_button.FontColor = sct_color.rv_header_text;
        end
        obj.sct_tab(i).h_panel.Visible = l_active;
        if ~isempty(obj.sct_tab(i).h_diagram) && isgraphics(obj.sct_tab(i).h_diagram)
            obj.sct_tab(i).h_diagram.Visible = l_active;
        end
    end
    if ~isempty(i_old) && i_old ~= i_tab
        G_old = obj.sct_tab(i_old).G;
        if isa(G_old, "GraphNetDiagram") && isscalar(G_old) && isvalid(G_old)
            obj.sct_tab(i_old).l_flow = G_old.FlowAnimation;
            G_old.FlowAnimation = false;
        end
    end
    obj.s_active = s_key;
    if ~obj.sct_tab(i_tab).l_built
        s_group = obj.sct_tab(i_tab).s_group;
        sct_app = struct("app", obj, "history", obj.history, "s_title", obj.sct_tab(i_tab).s_title, "s_group", s_group, ...
            "f_run", @(s_label, s_code, varargin) obj.run_code(s_group, s_label, s_code, varargin{:}), ...
            "f_stale_banner", @(h_grid, i_row) obj.stale_banner(h_grid, i_row, s_group), ...
            "f_redraw", @() obj.redraw(true));
        sct_hook = obj.sct_tab(i_tab).f_build(obj.sct_tab(i_tab).h_panel, sct_app);
        obj.sct_tab(i_tab).l_built = true;
        obj.sct_tab(i_tab).n_changed = obj.n_change;
        for s_hook = ["f_show", "f_changed", "f_diagram", "f_legend", "f_click"]
            if isfield(sct_hook, s_hook)
                obj.sct_tab(i_tab).(s_hook) = sct_hook.(s_hook);
            end
        end
    end
    obj.call_hook("f_show");
    obj.redraw();
    G = obj.sct_tab(i_tab).G;
    if isa(G, "GraphNetDiagram") && isscalar(G) && isvalid(G)
        G.FlowAnimation = obj.sct_tab(i_tab).l_flow;    % starts the timer of a visible figure (flow_timer)
    end
end
