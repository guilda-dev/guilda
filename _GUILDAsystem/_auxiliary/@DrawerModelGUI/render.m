function render(obj, a_target)
% Show a model: write the GUI of a_target into the components drawn in the container.
%
% An app that embeds the GUI calls it to switch the model; the breadcrumb, the child tables
% and the actions call it too. A deleted model shows a message instead. When a_target is
% another model than the one shown before, TargetChanged is notified after the drawing.
%
% The components are built once (build_frame) and kept: a render writes the header texts
% and the child table into them, and writes a property only when its value changes, since
% every write is sent to the figure. The add buttons of a kind of model and the child table
% are made on their first use and detached from the grid when not needed, to be attached
% again by a later render. The Parameter tab and the pages are one uihtml (the body), whose
% Data (body_data) is sent once per render, only when it changed; the tab of the same title
% stays selected.
%
% <@Examples>
% ```matlab
% net = network.IEEE14bus();
% h = net.launch_gui();
% h.render(net.a_Bus{2});
% ```
    arguments (Input)
        obj
        a_target (1,1) LayerPackage = obj.a_target  % Model to show (default: the one shown).
    end
    arguments (Output)
    end
    if ~isvalid(obj.h_container)
        return
    end
    l_newTarget = isempty(obj.a_target) || obj.a_target ~= a_target;
    obj.a_target = a_target;
    m_ui = obj.m_ui;
    sct_color = tools.gui_palette();
    if ~isvalid(a_target)    % a deleted model: the message alone (the next render builds the GUI again)
        h_layout = clear_gui(obj.h_container, m_ui);
        h_grid = uigridlayout(obj.h_container, [1 1], "RowHeight", {"fit"}, "Padding", [10 10 10 10], ...
            "Tag", "DrawerModelGUI", "BackgroundColor", sct_color.rv_background);
        if isa(h_layout, "matlab.ui.layout.GridLayoutOptions")
            h_grid.Layout = h_layout;
        end
        uilabel(h_grid, "Text", "The model has been deleted.", "FontWeight", "bold", ...
            "FontColor", sct_color.rv_text, "BackgroundColor", sct_color.rv_background);
        if l_newTarget
            notify(obj, "TargetChanged")
        end
        return
    end
    % The components are built on the first render (or when the grid was removed) and kept
    if ~(isKey(m_ui, "grid") && isvalid(m_ui("grid")) && isequal(m_ui("grid").Parent, obj.h_container))
        build_frame(obj.h_container, m_ui);
    end
    h_grid = m_ui("grid");
    if isa(obj.h_container, "matlab.ui.Figure")
        set_changed(obj.h_container, "Name", class(a_target) + " " + string(a_target.s_tag));
    end
    sct_model = obj.f_model(a_target);

    % Models from the root to a_target, through the parents
    a_chain = {a_target};
    a_parent = sct_model.parent;
    while true
        if iscell(a_parent)
            a_parent = [a_parent{:}];
        end
        if isempty(a_parent)
            break
        end
        a_chain = [{a_parent}, a_chain]; %#ok<AGROW>
        a_parent = obj.f_model(a_parent).parent;
    end

    % Actions, made here so that they can run the private run_code. LocalController
    % additions and removals go to the component that holds the controller. A model of
    % another tree than the root of the history (h.render of a host) is shown without actions.
    try
        s_expr = obj.model_expression(a_target, a_chain);
    catch
        s_expr = "";
    end
    s_owner = regexprep(s_expr, "(\.a_LocalController\{\d+\})+$", "");
    if ~contains(s_expr, ".a_Component{")
        s_owner = "";    % a controller outside a component: no component to add to
    end
    f_run = @(s_label, s_code, varargin) obj.run_code(s_label, s_code, varargin{:});

    update_header(m_ui, obj, a_chain);
    % The add buttons and the child tables take the left column; a model with neither leaves it to the tabs.
    sm_add = strings(0, 4);    % label, signature, object expression, kind (color)
    if isa(a_target, "PowerNetwork")
        sm_add = ["Bus", "PowerNetwork.add_bus", "", "Bus"; "Branch", "PowerNetwork.add_branch", "", "Branch"; ...
            "Controller", "PowerNetwork.add_global_controller", "", "GlobalController"; ...
            "Scenario", "PowerNetwork.add_scenario", "", "Scenario"];
    elseif isa(a_target, "Bus")
        sm_add = ["Component", "Bus.add_component", "", "Component"];
    elseif isa(a_target, "Component") || (isa(a_target, "LocalController") && s_owner ~= "")
        sm_add = ["Controller", "Component.add_local_controller", "", "LocalController"];
    elseif isa(a_target, "Scenario")
        sm_add = ["Fault", "Scenario.add_fault"; "Trip", "Scenario.add_trip"; "Open branch", "Scenario.add_open_branch"; ...
            "Offset", "Scenario.add_offset"; "Input", "Scenario.add_input"];
        sm_add(:, 3:4) = "";
    end
    if s_expr == ""
        sm_add = strings(0, 4);
    elseif ~isempty(sm_add)
        sm_add(:, 3) = s_expr;
        if isa(a_target, "LocalController")
            sm_add(:, 3) = s_owner;
        end
    end
    a_children = sct_model.children;
    a_children = a_children(~cellfun(@(c) isa(c, "Parameter"), a_children));
    l_child = ~isempty(a_children);
    h_left = m_ui("left");
    h_body = m_ui("body");
    % The grid of the add buttons of this kind of model, kept for the next model of the kind
    s_add = join(sm_add(:, 2), ",");
    if isempty(sm_add)
        s_add = "";
    end
    sv_addKey = string(keys(m_ui));
    sv_addKey = sv_addKey(startsWith(sv_addKey, "add:"));
    for s_key = sv_addKey    % the other grids are detached
        h_add = m_ui(s_key);
        if s_key ~= "add:" + s_add && ~isempty(h_add.Parent)
            h_add.Parent = [];
        end
    end
    if s_add ~= ""
        if isKey(m_ui, "add:" + s_add)
            h_add = m_ui("add:" + s_add);
            if isempty(h_add.Parent)
                h_add.Parent = h_left;
            end
        else
            h_add = uigridlayout(h_left, [ceil(size(sm_add, 1)/2) + 1, 2], "Padding", [8 8 8 0], ...
                "RowHeight", repmat({"fit"}, 1, ceil(size(sm_add, 1)/2) + 1), "RowSpacing", 4, "ColumnSpacing", 4, ...
                "BackgroundColor", sct_color.rv_background);
            h_add.Layout.Row = 1;
            h_label = uilabel(h_add, "Text", "Add", "FontWeight", "bold", "FontColor", sct_color.rv_subtext, ...
                "BackgroundColor", sct_color.rv_background);
            h_label.Layout.Column = [1 2];
            for k = 1:size(sm_add, 1)
                rv_back = sct_color.rv_card;
                if isfield(sct_color.sct_kind, sm_add(k, 4))
                    rv_back = sct_color.sct_kind.(sm_add(k, 4));
                end
                uibutton(h_add, "Text", "+ " + sm_add(k, 1), "Tag", "add", "UserData", sm_add(k, 2), ...
                    "FontColor", sct_color.rv_text, "BackgroundColor", rv_back);
            end
            m_ui("add:" + s_add) = h_add;
            m_ui("spare") = [m_ui("spare"); h_add];
        end
        % The object expression of the buttons follows the model shown
        h_button = findobj(h_add.Children, "flat", "Type", "uibutton");
        for k = 1:numel(h_button)
            sv_arg = sm_add(sm_add(:, 2) == h_button(k).UserData, :);
            set_changed(h_button(k), "Tooltip", sv_arg(3) + "." + extractAfter(sv_arg(2), "."));
            h_button(k).ButtonPushedFcn = @(src, ~) add_model(src, obj, f_run, sv_arg);
        end
    end
    % The left column and the child tables stay in the grid (taking a uitable out of the figure and
    % back costs the figure much more than a row of height 0): without children the row of the
    % tables gets height 0 and the table loses the Tag "children", and without children and add
    % buttons the column gets width 0.
    if l_child
        update_navigation(m_ui, obj, a_children, s_expr, s_owner, f_run, obj.m_cache);
    else    % the row of the tables gets height 0 (a hidden component also costs a redraw)
        if isKey(m_ui, "children")
            set_changed(m_ui("children"), "Tag", "");
        end
    end
    c_row = {"fit", 0};
    c_column = {0, "1x"};
    if l_child
        c_row = {"fit", "1x"};
        c_column = {300, "1x"};
    elseif s_add ~= ""    % add buttons only: a column as wide as the buttons
        c_column = {"fit", "1x"};
    end
    set_changed(h_left, "RowHeight", c_row);
    set_changed(h_grid, "ColumnWidth", c_column);
    if s_add ~= ""
        c_width = {"fit", "fit"};
        if l_child
            c_width = {"1x", "1x"};
        end
        set_changed(h_add, "ColumnWidth", c_width);
    end

    % Body: Parameter (a Scenario has none), then the pages of gui_content, in one Data
    % (body_data); the tab of the same title stays selected (e.g. Equilibrium from one bus to the next)
    s_selected = "";
    if isKey(m_ui, "selected")
        s_selected = m_ui("selected");
    end
    sct_data = body_data(a_target, sct_model.pages, s_expr, s_selected);
    m_ui("selected") = sct_data.selected;
    sct_old = h_body.Data;
    if isKey(m_ui, "resend") || ~(isstruct(sct_old) && isfield(sct_old, "n") && isequal(rmfield(sct_old, "n"), sct_data))
        n_send = 0;
        if isstruct(sct_old) && isfield(sct_old, "n")
            n_send = sct_old.n + 1;
        end
        sct_data.n = n_send;
        h_body.Data = sct_data;
        if isKey(m_ui, "resend")
            remove(m_ui, "resend");
        end
    end
    % The pages as MATLAB tables, for an app or a test that reads the values shown
    h_body.UserData = struct("title", string({sct_model.pages.s_title}), "content", {{sct_model.pages.content}});
    h_body.HTMLEventReceivedFcn = @(src, e) body_event(src, e, obj, m_ui, a_target, s_expr, f_run);
    if l_newTarget
        notify(obj, "TargetChanged")
    end
end

function add_model(h_button, drawer, f_run, sv_arg)
% Ask for the options of an add_* method and run the code of the call.
    arguments (Input)
        h_button  % Add button.
        drawer    % The GUI.
        f_run     % run_code of the GUI.
        sv_arg    % Label, signature, object expression and kind ("" for an event).
    end
    arguments (Output)
    end
    s_code = DrawerOptionDialog.ask(ancestor(h_button, "figure"), sv_arg(2), Object=sv_arg(3), History=drawer.history);
    s_kind = sv_arg(4);
    if s_kind == ""
        s_kind = sv_arg(1);
    end
    if s_code ~= ""
        f_run("Add " + s_kind + " to " + string(drawer.a_target.s_tag), s_code);
    end
end

function body_event(h_body, e, drawer, m_ui, a_target, s_expr, f_run)
% Run an action of the body (model_body.html): choose a tab, edit a parameter, or remove events.
%
% - "select": the title of the tab chosen, kept for the next render.
% - "edit": the edited cell, written as code through the history (edit_parameter); the
%   body goes back to the stored values after an error.
% - "remove_event": the tags of the rows, removed with Scenario.remove_event after a
%   confirmation.
    arguments (Input)
        h_body    % uihtml of the body.
        e         % Event data: HTMLEventName and HTMLEventData.
        drawer    % The GUI.
        m_ui      % Components of the GUI.
        a_target  % Model shown.
        s_expr    % Expression of the model shown.
        f_run     % run_code of the GUI.
    end
    arguments (Output)
    end
    sct = e.HTMLEventData;
    switch string(e.HTMLEventName)
        case "select"
            m_ui("selected") = string(sct.title);
        case "edit"
            if s_expr == ""
                return
            end
            if edit_parameter(h_body, sct, a_target, m_ui("stale"), s_expr, f_run)
                m_ui("resend") = true;    % the stored values, also when they did not change
                drawer.render();
            end
        case "remove_event"
            sv_tag = unique(string(sct.tags), "stable");
            if s_expr == "" || isempty(sv_tag)
                return
            end
            s_arg = """" + sv_tag + """";
            if ~isscalar(sv_tag)
                s_arg = "[" + join(s_arg, ", ") + "]";
            end
            f_run("Remove " + join(sv_tag, ", "), s_expr + ".remove_event(" + s_arg + ");", ...
                "Confirm", "Remove the event " + join(sv_tag, ", ") + "?");
    end
end
