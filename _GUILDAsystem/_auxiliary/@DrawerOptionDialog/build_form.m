function build_form(obj, h_container, sv_exclude, history, sct_value)
% Read the signature and gui_forms.json, set up one field per input and draw the form.
%
% With a history, the object of the call is evaluated in its workspace (the root variable of
% the Object expression), and the choices and defaults are evaluated on it. The fields of
% sct_value (code text by input name) are shown instead of the defaults; the baseline of
% get_code stays the default. The rows are: the title, the required and positional inputs,
% the main options, then a header row and the rows of each group. The fields of the main
% options are drawn here; those of a group when it is opened first (draw_field).
%
% A field (sct_field) holds: name, kind (required, ordered, namevalue), widget (tags,
% tagtext, choice, flag, logical, number, string, expression), baseline (the default as a
% value of the widget), shown (the value shown first), s_base (the text of the default in a
% text field), s_default, s_purpose, s_label, s_unit, s_hint (a default in words), items,
% s_pick ("", "element", "key" or "table"), sv_kind (element kinds), s_category (key category),
% s_table (the table expression of gui_forms.json "pick", evaluated by form_event),
% l_multiple, r_auto, s_auto (the word for r_auto), r_none, s_note (a hint of gui_forms.json), s_group, i_row, the handles (h, h_label, h_extra, h_reset),
% l_built, l_visible, l_shown and l_changed, and for choices or a default that refer to other
% inputs (refer_args, refresh_depend): s_choices and sv_default (the expressions with
% arg.<name>), sv_depend (the inputs referred to) and s_wait ("Select unit first").
    arguments (Input)
        obj                       % The form.
        h_container               % uifigure, uipanel, uitab or uigridlayout of a uifigure.
        sv_exclude (1,:) string   % Inputs left out of the form.
        history                   % HistoryGUILDA that holds the root variable of the Object expression, or [].
        sct_value (1,1) struct    % Initial values by input name, as MATLAB code text.
    end
    arguments (Output)
    end
    % The signature: the file of _GUILDAsystem first, then that of _GUILDAsystem/_auxiliary
    % (update_keymap writes the _auxiliary classes, such as the results, to both)
    s_key = replace(obj.s_signature, ".", "_");    % jsondecode makes "Bus.add_component" Bus_add_component
    c_input = [];
    for s_dir = ["", "_auxiliary"]
        s_file = fullfile(GUILDA.pwd(), "_GUILDAsystem", s_dir, "resources", "functionSignatures.json");
        if isempty(c_input) && isfile(s_file)
            sct_json = read_cached(s_file);
            if isfield(sct_json, s_key)
                c_input = sct_json.(s_key).inputs;
            end
        end
    end
    if isempty(c_input)
        error(msg("GUILDA:DrawerOptionDialog:UnknownSignature", obj.s_signature))
    end
    if isstruct(c_input)
        c_input = num2cell(c_input);
    end
    % The layout: the entry of the signature in gui_forms.json, else the fallback groups
    s_file = fullfile(GUILDA.pwd(), "_GUILDAsystem", "resources", "gui_forms.json");
    sct_forms = struct();
    if isfile(s_file)
        sct_forms = read_cached(s_file);
    end
    sct_spec = struct();
    l_spec = isfield(sct_forms, s_key);
    if l_spec
        sct_spec = sct_forms.(s_key);
        if isfield(sct_spec, "same")    % the layout of another signature
            sct_spec = sct_forms.(replace(string(sct_spec.same), ".", "_"));
        end
    elseif isfield(sct_forms, "x_fallback")
        sct_spec = sct_forms.x_fallback;
    end
    sv_main = strings(1, 0);
    if isfield(sct_spec, "main") && ~isempty(sct_spec.main)
        sv_main = reshape(string(sct_spec.main), 1, []);
    end
    c_group = {};
    if isfield(sct_spec, "groups") && ~isempty(sct_spec.groups)
        c_group = sct_spec.groups;
        if isstruct(c_group)
            c_group = num2cell(c_group);
        end
    end
    sct_label = struct();
    if isfield(sct_spec, "labels")
        sct_label = sct_spec.labels;
    end
    sct_pick = struct();    % input name -> element kinds, or {"table": expression on obj}
    if isfield(sct_spec, "pick")
        sct_pick = sct_spec.pick;
    end
    obj.c_visible = {};
    if isfield(sct_spec, "visible") && ~isempty(sct_spec.visible)
        obj.c_visible = sct_spec.visible;
        if isstruct(obj.c_visible)
            obj.c_visible = num2cell(obj.c_visible);
        end
        for i = 1:numel(obj.c_visible)
            c_when = obj.c_visible{i}.when;
            if isstruct(c_when)
                c_when = num2cell(c_when);
            end
            obj.c_visible{i}.when  = c_when;
            obj.c_visible{i}.names = reshape(string(obj.c_visible{i}.names), 1, []);
        end
    end
    % Defaults of options built from the properties of a class (opt.?GraphNetDiagram): the
    % default text and the comment of each property in the classdef file
    sct_property = struct();
    if isfield(sct_spec, "propertyDefaults")
        s_file = string(which(string(sct_spec.propertyDefaults)));
        if s_file ~= "" && isfile(s_file)
            c_tok = regexp(read_cached(s_file), ...
                "^[ \t]*(\w+)[ \t]*(?:\([^)\n]*\))?[ \t]*(?:[\w.]+)?[ \t]*(?:\{[^}\n]*\})?[ \t]*=[ \t]*(""(?:[^""\n]|"""")*""|[^%""\n]*?)[ \t]*%[ \t]*([^\n]*)$", ...
                "tokens", "lineanchors");
            for i = 1:numel(c_tok)
                sct_property.(c_tok{i}{1}) = struct("s_default", string(strtrim(c_tok{i}{2})), "s_comment", string(strtrim(c_tok{i}{3})));
            end
        end
    end

    % The object of the call, from the root variable of the Object expression ([] without one),
    % and the network of its elements for the pickers
    obj.a_object  = [];
    obj.a_network = [];
    obj.a_history = history;
    if ~isempty(history)
        s_root = string(regexp(obj.s_object, "^[A-Za-z]\w*", "match", "once"));
        try
            root = history.get_variable(s_root);
            [obj.a_object, l_object] = eval_text("obj" + extractAfter(obj.s_object, strlength(s_root)), root);
            if ~l_object
                obj.a_object = [];
            end
            if isa(root, "PowerNetwork") && isscalar(root)
                obj.a_network = root;
            end
        catch    % no such variable: the form is made without the object
        end
        a_up = obj.a_object;    % else up from the object: a bus, component, controller, scenario or event
        for i = 1:6
            if ~isempty(obj.a_network) || isempty(a_up) || ~isscalar(a_up) || ~isobject(a_up)
                break
            elseif isa(a_up, "PowerNetwork")
                obj.a_network = a_up;
                break
            end
            s_prop = ["a_PowerNetwork", "a_Scenario", "a_Bus", "a_Component"];
            s_prop = s_prop(arrayfun(@(s) isprop(a_up, s), s_prop));
            if isempty(s_prop)
                break
            end
            a_up = a_up.(s_prop(1));
        end
    end

    sv_numeric = ["double", "single", "int8", "int16", "int32", "int64", "uint8", "uint16", "uint32", "uint64"];
    sct_field = struct("name", {}, "kind", {}, "widget", {}, "baseline", {}, "shown", {}, "s_base", {}, ...
        "s_default", {}, "s_purpose", {}, "s_label", {}, "s_unit", {}, "s_hint", {}, "items", {}, ...
        "s_pick", {}, "sv_kind", {}, "s_category", {}, "s_table", {}, "l_multiple", {}, "r_auto", {}, "s_auto", {}, "r_none", {}, ...
        "s_note", {}, "s_group", {}, "rv_order", {}, "i_row", {}, "h", {}, "h_label", {}, "h_extra", {}, "h_reset", {}, ...
        "l_built", {}, "l_visible", {}, "l_shown", {}, "l_changed", {}, "s_choices", {}, "sv_default", {}, "sv_depend", {}, "s_wait", {});
    % The inputs a choices or default expression may refer to: their names and their defaults
    % (refer_args), and those referred to before they are made (evaluated after the loop)
    sv_arg = strings(1, 0);
    sv_arg_default = strings(1, 0);
    for k = 2:numel(c_input)
        if ~ismember(string(c_input{k}.name), sv_exclude)
            sv_arg(end+1) = string(c_input{k}.name);    %#ok<AGROW>
            s_arg = strings(1, 0);
            if isfield(c_input{k}, "purpose")
                s_arg = string(regexp(string(c_input{k}.purpose), "Default: (.*)\.$", "tokens", "once"));
            end
            sv_arg_default(end+1) = join([s_arg, ""], "");    %#ok<AGROW> "" for none
        end
    end
    sv_late = strings(1, 0);
    for k = 2:numel(c_input)    % the first input is obj
        sct_in = c_input{k};
        s_name = string(sct_in.name);
        if ismember(s_name, sv_exclude)
            continue
        end
        s_purpose = "";
        if isfield(sct_in, "purpose")
            s_purpose = string(sct_in.purpose);
        end
        % Types: the class and the choices expression, from a list or alternatives of lists
        sv_type = strings(0, 1);
        if isfield(sct_in, "type")
            c_stack = {sct_in.type};
            while ~isempty(c_stack)
                if iscell(c_stack{1})
                    c_stack = [reshape(c_stack{1}, 1, []), c_stack(2:end)];
                else
                    sv_type = [sv_type; string(c_stack{1})];    %#ok<AGROW>
                    c_stack(1) = [];
                end
            end
        end
        l_scalar  = any(sv_type == "scalar");    % (1,1): one value
        s_choices = sv_type(startsWith(sv_type, "choices="));
        s_class   = sv_type(~startsWith(sv_type, "choices=") & sv_type ~= "scalar");
        s_class(end+1) = "";    %#ok<AGROW> the first class, or "" for none
        s_class   = s_class(1);
        s_default = string(regexp(s_purpose, "Default: (.*)\.$", "tokens", "once"));
        if isempty(s_default)
            s_default = "";
        end
        if s_default == "" && isfield(sct_property, s_name)    % a property default of the class
            s_default = sct_property.(s_name).s_default;
            if s_purpose == ""
                s_purpose = sct_property.(s_name).s_comment + " Default: " + s_default + ".";
            end
        end
        % A default of alternatives of which one refers to another input ("From.Time, else
        % [0, 10]"): the first that evaluates for the current values (form_event again when
        % such an input changes); any other default is evaluated on the object only
        sv_alt = strings(1, 0);
        sv_depend = strings(1, 0);
        if contains(s_default, ", else ")
            sv_alt = reshape(strtrim(split(s_default, ", else ")), 1, []);
            for i = 1:numel(sv_alt)
                [sv_alt(i), sv_ref] = refer_args(sv_alt(i), sv_arg, sv_arg_default, s_name);
                sv_depend = union(sv_depend, sv_ref, "stable");
            end
        end
        sv_late = union(sv_late, setdiff(sv_depend, string({sct_field.name})), "stable");
        if ~isempty(sv_depend)
            [default, l_default] = eval_depend(sv_alt, sv_depend, sct_field, history, obj.a_object);
        else
            sv_alt = strings(1, 0);
            [default, l_default] = eval_text(s_default, obj.a_object);
        end

        sct = struct("name", s_name, "kind", string(sct_in.kind), "widget", "", "baseline", [], "shown", [], ...
            "s_base", "", "s_default", s_default, "s_purpose", s_purpose, "s_label", s_name, "s_unit", "", "s_hint", "", ...
            "items", strings(0, 1), "s_pick", "", "sv_kind", strings(1, 0), "s_category", "", "s_table", "", "l_multiple", ~l_scalar, ...
            "r_auto", [], "s_auto", "auto", "r_none", [], "s_note", "", "s_group", "", "rv_order", [0 0 0], "i_row", 0, "h", [], "h_label", [], ...
            "h_extra", [], "h_reset", [], "l_built", false, "l_visible", true, "l_shown", false, "l_changed", false, ...
            "s_choices", "", "sv_default", sv_alt, "sv_depend", sv_depend, "s_wait", "");
        % Label, unit ("[pu] ..." in the purpose) and the hint of a default in words
        sct.s_unit = string(regexp(s_purpose, "^\[([^\]]+)\]", "tokens", "once"));
        if isempty(sct.s_unit)
            sct.s_unit = "";
        end
        if isfield(sct_label, s_name)
            if isfield(sct_label.(s_name), "label")
                sct.s_label = string(sct_label.(s_name).label);
            end
            if isfield(sct_label.(s_name), "unit")
                sct.s_unit = string(sct_label.(s_name).unit);
            end
        end
        if s_default ~= "" && ~l_default
            sct.s_hint = s_default;
        end
        % Special numbers: "none" for the value the purpose calls none, "auto" for NaN otherwise
        s_none = string(regexp(s_purpose, "(-?(?:Inf|NaN))\s*(?::|=|for)\s*none", "tokens", "once", "ignorecase"));
        if ~isempty(s_none)
            sct.r_none = str2double(s_none);
        end
        if ~isequaln(sct.r_none, NaN) && contains(extractBefore(s_purpose + "Default:", "Default:"), "NaN", "IgnoreCase", true)
            sct.r_auto = NaN;
        end
        % gui_forms.json "labels": the word shown for NaN ("nan", e.g. "bus" for the Point of a
        % bus fault) and a short hint beside the field ("hint")
        if isfield(sct_label, s_name) && isfield(sct_label.(s_name), "nan")
            sct.r_auto = NaN;
            sct.s_auto = string(sct_label.(s_name).nan);
            if isequaln(sct.r_none, NaN)
                sct.r_none = [];
            end
        end
        if isfield(sct_label, s_name) && isfield(sct_label.(s_name), "hint")
            sct.s_note = string(sct_label.(s_name).hint);
        end

        if ~isempty(s_choices)
            s_items = extractAfter(s_choices(1), "choices=");
            % Choices that refer to other inputs (`get_element(unit)`, or `obj.s_unit`, the
            % default of Unit): evaluated for their current values, again by form_event when one
            % changes; while one is empty, no items and the hint "Select unit first"
            [s_depend, sv_ref] = refer_args(s_items, sv_arg, sv_arg_default, s_name);
            if ~isempty(sv_ref)
                sct.s_choices = s_depend;
                sct.sv_depend = union(sct.sv_depend, sv_ref, "stable");
                sv_late = union(sv_late, setdiff(sv_ref, string({sct_field.name})), "stable");
                [c_items, l_items, sct.s_wait] = eval_depend(s_depend, sv_ref, sct_field, history, obj.a_object);
                if ~l_items && (~isempty(obj.a_object) || isempty(regexp(s_items, "\<obj\>", "once")))
                    c_items = strings(0, 1);
                    l_items = true;
                elseif ~l_items    % no object to evaluate on (no History): a text field, nothing to rebuild
                    sct.s_choices = "";
                    sct.s_wait    = "";
                    sct.sv_depend = sv_depend;
                end
                if l_items
                    c_items = unique(reshape(string(c_items), [], 1), "stable");
                end
            else
                [c_items, l_items] = eval_text(s_items, obj.a_object);
            end
            if l_items
                sct.widget = "choice";
                sct.items  = reshape(string(c_items), [], 1);
                % tags of the object, or a default of several values: one or several
                if ~isempty(regexp(s_items, "\<obj\>", "once")) ...
                        || (l_default && (isstring(default) || iscellstr(default)) && numel(default) > 1)
                    sct.widget = "tags";
                    sct.items  = unique(sct.items(sct.items ~= ""), "stable");
                    if l_scalar    % one tag: a dropdown
                        sct.widget = "choice";
                    end
                end
            end
            % A picker: model keys, a table of gui_forms.json "pick" (evaluated on the object
            % when Select... is pressed), or the elements of the network
            l_table = isfield(sct_pick, s_name) && isstruct(sct_pick.(s_name)) && isfield(sct_pick.(s_name), "table");
            s_category = string(regexp(s_items, "GUILDA\.keymap\(""(\w+)""\)", "tokens", "once"));
            % (a list, not a step of a path: obj.a_Scenario.a_PowerNetwork is not a list of scenarios)
            c_kind = regexp(s_items, "\<a_(Bus|Branch|Component|LocalController|GlobalController|Scenario)\>(?!\.)", "tokens");
            if ~isempty(s_category) && sct.widget == "choice"
                sct.s_pick = "key";
                sct.s_category = s_category;
                sct.l_multiple = false;
            elseif l_table && ismember(sct.widget, ["tags", "choice"])
                sct.s_pick  = "table";
                sct.s_table = string(sct_pick.(s_name).table);
                if sct.widget == "tags"
                    sct.widget = "tagtext";
                end
            elseif ~isempty(c_kind) && ~isempty(obj.a_network) && ismember(sct.widget, ["tags", "choice"])
                sct.s_pick  = "element";
                sct.sv_kind = unique(string(cellfun(@(c) c{1}, c_kind, "UniformOutput", false)), "stable");
                if sct.widget == "tags"
                    sct.widget = "tagtext";
                end
            end
        end
        if sct.widget == ""
            if s_class == "logical" && s_default ~= "" && ~l_default
                sct.widget = "flag";    % a default in words: "" (left out), true or false
            elseif s_class == "logical"
                sct.widget = "logical";
            elseif ismember(s_class, sv_numeric)
                sct.widget = "number";
            elseif ismember(s_class, ["string", "char"]) && (~l_default ...
                    || ((isstring(default) || ischar(default)) && numel(string(default)) <= 1))    % one text, or none (strings(1,0))
                sct.widget = "string";
            else
                sct.widget = "expression";
            end
            if isfield(sct_pick, s_name) && ~isstruct(sct_pick.(s_name)) && ~isempty(obj.a_network) && ismember(sct.widget, ["string", "expression"])
                sct.s_pick  = "element";    % an input without choices that takes tags (gui_forms.json "pick")
                sct.sv_kind = reshape(string(sct_pick.(s_name)), 1, []);
            end
        end
        % The default as a value of the widget, and the text of the default in a text field
        sct = field_baseline(sct, default, l_default);
        % The value shown first: the default, or the code text of Value (written as it is in a
        % number or expression field, evaluated for the others)
        sct.shown = sct.baseline;
        if ismember(sct.widget, ["number", "string", "expression", "tagtext"])
            sct.shown = sct.s_base;
        end
        if isfield(sct_value, sct.name)
            s_given = strtrim(string(sct_value.(sct.name)));
            [given, l_given] = eval_text(s_given, obj.a_object);
            switch sct.widget
                case {"number", "expression"}
                    l_given = isscalar(s_given) && ~ismissing(s_given);
                    sct.shown = s_given;
                case {"tags", "tagtext"}
                    l_given = l_given && (isstring(given) || ischar(given) || iscellstr(given));
                    if l_given && sct.widget == "tagtext"
                        sct.shown = tags_text(string(given));
                    elseif l_given    % a value the list does not have is added to it
                        sct.shown = unique(string(given(:)), "stable");
                        sct.items = [sct.items; setdiff(sct.shown, sct.items, "stable")];
                    end
                case "choice"
                    l_given = l_given && (isstring(given) || ischar(given)) && isscalar(string(given));
                    if l_given
                        sct.shown = string(given);
                        if ~ismember(sct.shown, sct.items)    % a value the choices do not list
                            sct.items(end+1) = sct.shown;
                        end
                    end
                case "logical"
                    l_given = l_given && isscalar(given) && (islogical(given) || isnumeric(given));
                    if l_given
                        sct.shown = logical(given);
                    end
                case "flag"
                    l_given = l_given && isscalar(given) && (islogical(given) || isnumeric(given));
                    if l_given
                        sct.shown = string(mat2str(logical(given)));
                    end
                case "string"
                    l_given = l_given && (isstring(given) || ischar(given)) && isscalar(string(given));
                    if l_given
                        sct.shown = string(given);
                    end
            end
            if ~l_given
                error(msg("GUILDA:DrawerOptionDialog:InvalidValue", sct.name, join(string(s_given), " ")))
            end
        end
        % Group and order: [section, position in the list of the section, position in the signature]
        % with section 0 for the required and positional inputs, 1 for the main options, 1+g for group g
        sct.rv_order = [1, numel(sv_main) + 1, k];
        if sct.kind ~= "namevalue"
            sct.rv_order(1:2) = 0;
        elseif ismember(s_name, sv_main)
            sct.rv_order(2) = find(sv_main == s_name, 1);
        else
            for g = 1:numel(c_group)
                sct_g = c_group{g};
                sv_member = strings(1, 0);
                if isfield(sct_g, "members") && ~isempty(sct_g.members)
                    sv_member = reshape(string(sct_g.members), 1, []);
                end
                l_in = ismember(s_name, sv_member);
                if isfield(sct_g, "prefix") && ~isempty(sct_g.prefix)
                    l_in = l_in || any(startsWith(s_name, string(sct_g.prefix)));
                end
                if isfield(sct_g, "pattern") && ~isempty(sct_g.pattern)
                    l_in = l_in || ~isempty(regexp(s_name, string(sct_g.pattern), "once"));
                end
                if l_in
                    sct.s_group  = string(sct_g.name);
                    sct.rv_order = [1 + g, find([sv_member, s_name] == s_name, 1), k];
                    break
                end
            end
            if sct.s_group == "" && l_spec    % an option the entry does not list
                sct.s_group  = "Advanced";
                sct.rv_order = [1 + numel(c_group) + 1, 1, k];
                for g = 1:numel(c_group)
                    if string(c_group{g}.name) == "Advanced"
                        sct.rv_order(1) = 1 + g;
                    end
                end
            end
        end
        sct_field(end+1) = sct;    %#ok<AGROW>
    end
    sv_unknown = setdiff(string(fieldnames(sct_value)), string({sct_field.name}));
    if ~isempty(sv_unknown)
        error(msg("GUILDA:DrawerOptionDialog:UnknownValue", obj.s_signature, sv_unknown(1)))
    end
    if ~isempty(sct_field)
        [~, iv_order] = sortrows(vertcat(sct_field.rv_order));
        sct_field = sct_field(iv_order);
    end
    % Choices and defaults that refer to an input after them (Time to From of add_scenario):
    % evaluated now that every field is made
    if ~isempty(sv_late)
        sct_field = refresh_depend(sct_field, sv_late, history, obj.a_object);
    end

    % A form drawn before by this object (ask reuses its forms): when every field needs the same
    % widget (name, kind, widget, items, label, hints, picker, group), the widgets are kept and
    % only take the values shown now; the groups close again (those of Value open). Otherwise
    % the old grid is deleted and the form is drawn again.
    sv_shape = ["name", "kind", "widget", "items", "s_label", "s_unit", "s_hint", "s_note", "s_wait", "s_pick", "s_group", "s_purpose", "l_multiple"];
    if ~isempty(obj.h_grid) && isvalid(obj.h_grid)
        sct_old = obj.sct_field;
        if numel(sct_old) == numel(sct_field) && isequal(rmfield(sct_old, setdiff(fieldnames(sct_old), sv_shape)), ...
                rmfield(sct_field, setdiff(fieldnames(sct_field), sv_shape)))
            for k = 1:numel(sct_field)
                sct = sct_old(k);
                sct_field(k).i_row = sct.i_row;
                for s_name = ["h", "h_label", "h_extra", "h_reset", "l_built"]
                    sct_field(k).(s_name) = sct.(s_name);
                end
                if ~sct.l_built
                    continue
                end
                switch sct.widget
                    case "tags"
                        new = cellstr(sct_field(k).shown);
                    case "logical"
                        new = logical(sct_field(k).shown);
                    otherwise
                        new = char(sct_field(k).shown);
                end
                if ~isequal(sct.h.Value, new)
                    sct.h.Value = new;
                end
            end
            for g = 1:numel(obj.sct_group)
                obj.sct_group(g).l_open = any(isfield(sct_value, cellstr([sct_field(obj.sct_group(g).iv_field).name])));
            end
            obj.sct_field = sct_field;
            for k = 1:numel(sct_field)
                g = find(string({obj.sct_group.name}) == sct_field(k).s_group, 1);
                if ~sct_field(k).l_built && (isempty(g) || obj.sct_group(g).l_open)
                    obj.draw_field(k);
                end
            end
            obj.form_event("change", 0);
            return
        end
        delete(obj.h_grid)
    end

    % Rows: the title, one per field and one per group header (heights set by form_event), the message
    sct_color = tools.gui_palette();
    sct_group = struct("name", {}, "h", {}, "l_open", {}, "iv_field", {}, "i_row", {});
    i_row = 1;
    for k = 1:numel(sct_field)
        s_group = sct_field(k).s_group;
        if s_group ~= "" && (isempty(sct_group) || sct_group(end).name ~= s_group)
            i_row = i_row + 1;
            sct_group(end+1) = struct("name", s_group, "h", [], "l_open", false, "iv_field", [], "i_row", i_row);    %#ok<AGROW>
        end
        if s_group ~= ""
            sct_group(end).iv_field(end+1) = k;
        end
        i_row = i_row + 1;
        sct_field(k).i_row = i_row;
    end
    % (form_event moves each row to its place; until then every field and header sits in the
    % row of height 0 before the message)
    for k = 1:numel(sct_field)
        sct_field(k).i_row = i_row + 1;
    end
    for g = 1:numel(sct_group)
        sct_group(g).i_row = i_row + 1;
    end
    obj.h_grid = uigridlayout(h_container, [i_row + 2, 4], "Scrollable", "on", ...
        "RowHeight", [{22}, repmat({0}, 1, i_row), {"fit"}], "ColumnWidth", {"fit", "1x", "fit", 24}, ...
        "BackgroundColor", sct_color.rv_background, "RowSpacing", 4, "ColumnSpacing", 6);
    h_title = uilabel(obj.h_grid, "Text", obj.s_object + "." + extractAfter(obj.s_signature, "."), ...
        "FontWeight", "bold", "FontColor", sct_color.rv_blue, "FontSize", 13);
    h_title.Layout.Column = [1 4];
    for g = 1:numel(sct_group)
        h_header = uibutton(obj.h_grid, "Text", sct_group(g).name, "HorizontalAlignment", "left", ...
            "FontWeight", "bold", "FontColor", sct_color.rv_blue, "BackgroundColor", sct_color.rv_background, ...
            "Tag", "group_" + replace(sct_group(g).name, " ", "_"), "ButtonPushedFcn", @(~, ~) obj.form_event("toggle", g));
        h_header.Layout.Row = sct_group(g).i_row;
        h_header.Layout.Column = [1 4];
        sct_group(g).h = h_header;
    end
    obj.h_message = uilabel(obj.h_grid, "Text", "", "WordWrap", "on", "FontColor", sct_color.rv_stale_text);
    obj.h_message.Layout.Row = i_row + 2;
    obj.h_message.Layout.Column = [1 4];
    % A group that holds a field given by Value opens at once (its value must be seen and written)
    for g = 1:numel(sct_group)
        sct_group(g).l_open = any(isfield(sct_value, cellstr([sct_field(sct_group(g).iv_field).name])));
    end
    obj.sct_field = sct_field;
    obj.sct_group = sct_group;
    for k = 1:numel(sct_field)
        if sct_field(k).s_group == "" || sct_group(string({sct_group.name}) == sct_field(k).s_group).l_open
            obj.draw_field(k);
        end
    end
    obj.form_event("change", 0);
end

function value = read_cached(s_file)
% Decoded JSON (.json) or text (.m) of a file, kept for the MATLAB session while the file is unchanged.
    arguments (Input)
        s_file (1,1) string  % File path.
    end
    arguments (Output)
        value  % jsondecode of the file, or its text.
    end
    persistent sct_cache
    if isempty(sct_cache)
        sct_cache = struct("s_file", {}, "r_date", {}, "value", {});
    end
    sct_dir = dir(s_file);
    i = find(string({sct_cache.s_file}) == s_file, 1);
    if ~isempty(i) && sct_cache(i).r_date == sct_dir.datenum
        value = sct_cache(i).value;
        return
    end
    value = fileread(s_file, "Encoding", "UTF-8");
    if endsWith(s_file, ".json")
        value = jsondecode(value);
    end
    if isempty(i)
        i = numel(sct_cache) + 1;
    end
    sct_cache(i) = struct("s_file", s_file, "r_date", sct_dir.datenum, "value", {value});
end

function [s_expr, sv_depend] = refer_args(s_expr, sv_arg, sv_arg_default, s_self)
% Expression with the other inputs of the method written as arg.<name>, and the names of those it refers to.
%
% An input is referred to by its name (`get_element(unit)`) or by its default when that is a
% property of the object (`obj.s_unit`, the default of Unit of EventInput.edit). Text in
% double quotes is left as it is.
    arguments (Input)
        s_expr (1,1) string          % Choices or default expression, e.g. "cellstr(obj.a_PowerNetwork.get_element(unit).sv_u)".
        sv_arg (1,:) string          % Names of the inputs of the form.
        sv_arg_default (1,:) string  % Their default expressions ("" for none).
        s_self (1,1) string          % Name of the input of the expression (not referred to).
    end
    arguments (Output)
        s_expr (1,1) string          % The expression with arg.<name>, e.g. "cellstr(obj.a_PowerNetwork.get_element(arg.unit).sv_u)".
        sv_depend (1,:) string       % Names of the inputs it refers to.
    end
    sv_depend = strings(1, 0);
    sv_part = split(s_expr, """");    % odd parts are outside the quotes
    for i = find(sv_arg ~= s_self)
        s_name = sv_arg(i);
        sv_pattern = "(?<![\w.])" + s_name + "(?!\w)";
        if ~isempty(regexp(sv_arg_default(i), "^obj(\.\w+)+$", "once"))
            sv_pattern(end+1) = "(?<![\w.])" + regexptranslate("escape", sv_arg_default(i)) + "(?![\w\x28])";    %#ok<AGROW> (\x28: "(" in a class here is not read as such)
        end
        for j = 1:2:numel(sv_part)
            for s_pattern = sv_pattern
                if ~isempty(regexp(sv_part(j), s_pattern, "once"))
                    sv_part(j) = regexprep(sv_part(j), s_pattern, "arg." + s_name);
                    sv_depend = union(sv_depend, s_name, "stable");
                end
            end
        end
    end
    s_expr = join(sv_part, """");
end
