function s_code = ask(h_parent_figure, s_signature, opt)
% Ask for the options of a method in a modal dialog and return the code of the call; "" on cancel.
%
% The dialog has the form of DrawerOptionDialog and the buttons Run and Cancel (Tags
% "dialog_run" and "dialog_cancel"). Run returns the code of get_code; while a value is
% invalid it only shows the message and the dialog stays open. Cancel or closing the window
% returns "". The dialog is centered on the parent figure and is hidden when the parent is
% hidden. Its height follows the form (no blank space above the buttons), up to 640 px, and
% grows when a group is opened; a longer form scrolls. The code is not run here: pass it to
% HistoryGUILDA.run.
%
% One hidden dialog window is kept per parent figure (one more for no parent) and reused, as
% the picker of DrawerTagPicker.pick does. It keeps the forms of its last calls (up to 8, by
% signature, Object, Output and Exclude): a call with the same ones refreshes the form drawn
% before (values, defaults and choices on the object of now; the groups closed again) instead
% of drawing it again, so the second opening costs only the new values. A form whose fields
% need other widgets now (e.g. other choices) is drawn again. Between calls the window is
% hidden and has no name; it is deleted with its parent.
%
% A visible dialog waits for the user, with no time limit, in uiwait steps of 1 s that read
% UserData again, so a button pressed before the wait (its uiresume came too early) is not lost;
% hiding the dialog while it waits ends it as a cancel. A hidden dialog (hidden parent) or one in
% `matlab -batch` has no user: it waits at most 10 s for a program (a test) to press its
% buttons and then returns "" as a cancel, so it never blocks indefinitely.
%
% <@Examples>
% ```matlab
% s_code = DrawerOptionDialog.ask(fig, "Bus.add_component", Object="net.a_Bus{3}", Output="comp", History=h);
% if s_code ~= ""
%     h.run("Model", "Add a component", s_code);
% end
% ```
    arguments (Input)
        h_parent_figure                   % uifigure the dialog belongs to, or [] for none.
        s_signature (1,1) string          % Method in functionSignatures.json, e.g. "Bus.add_component".
        opt.Object  (1,1) string          % Object expression of the call, e.g. "net.a_Bus{3}".
        opt.Output  (1,:) string = ""     % Output variables of the call, e.g. "res_pf" ("" for none).
        opt.Exclude (1,:) string = string.empty  % Inputs left out of the form, e.g. "Parent".
        opt.History (1,1) HistoryGUILDA   % Log whose workspace holds the root variable of Object (see DrawerOptionDialog).
        opt.Value   (1,1) struct = struct()   % Initial values by input name, as MATLAB code text (see DrawerOptionDialog).
    end
    arguments (Output)
        s_code (1,1) string  % Code of the call, or "" when the dialog was canceled.
    end
    sct_color = tools.gui_palette();
    % The window of the parent: reused while it exists
    h_fig = [];
    if isempty(h_parent_figure)
        h_fig = findall(groot, "Type", "figure", "Tag", "DrawerOptionDialog_none");
    elseif isappdata(h_parent_figure, "DrawerOptionDialog")
        h_fig = getappdata(h_parent_figure, "DrawerOptionDialog");
    end
    if isempty(h_fig) || ~isvalid(h_fig(1))
        h_fig = uifigure("Name", "", "Visible", "off", "WindowStyle", "modal", "Tag", "DrawerOptionDialog", ...
            "Color", sct_color.rv_background, "Position", [100 100 560 300]);
        if isprop(h_fig, "Theme")
            h_fig.Theme = "light";
        end
        h_grid = uigridlayout(h_fig, [2 1], "RowHeight", {"1x", 30}, "BackgroundColor", sct_color.rv_background);
        h_button = uigridlayout(h_grid, [1 3], "ColumnWidth", {"1x", 100, 100}, "Padding", 0, ...
            "BackgroundColor", sct_color.rv_background);
        h_button.Layout.Row = 2;
        h_run = uibutton(h_button, "Text", "Run", "Tag", "dialog_run", "BackgroundColor", sct_color.rv_blue, ...
            "FontColor", sct_color.rv_header_text, "ButtonPushedFcn", @(~, ~) close_dialog(h_fig, get_code(getappdata(h_fig, "dlg"))));
        h_run.Layout.Column = 2;
        h_cancel = uibutton(h_button, "Text", "Cancel", "Tag", "dialog_cancel", "BackgroundColor", sct_color.rv_card, ...
            "FontColor", sct_color.rv_text, "ButtonPushedFcn", @(~, ~) close_dialog(h_fig, missing));
        h_cancel.Layout.Column = 3;
        h_fig.CloseRequestFcn = @(~, ~) close_dialog(h_fig, missing);
        setappdata(h_fig, "sct_form", struct("s_key", {}, "h_panel", {}, "dlg", {}));
        if isempty(h_parent_figure)
            h_fig.Tag = "DrawerOptionDialog_none";
        else
            setappdata(h_parent_figure, "DrawerOptionDialog", h_fig);
            addlistener(h_parent_figure, "ObjectBeingDestroyed", @(~, ~) delete(h_fig(isvalid(h_fig))));
        end
    end
    h_fig = h_fig(1);
    h_grid = h_fig.Children(1);
    % The form of the call: the one kept for the same signature, Object, Output and Exclude
    % (refreshed in place by build_form), else a new one in its own panel; the most recent last
    s_key = s_signature + "|" + opt.Object + "|" + sprintf("%s,", opt.Output) + "|" + sprintf("%s,", opt.Exclude);
    sct_form = getappdata(h_fig, "sct_form");
    sct_form = sct_form(arrayfun(@(f) isvalid(f.h_panel), sct_form));
    i_form = find(string({sct_form.s_key}) == s_key, 1);
    history = [];
    if isfield(opt, "History")
        history = opt.History;
    end
    try
        if isempty(i_form)
            h_panel = uipanel(h_grid, "BorderType", "none", "BackgroundColor", sct_color.rv_background);
            h_panel.Layout.Row = 1;
            c_opt = namedargs2cell(opt);
            dlg = DrawerOptionDialog(s_signature, h_panel, c_opt{:});
            sct_form(end+1) = struct("s_key", s_key, "h_panel", h_panel, "dlg", dlg);
        else
            h_panel = sct_form(i_form).h_panel;
            dlg = sct_form(i_form).dlg;
            dlg.f_resize = [];
            dlg.build_form(h_panel, opt.Exclude, history, opt.Value);
            sct_form = [sct_form([1:i_form-1, i_form+1:end]), sct_form(i_form)];
        end
    catch ME    % a form that cannot be made: its panel is not kept
        if isempty(i_form) && exist("h_panel", "var") && isvalid(h_panel)
            delete(h_panel)
        elseif ~isempty(i_form)
            delete(sct_form(i_form).h_panel)
        end
        sct_form = sct_form(arrayfun(@(f) isvalid(f.h_panel), sct_form));
        setappdata(h_fig, "sct_form", sct_form);
        rethrow(ME)
    end
    if numel(sct_form) > 8    % the oldest forms are dropped
        delete([sct_form(1:end-8).h_panel])
        sct_form = sct_form(end-7:end);
    end
    setappdata(h_fig, "sct_form", sct_form);
    setappdata(h_fig, "dlg", dlg);
    for f = sct_form(1:end-1)
        if f.h_panel.Visible
            f.h_panel.Visible = "off";
        end
    end
    h_panel.Visible = "on";
    h_fig.UserData = [];
    c_hide = onCleanup(@() set(h_fig(isvalid(h_fig)), "Visible", "off", "Name", "", "UserData", []));
    l_visible = true;
    rv_center = [];
    if ~isempty(h_parent_figure)
        rv_pos = h_parent_figure.Position;
        rv_center = rv_pos(1:2) + rv_pos(3:4) / 2;
        l_visible = logical(h_parent_figure.Visible);
    end
    % The height of the window follows the form: the form, the buttons and the paddings (10 px
    % each) of h_grid; the top edge stays where it is when a group opens
    dlg.f_resize = @(n_form) set(h_fig, "Position", h_fig.Position + ...
        [0, h_fig.Position(4) - min(640, max(160, n_form + 60)), 0, min(640, max(160, n_form + 60)) - h_fig.Position(4)]);
    dlg.form_event("change", 0);
    if ~isempty(rv_center)
        h_fig.Position(1:2) = rv_center - h_fig.Position(3:4) / 2;
    end
    h_fig.Name = s_signature;    % last: a program (a test) finds the dialog by its name
    h_fig.Visible = l_visible;
    if l_visible && ~batchStartupOptionUsed
        % A user answers. A button pressed before the wait (a program, while the Visible change
        % runs the callbacks and timers) has set UserData already and its uiresume came too
        % early: wait in steps of 1 s and read UserData again. A hidden dialog has nobody to
        % answer it: the wait ends as a cancel
        while isvalid(h_fig) && isempty(h_fig.UserData) && h_fig.Visible
            uiwait(h_fig, 1)
        end
    else
        % Nobody can answer a hidden dialog: wait at most 10 s for a program to press a button
        % (pause runs the callbacks and timers), then cancel. The loop ends by itself even when
        % no callback runs. drawnow first flushes the graphics queue: right after many figures
        % were deleted, pause alone runs the timers only about once in 2 s.
        t_start = tic;
        while isvalid(h_fig) && isempty(h_fig.UserData) && toc(t_start) < 10
            drawnow
            pause(0.05)
        end
    end
    s_code = "";
    if isvalid(h_fig) && isstring(h_fig.UserData)
        s_code = h_fig.UserData;
    end
end
