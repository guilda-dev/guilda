function redraw(obj, l_force)
% Write the info strip for the active tab, draw its diagram when it is out of date, and show the controls of the diagram. Nothing is logged.
%
% Each tab draws into a panel of its own (Tag "diagram_<key>", made on its first drawing) in
% the grid of h_diagram. Its diagram is drawn when the history ended a run since its last
% drawing (n_drawn < n_change) or with l_force (f_redraw of the tab API); otherwise it is
% shown as it is. The hook f_diagram of the tab draws it; without it, draw_network draws
% net.plot_diagram(State="auto") with no selection. When the hook returns another diagram,
% the click listener of the tab moves to it; [] means no diagram. An error of the drawing is
% shown in the info strip. obj.G is the diagram of the active tab.
%
% The first line of the info strip shows the counts of buses, branches and components, the
% stale state of the network and the last entry of the history. The second line says what
% the colors of the diagram mean: the hook f_legend of the tab, or by default the legend of
% draw_network (branch currents, or the topology while the network is stale).
%
% While the toggle "Display options" is pressed, the second column of h_side (230 px) holds
% the control panel of the diagram of the active tab (G.show_controls, made once per
% diagram and kept through its drawings; those of the other tabs are hidden); its changes are
% not logged. A diagram without declared controls keeps the column at 0 px and the info
% strip says so. Otherwise that column is 0 px wide and the control panels are removed.
    arguments (Input)
        obj
        l_force (1,1) logical = false  % Draw the diagram of the active tab even when it is up to date.
    end
    arguments (Output)
    end
    if obj.s_active == "" || ~isvalid(obj.h_diagram)
        return
    end
    sct_color = tools.gui_palette();
    try
        net = obj.history.get_variable("net");
    catch
        net = [];
    end
    if ~(isa(net, "PowerNetwork") && isscalar(net) && isvalid(net))
        obj.h_info.Text = "No network (no variable net in the workspace of the log)";
        return
    end

    % Info strip: counts, stale state and last run
    n_comp = sum(cellfun(@(b) numel(b.a_Component), net.a_Bus));
    sct_stale = net.sct_stale;
    sv_stale = string(fieldnames(sct_stale)).';
    sv_stale = sv_stale(arrayfun(@(s) ~isempty(sct_stale.(s)), sv_stale));
    s_text = sprintf("%d buses · %d branches · %d components", numel(net.a_Bus), numel(net.a_Branch), n_comp);
    if isempty(sv_stale)
        s_text = s_text + "  |  State: up to date";
        obj.h_info.FontColor = sct_color.rv_text;
        obj.h_info.BackgroundColor = sct_color.rv_card;
    else
        s_text = s_text + "  |  State: run initialize (" + join(sv_stale, ", ") + ")";
        obj.h_info.FontColor = sct_color.rv_stale_text;
        obj.h_info.BackgroundColor = sct_color.rv_stale_back;
    end
    tab = obj.history.tab_entry;
    if ~isempty(tab)
        s_mark = "✔";
        if tab.Status(end) == "fail"
            s_mark = "✖";
        end
        s_text = s_text + "  |  Last run: " + s_mark + " " + tab.Label(end);
    end

    % Diagram of the tab: drawn when out of date
    i_tab = find([obj.sct_tab.s_key] == obj.s_active, 1);
    if isempty(obj.sct_tab(i_tab).h_diagram) || ~isgraphics(obj.sct_tab(i_tab).h_diagram)
        h_panel = uipanel(obj.h_diagram.Children(1), "Tag", "diagram_" + obj.s_active, "BorderType", "none", ...
            "BackgroundColor", sct_color.rv_card);
        h_panel.Layout.Row = 1;
        h_panel.Layout.Column = 1;
        obj.sct_tab(i_tab).h_diagram = h_panel;
    end
    if l_force || obj.sct_tab(i_tab).n_drawn < obj.n_change
        f_diagram = obj.sct_tab(i_tab).f_diagram;
        if isempty(f_diagram)
            f_diagram = @(G, h_parent) draw_network(G, h_parent, net, true);
        end
        G_old = obj.sct_tab(i_tab).G;
        obj.sct_tab(i_tab).s_error = "";
        try
            G_new = f_diagram(G_old, obj.sct_tab(i_tab).h_diagram);
        catch ME
            G_new = G_old;
            obj.sct_tab(i_tab).s_error = "Cannot draw the diagram: " + string(ME.message);
        end
        obj.sct_tab(i_tab).n_drawn = obj.n_change;
        if ~(~isempty(G_new) && ~isempty(G_old) && isvalid(G_old) && G_new == G_old)
            delete(obj.sct_tab(i_tab).a_click);
            obj.sct_tab(i_tab).a_click = [];
            obj.sct_tab(i_tab).G = G_new;
            obj.sct_tab(i_tab).l_controls = false;
            if ~isempty(G_new)
                obj.sct_tab(i_tab).a_click = listener(G_new, "ElementClicked", @(~, data) obj.call_hook("f_click", data));
            end
            if isa(G_new, "GraphNetDiagram")
                obj.sct_tab(i_tab).l_flow = G_new.FlowAnimation;
            end
        end
    end
    G = obj.sct_tab(i_tab).G;
    obj.G = G;

    % Legend
    f_legend = obj.sct_tab(i_tab).f_legend;
    if obj.sct_tab(i_tab).s_error ~= ""
        s_legend = obj.sct_tab(i_tab).s_error;
    elseif ~isempty(f_legend)
        s_legend = f_legend();
    elseif isempty(sv_stale)
        s_legend = "Colors: branch current |I| [pu] at the equilibrium (colorbar).";
    else
        s_legend = "Topology only (the network is stale): run initialize to see the flows.";
    end
    l_graph = isa(G, "GraphBase") && isscalar(G) && isvalid(G) && ~isempty(G.ax) && all(isgraphics(G.ax));

    % Control panels of the diagrams, in the second column of h_side
    if obj.h_toggle.Value
        if l_graph && (isempty(G.h_controls) || ~isgraphics(G.h_controls))
            h_panel = G.show_controls(Parent=obj.h_side);
            h_panel.Layout.Row = 1;
            h_panel.Layout.Column = 2;
            % A graph without declared controls gets no empty column, and the strip says so
            obj.sct_tab(i_tab).l_controls = any(~arrayfun(@(h) isa(h, "matlab.ui.container.Panel") ...
                || isa(h, "matlab.ui.container.GridLayout") || isa(h, "matlab.ui.control.Label"), findall(h_panel)));
        end
        for i = 1:numel(obj.sct_tab)
            G_i = obj.sct_tab(i).G;
            if isa(G_i, "GraphBase") && isscalar(G_i) && isvalid(G_i) && ~isempty(G_i.h_controls) && isgraphics(G_i.h_controls)
                G_i.h_controls.Visible = l_graph && i == i_tab;
            end
        end
        if l_graph && obj.sct_tab(i_tab).l_controls
            obj.h_side.ColumnWidth{2} = 230;
        else
            obj.h_side.ColumnWidth{2} = 0;
            if l_graph
                s_legend = s_legend + " (This diagram has no display options.)";
            end
        end
    else
        obj.h_side.ColumnWidth{2} = 0;
        delete(obj.h_side.Children(obj.h_side.Children ~= obj.h_diagram));
    end
    obj.h_info.Text = [s_text; " " + s_legend];
    obj.h_info.Tooltip = s_text + newline + s_legend;
end
