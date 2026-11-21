function h = attach_view(obj, h_container)
% Draw the log in a container of a uifigure and keep it up to date.
%
% The view is a uilistbox that fills the container (a uifigure, uipanel or uitab gets a
% 1-by-1 grid; in a uigridlayout it takes the next cell). Each entry is a line
% `[mark] Label → Detail` (mark □ none, ▶ "run", ✔ "done", ✖ "fail") followed by its code
% as `>> code` lines, under a `【Group】` heading for each run of consecutive entries of one
% Group. It is redrawn on the event Changed until it is deleted. A double click on a `>>`
% line opens the file of the method or function it calls first, when that can be found
% (best effort: the class of the receiver is evaluated in the workspace of the log). The
% colors are the fixed light palette of the GUILDA GUIs (tools.gui_palette).
%
% <@Examples>
% ```matlab
% fig = uifigure();
% h_list = h.attach_view(fig);
% ```
    arguments (Input)
        obj          % The log.
        h_container  % uifigure, uipanel, uitab or uigridlayout of a uifigure.
    end
    arguments (Output)
        h  % The list box of the view. <@Type> matlab.ui.control.ListBox
    end
    if ~tools.is_ui_container(h_container)
        error(msg("GUILDA:HistoryGUILDA:NotUIContainer", class(h_container)))
    end
    sct_color = tools.gui_palette();
    if ~isa(h_container, "matlab.ui.container.GridLayout")
        h_container = uigridlayout(h_container, [1 1], "Padding", 0, ...
            "BackgroundColor", sct_color.rv_background);
    end
    h = uilistbox(h_container, "Items", {}, "Multiselect", "on", "FontSize", 12, ...
        "BackgroundColor", sct_color.rv_card, "FontColor", sct_color.rv_text);
    h.DoubleClickedFcn = @(~, ~) open_line(obj, h);
    h_listener = listener(obj, "Changed", @(~, ~) render_view(obj, h));
    h.DeleteFcn = @(~, ~) delete(h_listener);
    render_view(obj, h);
end
