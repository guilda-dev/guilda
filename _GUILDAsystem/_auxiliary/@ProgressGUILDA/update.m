function stop = update(obj, s_text, r_fraction)
% Show the text of the current step: a line (mode "disp") or the dialog (mode "dialog").
%
% Every mode keeps s_text and r_fraction (the last step). "disp" prints s_text when it
% differs from the last text. "dialog" draws it when the run has lasted 0.5 s (the timer
% also calls update to open the dialog and move the bar); it draws at most every 0.1 s. A dialog closed by the user is not opened
% again. stop is always false, so update can be the f_iter of a Method class.
    arguments (Input)
        obj
        s_text     (1,1) string         % Text of the current step.
        r_fraction (1,1) double = NaN   % Part done, 0 to 1 (NaN: unknown, the bar moves).
    end
    arguments (Output)
        stop (1,1) logical  % Always false.
    end
    stop = false;
    l_new = s_text ~= obj.s_text;
    obj.s_text     = s_text;      % kept in every mode (the last step)
    obj.r_fraction = r_fraction;
    switch obj.mode
        case "disp"
            if l_new
                fprintf("  %s\n", s_text);
            end
        case "dialog"
            if toc(obj.start_time) < 0.5 || ~isempty(obj.t_draw) && toc(obj.t_draw) < 0.1
                return
            end
            l_open = ~isempty(obj.dialog) && isvalid(obj.dialog);
            if ~isempty(obj.dialog) && ~l_open
                return          % closed by the user
            end
            obj.t_draw = tic;
            obj.n_draw = obj.n_draw + 1;
            r_bar = r_fraction;
            if isnan(r_bar)
                r_bar = mod(obj.n_draw, 20)/20;   % unknown: a moving bar
            end
            r_bar = min(max(r_bar, 0), 1);
            if ~l_open
                h_app = findall(groot, "Type", "figure", "Tag", "GUILDA:app", "Visible", "on");
                if isempty(h_app)
                    obj.dialog = waitbar(r_bar, s_text, "Name", obj.s_title);
                else
                    obj.dialog = uiprogressdlg(h_app(1), "Title", obj.s_title, "Message", s_text, ...
                        "Indeterminate", isnan(r_fraction), "Value", r_bar);
                end
            elseif isa(obj.dialog, "matlab.ui.dialog.ProgressDialog")
                obj.dialog.Message = s_text;
                obj.dialog.Indeterminate = isnan(r_fraction);
                obj.dialog.Value = r_bar;
            else
                waitbar(r_bar, obj.dialog, s_text);
            end
            drawnow limitrate
    end
end
