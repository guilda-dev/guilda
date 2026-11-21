function h_panel = show_controls(obj, opt)
% Show a panel of controls that change what the graph shows.
%
% The panel is made from the declaration control_list of the class: one control per
% property (a dropdown, checkbox, slider, spinner, a range of two spinners, with an Auto
% checkbox when the range can be automatic, or a toggle button), under the headings of
% their groups. The time is not in the panel: the playback bar below the axes has it (see
% GraphBase). The controls only set the properties, so a change in the panel is the same
% as setting the property in code, and a change of the property in code (or by set_style,
% another panel) is shown in the panel. A value the property refuses is reported (an
% alert in a visible figure, a warning otherwise) and the control goes back to the value
% of the property.
%
% Parent empty puts the panel next to the axes, in the container of the axes (or of their
% tiled layout): the axes give up the right part of about 220 pixels (the share is kept
% when the figure is resized; the playback bar keeps the width of the axes). A container (figure, uifigure, uipanel, uitab or
% uigridlayout, e.g. a cell prepared by a GUI) gets the panel filling it. A panel shown
% before is replaced. The panel stays through set_data and is deleted with the axes;
% hide_controls removes it.
%
% ChangedFcn is called as fcn(G, s_property, value) after a control set a property,
% e.g. to record the change as code.
%
% <@Examples>
% ```matlab
% G = res.plot_spring_model();
% G.show_controls();
% G.ShowLabel = false;                    % the checkbox follows
% h = G.show_controls(Parent=uipanel(uifigure), ...
%                     ChangedFcn=@(G, s, v) disp("G." + s + " = " + mat2str(v)));
% ```
    arguments (Input)
        obj
        opt.Parent = []      % Container of the panel (figure, uifigure, uipanel, uitab, uigridlayout); [] next to the axes.
        opt.ChangedFcn = []  % Function called as fcn(G, s_property, value) after a control set a property; [] for none. <@Type> function_handle
    end
    arguments (Output)
        h_panel  % The panel of controls. <@Type> matlab.ui.container.Panel
    end
    if ~all(isgraphics(obj.ax))
        error(msg("GUILDA:GraphBase:NoAxes", class(obj)));
    end
    if ~(isempty(opt.ChangedFcn) || isa(opt.ChangedFcn, "function_handle"))
        error(msg("GUILDA:GraphBase:ChangedFcn", class(opt.ChangedFcn)));
    end
    h_parent = opt.Parent;
    sv_container = ["matlab.ui.Figure", "matlab.ui.container.Panel", "matlab.ui.container.Tab", ...
                    "matlab.ui.container.GridLayout"];
    if ~isempty(h_parent) && ~(isscalar(h_parent) && isgraphics(h_parent) ...
            && any(arrayfun(@(s) isa(h_parent, s), sv_container)))
        error(msg("GUILDA:GraphBase:ControlsParent", class(h_parent)));
    end

    % Declared controls with the fields left out filled
    sct_in   = obj.control_list();
    sv_field = ["Property", "Widget", "Items", "Limits", "Step", "Label", "Group", "EnableFcn"];
    sct_ctl  = cell2struct(cell(numel(sv_field), 0), cellstr(sv_field), 1);
    for i = 1:numel(sct_in)
        ctl = cell2struct(cell(numel(sv_field), 1), cellstr(sv_field), 1);
        for s_field = sv_field
            if isfield(sct_in, s_field)
                ctl.(s_field) = sct_in(i).(s_field);
            end
        end
        ctl.Property = string(ctl.Property);
        ctl.Widget   = string(ctl.Widget);
        if ~(ctl.Widget == "range" && isa(ctl.Items, "function_handle"))
            ctl.Items = string(ctl.Items);     % a range keeps its function of the automatic values
        end
        ctl.Label    = string(ctl.Label);
        ctl.Group    = string(ctl.Group);
        if ~any(ctl.Widget == ["dropdown", "checkbox", "slider", "spinner", "range", "toggle"])
            error(msg("GUILDA:GraphBase:ControlWidget", ctl.Property, class(obj), join(ctl.Widget, "")));
        end
        mp = findprop(obj, ctl.Property);
        if isempty(mp) || ~mp.SetObservable || ~ischar(mp.SetAccess) || mp.SetAccess ~= "public"
            error(msg("GUILDA:GraphBase:ControlProperty", ctl.Property, class(obj)));
        end
        if isempty(ctl.Label) || ctl.Label == ""
            ctl.Label = ctl.Property;
        end
        if isempty(ctl.Group) || ctl.Group == ""
            ctl.Group = "View";
        end
        if isempty(ctl.Limits)
            ctl.Limits = [-Inf Inf];
            if ctl.Widget == "slider"
                ctl.Limits = [0 1];
            end
        end
        sct_ctl(end+1) = ctl; %#ok<AGROW>
    end

    obj.hide_controls();

    % The panel: next to the axes, or filling the container given
    fcn_restore = [];
    if isempty(h_parent)
        h_move = obj.ax(1);
        if isa(h_move.Parent, "matlab.graphics.layout.TiledChartLayout")
            h_move = h_move.Parent;
        end
        h_host = h_move.Parent;
        if isa(h_host, "matlab.ui.container.GridLayout") || isa(h_host, "matlab.graphics.layout.TiledChartLayout")
            error(msg("GUILDA:GraphBase:ControlsPlace", class(obj)));
        end
        s_units = string(h_move.Units);
        h_move.Units = "normalized";
        rv_pos = h_move.OuterPosition;
        rv_px  = getpixelposition(h_host);
        r_share = min(0.5, 220 / max(rv_px(3), 1));
        h_move.OuterPosition = [rv_pos(1)*(1-r_share), rv_pos(2), rv_pos(3)*(1-r_share), rv_pos(4)];
        h_panel = uipanel(h_host, "Units", "normalized", "Position", [1-r_share 0 r_share 1]);
        fcn_restore = @() set(h_move(isvalid(h_move)), "OuterPosition", rv_pos, "Units", s_units);
        obj.place_bar();     % the bar keeps the width of the axes
    elseif isa(h_parent, "matlab.ui.container.GridLayout")
        h_panel = uipanel(h_parent);
    else
        h_panel = uipanel(h_parent, "Units", "normalized", "Position", [0 0 1 1]);
    end
    h_panel.Tag   = "GUILDA:GraphBase:Controls";
    h_panel.Title = "Controls";

    % Rows: a heading per group, then its controls
    sv_group = unique(string([sct_ctl.Group]), "stable");
    n_row = numel(sv_group) + numel(sct_ctl);
    gl = uigridlayout(h_panel, [max(n_row, 1) 2], "ColumnWidth", {"fit", "1x"}, ...
        "RowHeight", repmat({"fit"}, 1, max(n_row, 1)), "Scrollable", "on", ...
        "Padding", [8 8 8 8], "RowSpacing", 6, "ColumnSpacing", 6);
    c_widget = cell(1, numel(sct_ctl));
    wr = matlab.lang.WeakReference(obj);     % the callbacks hold the graph weakly (savefig; build keeps it alive)
    i_row = 0;
    if isempty(sct_ctl)
        h = uilabel(gl, "Text", "No controls for this graph.");
        h.Layout.Column = [1 2];
    end
    for s_group = sv_group
        i_row = i_row + 1;
        h = uilabel(gl, "Text", s_group, "FontWeight", "bold");
        h.Layout.Row = i_row;
        h.Layout.Column = [1 2];
        for i = find(string([sct_ctl.Group]) == s_group)
            ctl = sct_ctl(i);
            i_row = i_row + 1;
            fcn = @(~, ~) call_weak(wr, @(G) on_change(G, h_panel, i));
            switch ctl.Widget
                case "dropdown"
                    w = uidropdown(gl, "Items", ctl.Items, "ValueChangedFcn", fcn);
                case "checkbox"
                    w = uicheckbox(gl, "Text", ctl.Label, "ValueChangedFcn", fcn);
                case "toggle"
                    w = uibutton(gl, "state", "Text", ctl.Label, "ValueChangedFcn", fcn);
                case "slider"
                    w = uislider(gl, "Limits", ctl.Limits, "MinorTicks", [], "ValueChangedFcn", fcn);
                case "spinner"
                    w = uispinner(gl, "Limits", ctl.Limits, "ValueChangedFcn", fcn);
                    if ~isempty(ctl.Step)
                        w.Step = ctl.Step;
                    end
                case "range"
                    l_auto = isa(ctl.Items, "function_handle");
                    c_col  = {"1x", "1x"};
                    if l_auto
                        c_col{end+1} = "fit"; %#ok<AGROW>
                    end
                    g2 = uigridlayout(gl, [1 numel(c_col)], "ColumnWidth", c_col, "RowHeight", {"fit"}, ...
                        "Padding", [0 0 0 0], "ColumnSpacing", 4);
                    g2.Layout.Row = i_row;
                    g2.Layout.Column = 2;
                    w = [uispinner(g2, "Limits", ctl.Limits, "ValueChangedFcn", fcn), ...
                         uispinner(g2, "Limits", ctl.Limits, "ValueChangedFcn", fcn)];
                    if ~isempty(ctl.Step)
                        set(w, "Step", ctl.Step);
                    end
                    if l_auto                  % a third widget: the automatic values (NaN)
                        w = [w, uicheckbox(g2, "Text", "Auto", ...
                            "ValueChangedFcn", @(~, ~) on_change(obj, h_panel, i, true))]; %#ok<AGROW>
                    end
            end
            if any(ctl.Widget == ["checkbox", "toggle"])
                w.Layout.Row = i_row;
                w.Layout.Column = [1 2];
            else
                h = uilabel(gl, "Text", ctl.Label);
                h.Layout.Row = i_row;
                h.Layout.Column = 1;
                if ctl.Widget ~= "range"
                    w.Layout.Row = i_row;
                    w.Layout.Column = 2;
                end
            end
            c_widget{i} = w;
        end
    end

    % The panel follows the properties; it goes with the axes
    sv_prop = unique(string([sct_ctl.Property]), "stable");
    c_listener = {listener(obj.ax(1), "ObjectBeingDestroyed", @(~, ~) delete(h_panel(isgraphics(h_panel))))};
    if ~isempty(sv_prop)
        c_listener{end+1} = listener(obj, cellstr(sv_prop), "PostSet", @(~, ~) call_weak(wr, @(G) G.refresh_controls()));
    end
    h_panel.UserData = struct("sct_ctl", sct_ctl, "c_widget", {c_widget}, "h_parent", h_parent, ...
        "fcn_changed", opt.ChangedFcn, "c_listener", {c_listener}, "fcn_restore", fcn_restore);
    h_panel.DeleteFcn = @(h, ~) on_delete(wr, h);
    obj.h_controls = h_panel;
    obj.refresh_controls();
end


function on_change(obj, h_panel, i_ctl, l_auto)
% Set the property of a control from its widget; on an error put the widget back.
    arguments (Input)
        obj                          % The graph.
        h_panel                      % The panel of controls.
        i_ctl (1,1) double           % Row of the control in the declaration.
        l_auto (1,1) logical = false % The Auto checkbox of a range changed: [NaN NaN] when checked.
    end
    sct = h_panel.UserData;
    ctl = sct.sct_ctl(i_ctl);
    w   = sct.c_widget{i_ctl};
    switch ctl.Widget
        case "dropdown"
            val = string(w.Value);
        case {"checkbox", "toggle"}
            val = logical(w.Value);
        case "range"
            val = [w(1).Value, w(2).Value];
            if l_auto && w(3).Value
                val = [NaN NaN];
            end
        otherwise
            val = w.Value;
    end
    try
        obj.(ctl.Property) = val;
    catch err
        obj.refresh_controls();
        fig = ancestor(h_panel, "figure");
        try
            assert(fig.Visible == "on");
            uialert(fig, err.message, ctl.Label);
        catch
            show_msg("warning", "GUILDA:GraphBase:ControlValue", ctl.Property, err.message);
        end
        return
    end
    obj.refresh_controls();
    if ~isempty(sct.fcn_changed)
        sct.fcn_changed(obj, ctl.Property, obj.(ctl.Property));
    end
end


function on_delete(wr, h_panel)
% Put the axes back in place and forget the panel when it is deleted (also once the graph is gone).
    arguments (Input)
        wr       % Weak reference to the graph. <@Type> matlab.lang.WeakReference
        h_panel  % The panel being deleted.
    end
    sct = h_panel.UserData;
    if isstruct(sct) && ~isempty(sct.fcn_restore)
        sct.fcn_restore();
    end
    G = wr.Handle;
    if ~isempty(G) && isvalid(G)
        if isequal(G.h_controls, h_panel)
            G.h_controls = gobjects(0);
        end
        if isstruct(sct) && ~isempty(sct.fcn_restore)
            G.place_bar();   % the bar takes back the width of the axes
        end
    end
end


function call_weak(wr, fcn)
% Call fcn(G) with the graph G held by the weak reference wr (nothing once it is deleted).
    arguments (Input)
        wr   % Weak reference to the graph. <@Type> matlab.lang.WeakReference
        fcn  % Function called as fcn(G). <@Type> function_handle
    end
    G = wr.Handle;
    if ~isempty(G) && isvalid(G)
        fcn(G);
    end
end

