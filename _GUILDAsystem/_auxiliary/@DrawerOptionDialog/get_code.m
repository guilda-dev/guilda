function s_code = get_code(obj)
% Code of the call for the current values of the form; "" while a value is invalid.
%
% The code is `<outputs> = <Object>.<method>(<required inputs>, Name=Value, ...);` with the
% required inputs in order and only the visible options whose value differs from the default
% (or the GUILDA.config setting for the analysis methods). Tags are written as `"B001"` (one)
% or `["B001", "B002"]` (several). "auto" (or the word of gui_forms.json for NaN) and "none"
% in a number field are written as the number they stand for (NaN, Inf or -Inf). An optional positional input is written when it
% or a later one is changed. The fields of a group that was never opened keep their default.
% A field changed from its default is highlighted and shows its reset button. When a value is
% invalid (not a number, an unknown tag, or a required input left empty), the form shows the
% message, the field is highlighted and "" is returned; nothing is thrown, so the fields call
% it on every change.
%
% <@Examples>
% ```matlab
% s_code = dlg.get_code()   % e.g. comp = net.a_Bus{3}.add_component("gen-park", P=0.5);
% ```
    arguments (Input)
        obj  % The form.
    end
    arguments (Output)
        s_code (1,1) string  % One line of MATLAB code, or "" while a value is invalid.
    end
    sct_color  = tools.gui_palette();
    rv_changed = [0.89 0.94 1.00];    % background of a changed field
    sv_problem = strings(0, 1);
    sv_input   = strings(1, 0);    % required inputs
    sv_ordered = strings(1, 0);    % optional positional inputs
    sv_ordered_name = strings(1, 0);
    l_ordered  = false(1, 0);      % ... changed from the initial value
    sv_option  = strings(1, 0);    % Name=Value
    for k = 1:numel(obj.sct_field)
        sct = obj.sct_field(k);
        h   = sct.h;
        s_value   = "";
        l_changed = false;
        s_problem = "";
        if ~sct.l_built    % a field of a group never opened: the default
            if sct.kind == "ordered"
                sv_ordered(end+1) = sct.s_default;    %#ok<AGROW>
                sv_ordered_name(end+1) = sct.name;    %#ok<AGROW>
                l_ordered(end+1) = false;             %#ok<AGROW>
            end
            continue
        end
        switch sct.widget
            case "tags"
                sv_text = reshape(string(h.Value), 1, []);
                sv_text = sv_text(ismember(sv_text, sct.items));
                if ~isempty(sv_text) || sct.kind ~= "required"
                    s_value = code_strings(sv_text);    % none selected: strings(1,0)
                else
                    s_problem = string(msg("GUILDA:DrawerOptionDialog:Required", sct.name));
                end
                l_changed = ~isequal(sort(sv_text(:)), sort(sct.baseline(:)));
            case "tagtext"
                sv_text = parse_tags(string(h.Value));
                sv_unknown = sv_text(~ismember(sv_text, sct.items));
                if ~isempty(sct.items) && ~isempty(sv_unknown)
                    s_problem = string(msg("GUILDA:DrawerOptionDialog:UnknownTag", sct.name, sv_unknown(1)));
                elseif ~isempty(sv_text) || sct.kind ~= "required"
                    s_value = code_strings(sv_text);
                else
                    s_problem = string(msg("GUILDA:DrawerOptionDialog:Required", sct.name));
                end
                l_changed = ~isequal(sv_text(:), sct.baseline(:));
            case "choice"
                s_text = string(h.Value);
                if s_text ~= ""
                    s_value   = code_strings(s_text);
                    l_changed = s_text ~= sct.baseline;
                elseif sct.kind == "required"    % no choice (e.g. no scenario yet)
                    s_problem = string(msg("GUILDA:DrawerOptionDialog:Required", sct.name));
                end
            case "flag"    % "" leaves the option out
                s_value   = string(h.Value);
                l_changed = s_value ~= sct.baseline;
            case "logical"
                s_value   = string(mat2str(logical(h.Value)));
                l_changed = logical(h.Value) ~= sct.baseline;
            case "number"
                s_text = strtrim(string(h.Value));
                if s_text == "" && sct.kind == "required"
                    s_problem = string(msg("GUILDA:DrawerOptionDialog:Required", sct.name));
                elseif s_text == ""    % emptied: left out, as the default
                elseif s_text == sct.s_base    % the default as shown (also a rounded pi/2, or "turbo")
                    s_value = s_text;
                    if ~isempty(sct.baseline) && numel(sct.baseline) <= 16
                        s_value = string(mat2str(sct.baseline, 17));
                    end
                elseif s_text == sct.s_auto && ~isempty(sct.r_auto)
                    s_value   = "NaN";
                    l_changed = ~isequaln(sct.baseline, NaN);
                elseif s_text == "none" && ~isempty(sct.r_none)
                    s_value   = string(mat2str(sct.r_none));
                    l_changed = ~isequaln(sct.baseline, sct.r_none);
                else
                    num = str2double(s_text);
                    if isnan(num) && ~strcmpi(s_text, "nan")
                        [num, l_num] = str2num(char(s_text), Evaluation="restricted");    %#ok<ST2NM> also takes [0.1 0.02], Inf, -1e3
                        if ~l_num || ~(isnumeric(num) || islogical(num)) || ~isreal(num)
                            s_problem = string(msg("GUILDA:DrawerOptionDialog:NotNumber", sct.name, s_text));
                        end
                    end
                    s_value   = s_text;
                    l_changed = s_problem == "" && ~isequaln(double(num), sct.baseline);
                end
            case "string"
                s_text    = string(h.Value);
                s_value   = code_strings(s_text);
                l_changed = s_text ~= sct.baseline;
                if s_text == "" && sct.kind == "required"
                    s_problem = string(msg("GUILDA:DrawerOptionDialog:Required", sct.name));
                end
            case "expression"
                s_text = strtrim(string(h.Value));
                if s_text == sct.s_auto && ~isempty(sct.r_auto)
                    s_value   = "NaN";
                    l_changed = sct.s_base ~= sct.s_auto;
                elseif s_text ~= ""
                    s_value   = s_text;
                    l_changed = s_text ~= sct.s_base;
                elseif sct.kind == "required"
                    s_problem = string(msg("GUILDA:DrawerOptionDialog:Required", sct.name));
                end
        end
        % Highlight: invalid, changed or default; the reset button of a changed field
        obj.sct_field(k).l_changed = l_changed && s_problem == "";
        % (a property is set only when it changes: each set is sent to the view and redrawn)
        if isprop(h, "BackgroundColor")
            if s_problem ~= ""
                rv_back = sct_color.rv_stale_back;
            elseif l_changed
                rv_back = rv_changed;
            else
                rv_back = sct_color.rv_card;
            end
            if ~isequal(h.BackgroundColor, rv_back)
                h.BackgroundColor = rv_back;
            end
        end
        rv_font = sct_color.rv_text;
        if l_changed
            rv_font = sct_color.rv_blue;
        end
        if ~isequal(sct.h_label.FontColor, rv_font)
            sct.h_label.FontColor = rv_font;
        end
        if l_changed && isempty(sct.h_reset)
            sct.h_reset = uibutton(obj.h_grid, "Text", "↺", "Tag", char("reset_" + sct.name), ...
                "Tooltip", "Reset to the default", "BackgroundColor", sct_color.rv_card, "FontColor", sct_color.rv_blue, ...
                "ButtonPushedFcn", @(~, ~) obj.form_event("reset", k));
            sct.h_reset.Layout.Row = sct.i_row;
            sct.h_reset.Layout.Column = 4;
            obj.sct_field(k).h_reset = sct.h_reset;
        end
        if ~isempty(sct.h_reset) && sct.h_reset.Visible ~= (l_changed && sct.l_shown)
            sct.h_reset.Visible = l_changed && sct.l_shown;
        end
        if s_problem ~= ""
            sv_problem(end+1) = s_problem;    %#ok<AGROW>
            continue
        end
        switch sct.kind
            case "required"
                sv_input(end+1) = s_value;    %#ok<AGROW>
            case "ordered"
                if s_value == ""
                    s_value = sct.s_default;   % written only when a later input is changed
                end
                sv_ordered(end+1) = s_value;   %#ok<AGROW>
                sv_ordered_name(end+1) = sct.name;    %#ok<AGROW>
                l_ordered(end+1)  = l_changed; %#ok<AGROW>
            otherwise
                if l_changed && s_value ~= "" && sct.l_visible
                    sv_option(end+1) = sct.name + "=" + s_value;    %#ok<AGROW>
                end
        end
    end
    % Group headers: ▸ closed, ▾ open, with the number of options and of changed ones
    for g = 1:numel(obj.sct_group)
        iv = obj.sct_group(g).iv_field;
        iv = iv([obj.sct_field(iv).l_visible]);
        n_changed = nnz([obj.sct_field(iv).l_changed]);
        s_head = "▸ ";
        if obj.sct_group(g).l_open
            s_head = "▾ ";
        end
        s_count = "(" + numel(iv) + ")";
        if n_changed > 0
            s_count = "(" + numel(iv) + ", " + n_changed + " changed)";
        end
        s_text = s_head + obj.sct_group(g).name + "  " + s_count;
        if string(obj.sct_group(g).h.Text) ~= s_text
            obj.sct_group(g).h.Text = s_text;
        end
    end
    sv_ordered = sv_ordered(1:find(l_ordered, 1, "last"));
    if any(sv_ordered == "")
        sv_problem(end+1) = string(msg("GUILDA:DrawerOptionDialog:Required", ...
            sv_ordered_name(find(sv_ordered == "", 1))));
    end
    if ~isempty(sv_problem)
        if string(obj.h_message.Text) ~= sv_problem(1)
            obj.h_message.Text = sv_problem(1);
        end
        if ~isequal(obj.h_grid.RowHeight{end}, "fit")
            obj.h_grid.RowHeight{end} = "fit";    % the message row (no height while empty)
        end
        s_code = "";
        return
    end
    if string(obj.h_message.Text) ~= ""
        obj.h_message.Text = "";
    end
    if ~isequal(obj.h_grid.RowHeight{end}, 0)
        obj.h_grid.RowHeight{end} = 0;
    end
    switch numel(obj.sv_output)
        case 0
            s_lhs = "";
        case 1
            s_lhs = obj.sv_output + " = ";
        otherwise
            s_lhs = "[" + join(obj.sv_output, ", ") + "] = ";
    end
    sv_arg = [sv_input, sv_ordered, sv_option];
    s_arg  = "";
    if ~isempty(sv_arg)
        s_arg = join(sv_arg, ", ");
    end
    s_code = s_lhs + obj.s_object + "." + extractAfter(obj.s_signature, ".") + "(" + s_arg + ");";
end
