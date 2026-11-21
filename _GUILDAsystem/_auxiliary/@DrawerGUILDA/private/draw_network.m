function G = draw_network(G, h_parent, net, l_clear)
% Draw net.plot_diagram(State="auto") in the diagram panel: into G when it is a diagram shown there, else anew.
%
% Into an existing GraphNetDiagram, plot_diagram(Graph=G) keeps the positions, styles and
% selection of the elements by tag; otherwise the panel is emptied and a new diagram is
% drawn in it. A network without buses gets a note instead and G is []. The INFO message of a topology drawing (a stale network) is not printed: the
% info strip of the app shows the stale state. The branches and links are colored by their
% current (ColorMode "I", ColorbarLabel "Branch current |I| [pu]"), and no title is written.
% The default drawing of the tabs (redraw) and the model tab use it.
    arguments (Input)
        G          % Diagram shown, or [].
        h_parent   % Panel of the diagram.
        net (1,1) PowerNetwork  % Network to draw.
        l_clear (1,1) logical   % Clear the selection.
    end
    arguments (Output)
        G  % Diagram drawn; [] for a network without buses (a note is shown instead). <@Type> GraphNetDiagram
    end
    if isempty(net.a_Bus)    % nothing to draw: a note instead of the diagram
        delete(h_parent.Children);
        sct_color = tools.gui_palette();
        uilabel(uigridlayout(h_parent, [1 1], "BackgroundColor", sct_color.rv_card), ...
            "Text", "No buses yet. Add one with + Bus on the right.", "Tag", "diagram_empty", ...
            "HorizontalAlignment", "center", "FontColor", sct_color.rv_subtext, "BackgroundColor", sct_color.rv_card);
        G = [];
        return
    end
    s_label = "Branch current |I| [pu]"; %#ok<NASGU> used in evalc
    if isa(G, "GraphNetDiagram") && isscalar(G) && isvalid(G) && ~isempty(G.ax) && all(isgraphics(G.ax)) ...
            && isequal(ancestor(G.ax(1), "uipanel"), h_parent)
        evalc("G = net.plot_diagram(Graph=G, State=""auto"", ColorMode=""I"", ColorbarLabel=s_label, TitleFormat="""");");
    else
        delete(h_parent.Children);
        evalc("G = net.plot_diagram(Parent=h_parent, State=""auto"", ColorMode=""I"", ColorbarLabel=s_label, TitleFormat="""");");
    end
    if l_clear
        G.clear_selection();
    end
end
