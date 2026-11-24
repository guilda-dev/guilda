function form_event(obj, s_event, k)
% Handle an event of the form: a changed field, a reset, a Select... button or a group header.
%
% - "change": a field changed (k = 0 when the form is drawn).
% - "reset": field k goes back to its default.
% - "select": field k opens DrawerTagPicker.pick with the table of its elements or keys, built
%   now from the network of the call, or (s_pick "table") the table that its gui_forms.json
%   expression gives on the object now, and takes the tags chosen (nothing on cancel). An
%   expression that fails or gives no rows leaves the field as it is and says so (an alert,
%   a warning in a hidden window).
% - "toggle": group k opens or closes; its fields are drawn when it opens first.
%
% A change, reset or selection of field k first evaluates again the choices and defaults of
% the fields that refer to it (refresh_depend: e.g. the input names of the unit of
% Scenario.add_input, or the Time of add_scenario from its From). Every event then applies the conditions of gui_forms.json "visible" (a hidden field is left
% out of the call), lays out the rows (the shown fields in order; the hidden ones and the
% fields of a closed group in one row of height 0), calls get_code (highlight, reset buttons and message) and passes the height
% of the form to f_resize (the dialog of ask).
    arguments (Input)
        obj                   % The form.
        s_event (1,1) string  % "change", "reset", "select" or "toggle".
        k (1,1) double        % Index of the field (of the group for "toggle"; 0 for none).
    end
    arguments (Output)
    end
    if ~isvalid(obj.h_grid)
        return
    end
    s_note = "";    % a message shown after get_code (a shared tag)
    switch s_event
        case "toggle"
            obj.sct_group(k).l_open = ~obj.sct_group(k).l_open;
            for i = obj.sct_group(k).iv_field
                if ~obj.sct_field(i).l_built
                    obj.draw_field(i);
                end
            end
        case "reset"
            sct = obj.sct_field(k);
            switch sct.widget
                case "tags"
                    sct.h.Value = cellstr(sct.baseline);
                case {"choice", "flag"}
                    sct.h.Value = char(sct.baseline);
                case "logical"
                    sct.h.Value = sct.baseline;
                otherwise
                    sct.h.Value = char(sct.s_base);
            end
        case "select"
            sct = obj.sct_field(k);
            % The current tags, the table and the column returned
            switch sct.widget
                case "choice"
                    sv_now = string(sct.h.Value);
                case "expression"
                    [value, l_value] = eval_text(string(sct.h.Value));
                    sv_now = strings(1, 0);
                    if l_value && (isstring(value) || iscellstr(value) || ischar(value))
                        sv_now = reshape(string(value), 1, []);
                    end
                otherwise
                    sv_now = parse_tags(string(sct.h.Value));
            end
            s_column = "Tag";
            if sct.s_pick == "key"
                tab = DrawerTagPicker.key_table(sct.s_category);
                s_column = "Key";
                s_title = "Select " + sct.s_label + " (" + sct.s_category + " keys)";
            elseif sct.s_pick == "table"
                s_title = "Select " + sct.s_label;
                [tab, l_tab, s_reason] = eval_text(sct.s_table, obj.a_object);
                if ~l_tab && s_reason == ""
                    s_reason = "no expression";
                elseif l_tab && (~istable(tab) || ~ismember("Tag", string(tab.Properties.VariableNames)))
                    s_reason = "no table with a Tag column";
                elseif l_tab && height(tab) == 0
                    s_reason = "the table has no rows";
                end
                if s_reason ~= ""
                    s_alert = string(msg("GUILDA:DrawerOptionDialog:NoPickTable", sct.name, s_reason));
                    h_fig = ancestor(obj.h_grid, "figure");
                    if h_fig.Visible == "on"
                        uialert(h_fig, s_alert, s_title, "Icon", "warning");
                    else
                        warning("GUILDA:DrawerOptionDialog:NoPickTable", "%s", s_alert);
                    end
                    return    % the field stays as it is
                end
            else
                % The elements of each kind that the choices list (all of them for gui_forms.json
                % "pick"); a local controller of a component call only of that component
                c_tab = {};
                sv_found = strings(1, 0);
                for s_kind = sct.sv_kind
                    tab_kind = DrawerTagPicker.element_table(obj.a_network, s_kind);
                    lv_keep = true(height(tab_kind), 1);
                    if ~isempty(sct.items)
                        lv_keep = ismember(tab_kind.Tag, sct.items);
                    end
                    if s_kind == "LocalController" && isa(obj.a_object, "Component") && isscalar(obj.a_object)
                        lv_keep = lv_keep & tab_kind.Component == obj.a_object.s_tag;
                    end
                    if any(lv_keep) || isscalar(sct.sv_kind)
                        c_tab{end+1} = tab_kind(lv_keep, :);    %#ok<AGROW>
                        sv_found(end+1) = s_kind;               %#ok<AGROW>
                    end
                end
                if isscalar(c_tab)
                    tab = c_tab{1};
                else    % several kinds: Tag, Kind, Bus, Detail, Class (one table at the end)
                    [Tag, Kind, Bus, Detail, Class] = deal(strings(0, 1));
                    for i = 1:numel(c_tab)
                        t = c_tab{i};
                        n = height(t);
                        sv_bus = strings(n, 1);
                        sv_detail = strings(n, 1);
                        sv_class = strings(n, 1);
                        switch sv_found(i)
                            case "Bus"
                                sv_bus = t.Tag;
                                sv_detail = t.Type + ", " + t.Components + " components";
                            case "Branch"
                                sv_bus = t.From + " - " + t.To;
                                sv_class = t.Class;
                            case "Component"
                                sv_bus = t.Bus;
                                sv_detail = "position " + t.Position;
                                sv_class = t.Class;
                            case "LocalController"
                                sv_bus = t.Bus;
                                sv_detail = t.Role + " of " + t.Component;
                                sv_class = t.Class;
                            case "GlobalController"
                                sv_detail = t.Units + " units";
                                sv_class = t.Class;
                            case "Scenario"
                                sv_detail = t.Time;
                        end
                        Tag    = [Tag; t.Tag];                         %#ok<AGROW> a few kinds
                        Kind   = [Kind; repmat(sv_found(i), n, 1)];    %#ok<AGROW>
                        Bus    = [Bus; sv_bus];                        %#ok<AGROW>
                        Detail = [Detail; sv_detail];                  %#ok<AGROW>
                        Class  = [Class; sv_class];                    %#ok<AGROW>
                    end
                    tab = table(Tag, Kind, Bus, Detail, Class);
                end
                s_title = "Select " + sct.s_label;
            end
            sv_pick = DrawerTagPicker.pick(ancestor(obj.h_grid, "figure"), tab, Multiple=sct.l_multiple, ...
                Selected=sv_now, Title=s_title, Column=s_column);
            if isempty(sv_pick) || ~isvalid(obj.h_grid)
                return    % canceled: nothing changes
            end
            switch sct.widget
                case "choice"
                    if ~ismember(sv_pick(1), sct.items)
                        obj.sct_field(k).items(end+1) = sv_pick(1);
                        sct.h.Items = cellstr(obj.sct_field(k).items);
                    end
                    sct.h.Value = char(sv_pick(1));
                case "expression"
                    sct.h.Value = char(code_strings(sv_pick));
                otherwise
                    sct.h.Value = char(tags_text(sv_pick));
            end
            % A tag that several elements share (a trip names its units by tag only)
            for s_tag = sv_pick(sct.s_pick == "element")
                iv_same = find(tab.Tag == s_tag);
                if numel(iv_same) > 1
                    s_where = s_tag;
                    if ismember("Component", string(tab.Properties.VariableNames))
                        s_where = join(tab.Component(iv_same), ", ");
                    elseif ismember("Detail", string(tab.Properties.VariableNames))
                        s_where = join(tab.Detail(iv_same), ", ");
                    end
                    s_note = string(msg("GUILDA:DrawerOptionDialog:SharedTag", sct.name, s_tag, numel(iv_same), s_where));
                    break
                end
            end
    end

    % Fields whose choices or default refer to the field changed: evaluated again
    if k > 0 && s_event ~= "toggle"
        obj.sct_field = refresh_depend(obj.sct_field, obj.sct_field(k).name, obj.a_history, obj.a_object);
    end

    % Visibility: a field named by a condition is shown only while one of its "when" holds
    sv_name = string({obj.sct_field.name});
    lv_visible = true(1, numel(obj.sct_field));
    for i = 1:numel(obj.c_visible)
        sct_rule = obj.c_visible{i};
        l_show = false;
        for j = 1:numel(sct_rule.when)
            sct_when = sct_rule.when{j};
            l_all = true;
            for s_other = reshape(string(fieldnames(sct_when)), 1, [])
                i_other = find(sv_name == s_other, 1);
                if isempty(i_other)
                    continue
                end
                % The value of the other field as text ("NaN" for "auto" or the word for NaN, the value for "none")
                sct = obj.sct_field(i_other);
                if ~sct.l_built
                    switch sct.widget
                        case {"choice", "flag"}
                            s_value = string(sct.baseline);
                        case "logical"
                            s_value = string(mat2str(sct.baseline));
                        case "tags"
                            s_value = join([sct.baseline(:)', ""], " ");
                        otherwise
                            s_value = sct.s_base;
                    end
                elseif sct.widget == "logical"
                    s_value = string(mat2str(logical(sct.h.Value)));
                elseif sct.widget == "tags"
                    s_value = join([string(sct.h.Value), ""], " ");
                else
                    s_value = strtrim(string(sct.h.Value));
                end
                if sct.widget == "number" && s_value == sct.s_auto && ~isempty(sct.r_auto)
                    s_value = "NaN";
                elseif sct.widget == "number" && s_value == "none" && ~isempty(sct.r_none)
                    s_value = string(mat2str(sct.r_none));
                end
                cond = sct_when.(s_other);
                l_not = isstruct(cond);
                if l_not
                    cond = cond.not;
                end
                sv_cond = reshape(string(cond), 1, []);
                l_number = @(s) ~isnan(str2double(s)) || strcmpi(s, "nan");
                l_match = any(sv_cond == s_value);
                if ~l_match && l_number(s_value)
                    l_match = any(arrayfun(@(c) l_number(c) && isequaln(str2double(c), str2double(s_value)), sv_cond));
                end
                l_all = l_all && xor(l_match, l_not);
            end
            l_show = l_show || l_all;
        end
        lv_visible(ismember(sv_name, sct_rule.names)) = lv_visible(ismember(sv_name, sct_rule.names)) & l_show;
    end

    % Rows: the title, then the shown group headers and fields in their order, then one row of
    % height 0 that parks the hidden ones (fields hidden by "visible", the fields of a closed
    % group and the headers of a group without visible fields), then the message
    sv_group = string({obj.sct_group.name});
    c_height = {22};
    iv_row_field = zeros(1, numel(obj.sct_field));
    iv_row_group = zeros(1, numel(obj.sct_group));
    for i = 1:numel(obj.sct_field)
        sct = obj.sct_field(i);
        g = find(sv_group == sct.s_group, 1);
        if ~isempty(g) && iv_row_group(g) == 0 && obj.sct_group(g).iv_field(1) == i    % the header before its first field
            iv_row_group(g) = -1;
            if any(lv_visible(obj.sct_group(g).iv_field))
                c_height{end+1} = 24;    %#ok<AGROW>
                iv_row_group(g) = numel(c_height);
            end
        end
        l_shown = lv_visible(i) && (isempty(g) || obj.sct_group(g).l_open);
        obj.sct_field(i).l_visible = lv_visible(i);
        obj.sct_field(i).l_shown = l_shown;
        if l_shown
            c_height{end+1} = 22 + 44 * (sct.widget == "tags");    %#ok<AGROW> a list shows three tags
            iv_row_field(i) = numel(c_height);
        end
    end
    i_park = numel(c_height) + 1;
    iv_row_field(iv_row_field == 0) = i_park;
    iv_row_group(iv_row_group <= 0) = i_park;
    c_old = obj.h_grid.RowHeight;
    if numel(c_old) < i_park + 1    % room for every row before the components move
        obj.h_grid.RowHeight = [c_old, repmat({0}, 1, i_park + 1 - numel(c_old))];
    end
    for i = 1:numel(obj.sct_field)
        sct = obj.sct_field(i);
        obj.sct_field(i).i_row = iv_row_field(i);
        if sct.l_built
            a_h = [sct.h_label, sct.h, sct.h_extra, sct.h_reset];
            for h = a_h
                if h.Layout.Row ~= iv_row_field(i)
                    h.Layout.Row = iv_row_field(i);
                end
            end
            for c_h = {sct.h_label, sct.h, sct.h_extra}
                if ~isempty(c_h{1}) && c_h{1}.Visible ~= sct.l_shown
                    c_h{1}.Visible = sct.l_shown;
                end
            end
        end
    end
    for g = 1:numel(obj.sct_group)
        if obj.sct_group(g).h.Layout.Row ~= iv_row_group(g)
            obj.sct_group(g).h.Layout.Row = iv_row_group(g);
        end
        if obj.sct_group(g).h.Visible ~= (iv_row_group(g) ~= i_park)
            obj.sct_group(g).h.Visible = iv_row_group(g) ~= i_park;
        end
    end
    if obj.h_message.Layout.Row ~= i_park + 1
        obj.h_message.Layout.Row = i_park + 1;
    end
    c_height = [c_height, {0}, {"fit"}];
    if ~isequal(obj.h_grid.RowHeight, c_height)
        obj.h_grid.RowHeight = c_height;
    end
    obj.get_code();
    if s_note ~= "" && obj.h_message.Text == ""
        obj.h_message.Text = s_note;
    end
    if k == 0 && s_event == "change"    % the form is drawn: no message yet for an empty required input
        obj.h_message.Text = "";
        for i = 1:numel(obj.sct_field)
            if obj.sct_field(i).l_built && isprop(obj.sct_field(i).h, "BackgroundColor") ...
                    && isequal(obj.sct_field(i).h.BackgroundColor, tools.gui_palette().rv_stale_back)
                obj.sct_field(i).h.BackgroundColor = tools.gui_palette().rv_card;
            end
        end
    end
    % The message row takes no height while it is empty
    if obj.h_message.Text == ""
        c_height{end} = 0;
    end
    if ~isequal(obj.h_grid.RowHeight, c_height)
        obj.h_grid.RowHeight = c_height;
    end
    if ~isempty(obj.f_resize)
        rv_numeric = cellfun(@(c) sum(double(c(isnumeric(c)))), c_height);    % "fit" rows: 0
        n_message = 0;
        if obj.h_message.Text ~= ""
            n_message = 36;
        end
        obj.f_resize(sum(rv_numeric) + n_message + obj.h_grid.RowSpacing * (numel(c_height) - 1) ...
            + sum(obj.h_grid.Padding([2 4])));
    end
end
