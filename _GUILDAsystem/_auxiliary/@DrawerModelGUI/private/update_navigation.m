function update_navigation(m_ui, drawer, a_children, s_expr, s_owner, f_run, m_cache)
% Child table: the children of the model, one kind at a time, in a compact searchable table.
%
% The kinds come in the order Bus, Branch, Component, LocalController, GlobalController,
% Scenario (then any other model), without the Parameter containers. A drop-down (Tag
% "kind") chooses the kind ("Bus (14)"), a search field (Tag "search") keeps the rows whose
% text contains it (any column, ignoring case), and the table (Tag "children") lists the
% children of that kind, one row each. A click on a row renders that child. The context menu
% of a row has "Open in new window" (a new uifigure with the same history) and "Remove",
% which runs the remove_* method of the parent (of the component for a local controller)
% after a confirmation. The components are made once (build_frame); a render writes their
% items, data and callbacks.
%
% The columns come from DrawerTagPicker.element_table of the network (the root variable of
% the history): Bus Tag, Type, Components; Branch Tag, From, To, Class; Component Tag,
% Class, Key; LocalController Tag, Role, Class; GlobalController Tag, Class, Units; Scenario
% Tag, Time, Description. Its rows are matched to the children by tag (local controllers
% within the rows of the component shown and of the controller shown as their Parent, since
% their tags are unique among siblings only); a model outside a network, or rows that do
% not match, get the columns Tag and Class instead.
%
% m_cache keeps:
% - the element table of each kind ("element_<kind>") until the history has a new entry or
%   the network changes, so that the children of every bus or component come from one table;
% - the table of each kind of the model shown ("table_<kind>", built when the kind is first
%   shown) and the kind chosen and the search text, for the next render of the same model
%   without a run in between (e.g. the app showing its model tab again).
    arguments (Input)
        m_ui        % Components of the GUI (build_frame). <@Type> containers.Map
        drawer      % DrawerModelGUI that renders the clicked model.
        a_children  % Children of the model shown, without Parameter containers (not empty). <@Type> cell
        s_expr      % Expression of the model shown, e.g. "net.a_Bus{1}" ("": outside the tree of the history, without actions). <@Type> string
        s_owner     % Expression of the component that holds a local controller shown ("" for none). <@Type> string
        f_run       % run_code of the GUI: @(s_label, s_code, Name, Value). <@Type> function_handle
        m_cache     % Cache of the tables (the drawer's, a containers.Map). <@Type> containers.Map
    end
    arguments (Output)
    end
    sv_kind = ["Bus","Branch","Component","LocalController","GlobalController","Scenario"];
    sv_child = repmat("Other", 1, numel(a_children));
    for s_kind = sv_kind
        sv_child(cellfun(@(c) isa(c, s_kind), a_children)) = s_kind;
    end
    sv_kind = [sv_kind, "Other"];
    sv_kind = sv_kind(ismember(sv_kind, sv_child));

    % Cache: the element tables until a run or another network, the tables of the model shown until another model
    a_target = drawer.a_target;
    n_entry = height(drawer.history.tab_entry);
    sv_key = string(keys(m_cache));
    if ~(isKey(m_cache, "n_entry") && m_cache("n_entry") == n_entry)    % a run since: everything is built again
        remove(m_cache, cellstr(sv_key(startsWith(sv_key, ["table_", "element_"]))));
        m_cache("n_entry") = n_entry;
    end
    if ~(isKey(m_cache, "target") && isequal(class(m_cache("target")), class(a_target)) ...
            && m_cache("target") == a_target)    % another model: its tables, kind and search are not reused
        sv_key = string(keys(m_cache));
        remove(m_cache, cellstr(sv_key(startsWith(sv_key, "table_") | ismember(sv_key, ["kind", "search"]))));
        m_cache("target") = a_target;
    end
    s_kind = sv_kind(1);
    if isKey(m_cache, "kind") && ismember(m_cache("kind"), sv_kind)
        s_kind = m_cache("kind");
    end
    s_search = "";
    if isKey(m_cache, "search")
        s_search = m_cache("search");
    end

    h_kind   = m_ui("kind");
    h_search = m_ui("search");
    sv_item = sv_kind + " (" + arrayfun(@(s) sum(sv_child == s), sv_kind) + ")";
    if ~isequal(string(h_kind.Items), sv_item) || ~isequal(string(h_kind.ItemsData), sv_kind)
        set(h_kind, "Items", sv_item, "ItemsData", sv_kind);
    end
    set_changed(h_kind, "Value", s_kind);
    set_changed(h_search, "Value", s_search);
    h_open = m_ui("open");
    h_open.MenuSelectedFcn = @(~, e) menu_row(e, m_ui, "open", drawer, s_expr, s_owner, f_run);
    % Remove, only for a model in the tree of the history (s_expr "": without actions)
    l_remove = isKey(m_ui, "remove") && isvalid(m_ui("remove"));
    if s_expr ~= "" && ~l_remove
        m_ui("remove") = uimenu(h_open.Parent, "Text", "Remove", "Separator", "on");
    elseif s_expr == "" && l_remove
        delete(m_ui("remove"));
        remove(m_ui, "remove");
    end
    if s_expr ~= ""
        h_remove = m_ui("remove");
        h_remove.MenuSelectedFcn = @(~, e) menu_row(e, m_ui, "remove", drawer, s_expr, s_owner, f_run);
    end

    f_show = @(s_text) show_rows(m_ui, string(h_kind.Value), string(s_text), a_children, sv_child, m_cache, drawer, s_expr);
    h_kind.ValueChangedFcn = @(~, ~) f_show(h_search.Value);
    h_search.ValueChangingFcn = @(~, e) f_show(e.Value);
    h_search.ValueChangedFcn = @(src, ~) f_show(src.Value);
    f_show(s_search);
end

function show_rows(m_ui, s_kind, s_search, a_children, sv_child, m_cache, drawer, s_expr)
% Fill the table with the children of the kind chosen that match the search text; build the table of the kind on its first show.
%
% Each set of columns (the kind and its column names) has a uitable of its own, made on its
% first use, in the same cell of the grid: the one of the kind shown is visible with the Tag
% "children" (m_ui "children"), the others are hidden without the Tag. A new set of columns
% costs the figure much more than new rows, so the columns of a table never change. The
% UserData of the table holds the children of the rows shown (cell, in row order).
    arguments (Input)
        m_ui        % Components of the GUI (build_frame). <@Type> containers.Map
        s_kind      % Kind chosen in the drop-down.
        s_search    % Text of the search field.
        a_children  % Children of the model shown (without Parameter containers).
        sv_child    % Kind of each child.
        m_cache     % Cache of the tables.
        drawer      % The GUI.
        s_expr      % Expression of the model shown.
    end
    arguments (Output)
    end
    s_search = strtrim(s_search);
    m_cache("kind") = s_kind;
    m_cache("search") = s_search;
    a_kind = a_children(sv_child == s_kind);
    if isKey(m_cache, "table_" + s_kind)
        tab = m_cache("table_" + s_kind);
    else
        sv_tag = string(cellfun(@(c) string(c.s_tag), a_kind, "UniformOutput", false));
        sv_tag = reshape(sv_tag, [], 1);
        tab = [];
        sct_column = struct("Bus", ["Tag", "Type", "Components"], "Branch", ["Tag", "From", "To", "Class"], ...
            "Component", ["Tag", "Class", "Key"], "LocalController", ["Tag", "Role", "Class"], ...
            "GlobalController", ["Tag", "Class", "Units"], "Scenario", ["Tag", "Time", "Description"]);
        try
            net = drawer.history.get_variable(extractBefore(s_expr + ".", "."));
            if isfield(sct_column, s_kind) && isa(net, "PowerNetwork") && isscalar(net) && isvalid(net)
                % The element table of the network, kept until a run (update_navigation) or another network;
                % made again once when the tags do not match (a change outside the history)
                s_key = "element_" + s_kind;
                l_fresh = ~(isKey(m_cache, s_key) && isKey(m_cache, "element_net") && m_cache("element_net") == net);
                if l_fresh
                    m_cache("element_net") = net;
                    m_cache(s_key) = DrawerTagPicker.element_table(net, s_kind);
                end
                tab_all = m_cache(s_key);
                if ~l_fresh && ~all(ismember(sv_tag, tab_all.Tag))
                    m_cache(s_key) = DrawerTagPicker.element_table(net, s_kind);
                    tab_all = m_cache(s_key);
                end
                if s_kind == "LocalController"    % tags are unique among siblings only: the rows of the component shown
                    c_index = regexp(s_expr, "^\w+\.a_Bus\{(\d+)\}\.a_Component\{(\d+)\}", "tokens", "once");
                    comp = net.a_Bus{str2double(c_index{1})}.a_Component{str2double(c_index{2})};
                    s_parent = "";
                    if isa(drawer.a_target, "LocalController")
                        s_parent = string(drawer.a_target.s_tag);
                    end
                    tab_all = tab_all(tab_all.Component == string(comp.s_tag) & tab_all.Parent == s_parent, :);
                end
                [l_found, iv_row] = ismember(sv_tag, tab_all.Tag);
                if all(l_found) && numel(unique(tab_all.Tag(iv_row))) == numel(sv_tag)
                    tab = tab_all(iv_row, sct_column.(s_kind));
                end
            end
        catch    % no network in the history: the plain columns
        end
        if isempty(tab)
            tab = table(sv_tag, reshape(string(cellfun(@class, a_kind, "UniformOutput", false)), [], 1), ...
                "VariableNames", ["Tag", "Class"]);
        end
        m_cache("table_" + s_kind) = tab; %#ok<NASGU> a handle (containers.Map)
    end
    l_row = true(height(tab), 1);
    if s_search ~= "" && height(tab) > 0
        sm_text = strings(height(tab), width(tab));
        for j = 1:width(tab)
            sm_text(:, j) = string(tab{:, j});
        end
        l_row = any(contains(sm_text, s_search, "IgnoreCase", true), 2);
    end
    tab = tab(l_row, :);
    % The table of these columns, made on first use; the others are hidden
    s_key = s_kind + "|" + join(string(tab.Properties.VariableNames), ",");
    sct_table = m_ui("child_tables");
    i_table = find(string({sct_table.s_key}) == s_key, 1);
    if isempty(i_table)
        sct_color = tools.gui_palette();
        h_table = uitable(m_ui("nav"), "Tag", "", "Visible", "off", "RowName", {}, "ColumnEditable", false, ...
            "ColumnWidth", "auto", "SelectionType", "row", "Multiselect", "off", "RowStriping", "on", ...
            "BackgroundColor", [sct_color.rv_card; sct_color.rv_stripe], "ForegroundColor", sct_color.rv_text, ...
            "ContextMenu", m_ui("menu"), "ClickedFcn", @(src, e) open_row(src, e, drawer));
        h_table.Layout.Row = 2;
        h_table.Layout.Column = [1 2];
        i_table = numel(sct_table) + 1;
        sct_table(i_table) = struct("s_key", s_key, "table", h_table);
        m_ui("child_tables") = sct_table;
    end
    h_table = sct_table(i_table).table;
    if isKey(m_ui, "children") && m_ui("children") ~= h_table
        set(m_ui("children"), "Visible", "off", "Tag", "");
    end
    set_changed(h_table, "Visible", "on", "Tag", "children");
    m_ui("children") = h_table;
    if ~isequal(h_table.Data, tab)
        h_table.Data = tab;
    end
    h_table.UserData = a_kind(l_row);
end

function open_row(h_table, e, drawer)
% Render the child of the clicked row (a left click on a row).
    arguments (Input)
        h_table  % Table of the children.
        e        % Event data of the click (InteractionInformation.Row).
        drawer   % The GUI.
    end
    arguments (Output)
    end
    i_row = [];
    try    % the row clicked (also a struct with the same fields)
        i_row = e.InteractionInformation.Row;
    catch    % not on a row
    end
    h_fig = ancestor(h_table, "figure");
    if isempty(i_row) || ~isscalar(i_row) || i_row < 1 || i_row > numel(h_table.UserData) ...
            || (isprop(h_fig, "SelectionType") && h_fig.SelectionType == "alt")
        return
    end
    drawer.render(h_table.UserData{i_row});
end

function menu_row(e, m_ui, s_action, drawer, s_expr, s_owner, f_run)
% Run a menu item on the child of the row: open it in a new window, or remove it after a confirmation.
    arguments (Input)
        e         % Event data of the menu (InteractionInformation.Row of the table).
        m_ui      % Components of the GUI, with the table of the children shown ("children").
        s_action  % "open" or "remove".
        drawer    % The GUI.
        s_expr    % Expression of the model shown (the parent).
        s_owner   % Expression of the component that holds a local controller.
        f_run     % run_code of the GUI.
    end
    arguments (Output)
    end
    h_table = m_ui("children");
    i_row = [];
    try    % the row right-clicked (also a struct with the same fields)
        i_row = e.InteractionInformation.Row;
    catch    % no row: the selected one
    end
    if isempty(i_row)
        i_row = h_table.Selection;
    end
    if isempty(i_row) || i_row(1) < 1 || i_row(1) > numel(h_table.UserData)
        return
    end
    a_model = h_table.UserData{i_row(1)};
    if s_action == "open"
        a_model.launch_gui(History=drawer.history);
        return
    end
    s_tag = string(a_model.s_tag);
    s_arg = """" + replace(s_tag, """", """""") + """";
    s_question = "Remove " + class(a_model) + " " + s_tag + "?";
    if isa(a_model, "Bus")
        s_code = s_expr + ".remove_bus(" + s_arg + ");";
    elseif isa(a_model, "Branch")
        s_code = s_expr + ".remove_branch(" + s_arg + ");";
    elseif isa(a_model, "GlobalController")
        s_code = s_expr + ".remove_global_controller(" + s_arg + ");";
    elseif isa(a_model, "Scenario")
        s_code = s_expr + ".remove_scenario(" + s_arg + ");";
    elseif isa(a_model, "Component")
        s_code = s_expr + ".remove_component(" + s_arg + ");";
    elseif isa(a_model, "LocalController")
        if s_owner == ""
            s_owner = s_expr;    % the children of a component
        end
        if isempty(a_model.a_LocalController)
            s_code = s_owner + ".remove_local_controller(" + s_arg + ");";
        else    % with the controller nested in it (the PSS under an AVR)
            s_code = s_owner + ".remove_local_controller(" + s_arg + ", RemoveNested=true);";
            s_question = "Remove " + class(a_model) + " " + s_tag + " and the controller nested in it?";
        end
    else
        return
    end
    f_run("Remove " + s_tag, s_code, "Confirm", s_question);
end
