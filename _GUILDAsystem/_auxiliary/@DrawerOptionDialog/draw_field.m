function draw_field(obj, k)
% Draw the row of one field: its label, its widget, and the Select... button or a hint (a default in words, the hint of gui_forms.json, or "Select unit first").
%
% The label is the name (or the label of gui_forms.json) with the unit, e.g. "P [pu]", and a
% star for a required input. The widget shows sct_field(k).shown and has the input name as
% its Tag. The reset button is drawn by get_code when the field is first changed.
    arguments (Input)
        obj           % The form.
        k (1,1) double  % Index of the field.
    end
    arguments (Output)
    end
    sct = obj.sct_field(k);
    sct_color = tools.gui_palette();
    h_grid = obj.h_grid;
    s_text = sct.s_label;
    if sct.s_unit ~= ""
        s_text = s_text + " [" + sct.s_unit + "]";
    end
    s_tooltip = sct.s_purpose;
    if sct.s_label ~= sct.name
        s_tooltip = sct.name + ": " + s_tooltip;
    end
    h_label = uilabel(h_grid, "Text", s_text, "Tooltip", s_tooltip, "FontColor", sct_color.rv_text);
    if sct.kind == "required"    % required inputs: bold, with a star
        h_label.Text = s_text + " *";
        h_label.FontWeight = "bold";
    end
    switch sct.widget
        case "tags"
            h = uilistbox(h_grid, "Items", cellstr(sct.items), "Multiselect", "on", ...
                "Value", cellstr(sct.shown), "BackgroundColor", sct_color.rv_card, "FontColor", sct_color.rv_text);
        case {"choice", "flag"}
            h = uidropdown(h_grid, "Items", cellstr(sct.items), "Value", char(sct.shown), ...
                "BackgroundColor", sct_color.rv_card, "FontColor", sct_color.rv_text);
        case "logical"
            h = uicheckbox(h_grid, "Text", "", "Value", sct.shown, "FontColor", sct_color.rv_text);
        otherwise    % number, string, expression, tagtext: the text shown
            h = uieditfield(h_grid, "text", "Value", char(sct.shown), ...
                "BackgroundColor", sct_color.rv_card, "FontColor", sct_color.rv_text);
    end
    h.Tag = char(sct.name);
    h.Tooltip = s_tooltip;
    h.ValueChangedFcn = @(~, ~) obj.form_event("change", k);
    h_extra = [];
    if sct.s_pick ~= ""
        h_extra = uibutton(h_grid, "Text", "Select...", "Tag", char("select_" + sct.name), ...
            "Tooltip", "Choose from a table", "BackgroundColor", sct_color.rv_card, "FontColor", sct_color.rv_text, ...
            "ButtonPushedFcn", @(~, ~) obj.form_event("select", k));
        if sct.s_hint ~= "" && isprop(h, "Placeholder")    % the button takes the place of the hint
            h.Placeholder = "default: " + sct.s_hint;
        end
    elseif sct.s_hint ~= "" || sct.s_note ~= "" || ~isempty(sct.sv_depend)
        % the default in words, the hint of gui_forms.json "labels", or (a field whose choices or
        % default depend on another input) the label form_event writes when that input changes
        s_hint_tip = s_tooltip;
        if sct.s_hint ~= ""
            s_hint_tip = "Default: " + sct.s_hint;
        end
        h_extra = uilabel(h_grid, "Text", hint_text(sct), "Tag", char("hint_" + sct.name), ...
            "Tooltip", s_hint_tip, "FontAngle", "italic", "FontColor", sct_color.rv_subtext);
    end
    h_label.Layout.Row = sct.i_row;
    h_label.Layout.Column = 1;
    h.Layout.Row = sct.i_row;
    h.Layout.Column = 2;
    if ~isempty(h_extra)
        h_extra.Layout.Row = sct.i_row;
        h_extra.Layout.Column = 3;
    end
    obj.sct_field(k).h       = h;
    obj.sct_field(k).h_label = h_label;
    obj.sct_field(k).h_extra = h_extra;
    obj.sct_field(k).l_built = true;
end
