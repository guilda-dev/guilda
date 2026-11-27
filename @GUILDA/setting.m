function setting(s_category, varargin)
% Change the GUILDA settings: in the settings window, or by command
%
% Without inputs, opens the settings window (GUI): the sections are listed on the left,
% and the settings of the selected section on the right, each with its name, an input
% field of its type (a check box for "logical", a drop-down list for "select") and its
% description. The window keeps its size, and a long section scrolls. Apply saves the
% changes of all sections.
%
% With a category and Name-Value arguments, changes those settings without opening the
% window. Each value is checked against the type of the setting ("double", "logical",
% "string", or "select" with its options) and its condition, and stored in the class of
% the type (string, logical, double), the same check GUILDA.config applies when it reads
% the settings files; an unknown category or name, or an invalid value, stops with an
% error and changes nothing. The change is saved in @GUILDA/user, as with Apply in the
% window, so it stays after MATLAB restarts, and the next GUILDA.config call and
% analysis use it. The same check applies to a value entered in the window.
%
% A change of a setting read at startup takes effect at the next start, or when the
% function that reads it runs: e.g. ModelFolder (Startup), the folders of your own model
% classes, is read by GUILDA.addpath and GUILDA.dictionary, so run GUILDA.addpath and
% GUILDA.update_keymap after changing it. The setting itself does not change the path.
%
% A new version of GUILDA may reset the settings of a category to their defaults (INFO
% at startup): the user settings of a category are kept only while the version of its
% default file stays the same. A value of a user file that fails the check above (e.g.
% written by hand) is reset to its default when the settings are read (INFO).
%
% <@Examples>
% ```matlab
% GUILDA.setting
% GUILDA.setting("PowerFlowCalculation", Tolerance=1e-10, WhenFailed="ERROR")
% GUILDA.config("PowerFlowCalculation", "Tolerance")
% GUILDA.setting("Startup", ModelFolder=["/home/user/myModels", "/home/user/lab"])
% GUILDA.setting("Startup", ModelFolder=strings(1,0))   % no folder
% ```
%
% See also GUILDA.config
    arguments (Input)
        s_category string {mustBeScalarOrEmpty} = string.empty  % Settings category, e.g. "PowerFlowCalculation"; omit to open the window.
    end
    arguments (Input, Repeating)
        varargin  % Name-Value pairs: setting name and new value.
    end

    if ~isempty(s_category)
        set_by_command(s_category, varargin);
        return
    end

    % Settings window: built from the settings (get_config) at each opening, one section
    % at a time with one row per setting. The window keeps its size; a long section scrolls.
    env      = get_config();
    sv_sec   = string(fieldnames(env))';
    sv_dirty = strings(1,0);   % sections with changes that are not applied

    col_back   = [0.95 0.96 0.97];
    col_panel  = [1 1 1];
    col_accent = [0.00 0.36 0.60];
    col_muted  = [0.38 0.40 0.44];
    r_size     = [980, 640];   % [px] width and height of the window
    r_name     = 230;          % [px] column of the setting names
    r_value    = 230;          % [px] width of the input fields
    r_desc     = 470;          % [px] width of the descriptions, for their number of lines

    r_scr = get(groot, "ScreenSize");
    r_pos = [100, 100, r_size];
    if all(r_scr(3:4) > r_size)
        r_pos(1:2) = round((r_scr(3:4) - r_size) / 2);
    end
    uifig = uifigure("Name", "GUILDA Settings", ...
                     "Position", r_pos, ...
                     "Resize", "off", ...
                     "Color", col_back, ...
                     "CloseRequestFcn", @(~,~) close_window());

    g_main = uigridlayout(uifig, [3, 2], ...
                     "RowHeight", {52, '1x', 36}, ...
                     "ColumnWidth", {190, '1x'}, ...
                     "Padding", [14 12 14 12], ...
                     "RowSpacing", 10, "ColumnSpacing", 12, ...
                     "BackgroundColor", col_back);

    % header: title and logo
    g_head = uigridlayout(g_main, [1, 2], "ColumnWidth", {'1x', 160}, "Padding", 0, ...
                     "BackgroundColor", col_back);
    g_head.Layout.Row = 1;  g_head.Layout.Column = [1, 2];
    uilabel(g_head, "Text", "GUILDA Settings", "FontSize", 22, "FontWeight", "bold");
    uiimage(g_head, "ImageSource", fullfile(GUILDA.pwd, "@GUILDA", "config", "GUILDAlogo.png"), ...
                     "HorizontalAlignment", "right", "ScaleMethod", "fit");

    % list of the sections
    lb_sec = uilistbox(g_main, "Items", sv_sec, "ItemsData", sv_sec, "Value", sv_sec(1), ...
                     "FontSize", 14, "Tag", "sections", ...
                     "ValueChangedFcn", @(src,~) show_section(src.Value));
    lb_sec.Layout.Row = 2;  lb_sec.Layout.Column = 1;

    % selected section: heading and the scrolling table of its settings
    pnl = uipanel(g_main, "BackgroundColor", col_panel, "BorderType", "line");
    pnl.Layout.Row = 2;  pnl.Layout.Column = 2;
    g_sec = uigridlayout(pnl, [2, 1], "RowHeight", {32, '1x'}, "Padding", [16 10 6 10], ...
                     "RowSpacing", 8, "BackgroundColor", col_panel);
    lbl_sec = uilabel(g_sec, "Text", "", "FontSize", 18, "FontWeight", "bold", ...
                     "FontColor", col_accent, "Tag", "heading");
    g_list = uigridlayout(g_sec, [1, 2], ...
                     "ColumnWidth", {r_name, '1x'}, ...
                     "Padding", [0 0 12 0], ...
                     "RowSpacing", 2, "ColumnSpacing", 14, ...
                     "Scrollable", "on", "Tag", "settings", ...
                     "BackgroundColor", col_panel);

    % footer: changes not applied, and the buttons
    g_foot = uigridlayout(g_main, [1, 3], "ColumnWidth", {'1x', 110, 110}, "Padding", 0, ...
                     "ColumnSpacing", 10, "BackgroundColor", col_back);
    g_foot.Layout.Row = 3;  g_foot.Layout.Column = [1, 2];
    lbl_state = uilabel(g_foot, "Text", "", "FontColor", col_muted, "Tag", "state");
    btn_apply = uibutton(g_foot, "Text", "Apply", "FontWeight", "bold", "Enable", "off", ...
                     "Tag", "apply", "ButtonPushedFcn", @(~,~) apply());
    uibutton(g_foot, "Text", "Close", "Tag", "close", "ButtonPushedFcn", @(~,~) close_window());

    show_section(sv_sec(1));


    function show_section(s_sec)
        % Rebuild the table for one section: per setting, a row with the name and the
        % input field of its type, and a row with the description
        delete(g_list.Children);
        lbl_sec.Text = s_sec;
        sct      = env.(s_sec);
        sv_name  = string(fieldnames(sct))';
        c_height = cell(1, 2*numel(sv_name));
        for k = 1:numel(sv_name)
            s_name  = sv_name(k);
            sct_set = sct.(s_name);
            s_desc  = string(sct_set.Description);
            c_height{2*k-1} = 26;
            c_height{2*k}   = 16*max(1, ceil(strlength(s_desc) * 5.9 / r_desc)) + 10;

            lbl = uilabel(g_list, "Text", s_name, "FontSize", 13, "FontWeight", "bold", ...
                          "Tag", "name", "Tooltip", "Type: " + sct_set.Type);
            lbl.Layout.Row = 2*k-1;  lbl.Layout.Column = 1;

            % the input field keeps its width: a grid with a free column after it
            g_val = uigridlayout(g_list, [1, 2], "ColumnWidth", {r_value, '1x'}, "Padding", 0, ...
                                 "BackgroundColor", col_panel);
            g_val.Layout.Row = 2*k-1;  g_val.Layout.Column = 2;
            f_change = @(src,~) change(src, s_sec, s_name);
            switch sct_set.Type
                case "logical"
                    ed = uicheckbox(g_val, "Text", "", "Value", sct_set.Value, "ValueChangedFcn", f_change);
                case "select"
                    ed = uidropdown(g_val, "Items", string(sct_set.options), "Value", sct_set.Value, ...
                                    "ValueChangedFcn", f_change);
                case "double"
                    ed = uieditfield(g_val, "text", "Value", text_of(sct_set), ...
                                     "HorizontalAlignment", "right", "ValueChangedFcn", f_change);
                case "string"
                    ed = uieditfield(g_val, "text", "Value", text_of(sct_set), "ValueChangedFcn", f_change);
                otherwise
                    ed = uilabel(g_val, "Text", text_of(sct_set));
            end
            ed.Tag = "value";
            if isfield(sct_set, "Valid")
                ed.Tooltip = "Condition: " + string(sct_set.Valid);
            end

            lbl = uilabel(g_list, "Text", s_desc, "FontSize", 12, "FontColor", col_muted, ...
                          "WordWrap", "on", "VerticalAlignment", "top", "Tag", "description");
            lbl.Layout.Row = 2*k;  lbl.Layout.Column = 2;
        end
        g_list.RowHeight = c_height;
        scroll(g_list, "top");
    end

    function change(src, s_sec, s_name)
        % Check the new value of a field as GUILDA.setting does: keep it, or restore the field
        sct_set = env.(s_sec).(s_name);
        val     = src.Value;
        l_text  = isa(src, "matlab.ui.control.EditField");
        if l_text && sct_set.Type == "double"
            % "0.1" for a scalar; "[0.1 0.02]" or "0.1, 0.02" for an array (Size is checked)
            sv_tok = split(erase(string(val), ["[","]"]), [" ",",",";"])';
            sv_tok = sv_tok(strtrim(sv_tok) ~= "");
            val    = str2double(sv_tok);            % NaN for text that is not a number
            if isempty(val) || any(isnan(val) & ~strcmpi(strtrim(sv_tok), "nan"))
                val = string(src.Value);            % fails the check below
            end
        elseif l_text
            val = strtrim(split(string(val), ","))';   % comma-separated: "Q, V" -> ["Q","V"]
            val = val(val ~= "");
            if isempty(val)
                val = string(missing);              % fails the check below
            end
        end
        [val, l_ok, s_expect] = check_setting(sct_set, val);
        if ~l_ok
            if l_text
                src.Value = text_of(sct_set);
            else
                src.Value = sct_set.Value;
            end
            lbl_state.Text = "Invalid value: " + s_name + " needs " + s_expect + ".";
            if uifig.Visible   % uialert needs a visible window
                uialert(uifig, s_name + " needs " + s_expect + ".", "Invalid value", "Icon", "warning");
            end
            return
        end
        env.(s_sec).(s_name).Value = val;
        if l_text
            src.Value = text_of(env.(s_sec).(s_name));
        end
        sv_dirty = unique([sv_dirty, s_sec], "stable");
        mark_dirty();
    end

    function mark_dirty()
        % Mark the sections with changes that are not applied, and enable Apply for them
        sv_item = sv_sec;
        l_dirty = ismember(sv_sec, sv_dirty);
        sv_item(l_dirty) = sv_item(l_dirty) + "  *";
        lb_sec.Items     = sv_item;
        btn_apply.Enable = ~isempty(sv_dirty);
        if isempty(sv_dirty)
            lbl_state.Text = "";
        else
            lbl_state.Text = "Changes not applied: " + strjoin(sv_dirty, ", ");
        end
    end

    function apply()
        set_config(env);
        sv_dirty = strings(1,0);
        mark_dirty();
        lbl_state.Text = "Saved in @GUILDA/user.";
    end

    function close_window()
        if ~isempty(sv_dirty)
            s_sel = uiconfirm(uifig, "Apply the changed settings?", "Close", ...
                              "Options", ["Apply", "Discard", "Cancel"], ...
                              "DefaultOption", 1, "CancelOption", 3);
            switch s_sel
                case "Apply";   apply();
                case "Cancel";  return
            end
        end
        delete(uifig);
    end

end


function set_by_command(s_category, c_nv)
    % Check the Name-Value pairs against the settings of the category, then save them all
    arguments (Input)
        s_category (1,1) string  % Settings category.
        c_nv       cell          % Name-Value pairs.
    end
    env = get_config();
    if ~isfield(env, s_category)
        error(msg("GUILDA:GUILDA:UnknownSettingCategory", s_category, strjoin(string(fieldnames(env)), ", ")))
    end
    sct = env.(s_category);
    if mod(numel(c_nv), 2) ~= 0 || isempty(c_nv)
        error(msg("GUILDA:GUILDA:SettingNameValue", s_category))
    end
    for k = 1:2:numel(c_nv)
        s_name = c_nv{k};
        if ~(ischar(s_name) || isstring(s_name) && isscalar(s_name)) || ~isfield(sct, s_name)
            if ~(ischar(s_name) || isstring(s_name))
                s_name = "(" + class(s_name) + ")";
            end
            error(msg("GUILDA:GUILDA:UnknownSettingName", string(s_name), s_category, ...
                strjoin(string(fieldnames(sct)), ", ")))
        end
        s_name = char(s_name);
        [val, l_ok, s_expect] = check_setting(sct.(s_name), c_nv{k+1});
        if ~l_ok
            error(msg("GUILDA:GUILDA:InvalidSettingValue", s_category, s_name, s_expect))
        end
        sct.(s_name).Value = val;
    end
    env.(s_category) = sct;
    set_config(env);
end


function s = text_of(sct_set)
    % Text of the value of a setting in its input field (a string row joined by ", ",
    % a double array as "[0.1 0.02]")
    arguments (Input)
        sct_set (1,1) struct  % Definition of the setting with its Value.
    end
    arguments (Output)
        s (1,1) string  % Text of the value.
    end
    if isnumeric(sct_set.Value) && isscalar(sct_set.Value)
        s = string(num2str(sct_set.Value, 15));   % all digits (string() keeps 5)
    elseif isnumeric(sct_set.Value)
        s = "[" + strjoin(arrayfun(@(v) string(num2str(v, 15)), sct_set.Value(:).'), " ") + "]";
    else
        s = strjoin(string(sct_set.Value), ", ");
    end
end
