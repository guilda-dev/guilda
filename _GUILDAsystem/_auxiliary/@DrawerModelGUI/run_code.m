function l_ok = run_code(obj, s_label, s_code, opt)
% Run the code of an action through the history, then draw the GUI again and notify ModelChanged.
%
% With Confirm, a visible figure first asks the question (uiconfirm) and a cancel runs
% nothing; a hidden figure or `matlab -batch` has nobody to ask and runs the code. The
% GUI is drawn again after the run, also after a failed one (a failed run may have changed
% part of a handle model); Render=false leaves the redraw to the caller. A failed run shows
% its error in an alert (a warning on a hidden figure). ModelChanged is notified after a
% successful run.
    arguments (Input)
        obj                             % The GUI.
        s_label (1,1) string            % Label of the entry of the history, also the title of the alert.
        s_code  (1,1) string            % MATLAB code of the action.
        opt.Confirm (1,1) string = ""   % Question asked before the run ("": none).
        opt.Render  (1,1) logical = true  % Draw the GUI again after the run.
    end
    arguments (Output)
        l_ok (1,1) logical  % True when the code ran without an error.
    end
    h_fig = ancestor(obj.h_container, "figure");
    if opt.Confirm ~= "" && h_fig.Visible && ~batchStartupOptionUsed
        s_answer = uiconfirm(h_fig, opt.Confirm, s_label, "Options", ["Remove", "Cancel"], ...
            "DefaultOption", 2, "CancelOption", 2, "Icon", "warning");
        if s_answer ~= "Remove"
            l_ok = false;
            return
        end
    end
    [l_ok, s_detail] = obj.history.run("Model building", s_label, s_code);
    if opt.Render
        obj.render();
    end
    if l_ok
        notify(obj, "ModelChanged")
    else
        show_alert(obj.h_container, regexprep(s_detail, " \(\d+\.\d+ s\)$", ""), s_label);
    end
end
