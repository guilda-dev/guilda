function [l_ok, s_detail] = run_code(obj, s_group, s_label, s_code, opt)
% Run code through the history, with a progress dialog for a long run; a failure shows an alert.
%
% With Progress, an indeterminate uiprogressdlg without a cancel button shows the message
% while the code runs (only on a visible figure outside matlab -batch). A failed run shows
% its message in a uialert on a visible figure; the log keeps it in any case.
    arguments (Input)
        obj
        s_group (1,1) string           % Group of the entry (a section of the script).
        s_label (1,1) string           % Label of the entry.
        s_code  (1,1) string           % MATLAB code to run.
        opt.Progress (1,1) string = "" % Message of the progress dialog ("": none).
    end
    arguments (Output)
        l_ok     (1,1) logical  % True when the code ran without an error.
        s_detail (1,1) string   % Result summary or error message (HistoryGUILDA.run).
    end
    l_visible = isvalid(obj.h_figure) && obj.h_figure.Visible && ~batchStartupOptionUsed;
    h_dialog = [];
    if opt.Progress ~= "" && l_visible
        h_dialog = uiprogressdlg(obj.h_figure, "Title", s_label, "Message", opt.Progress, ...
            "Indeterminate", "on", "Cancelable", "off");
    end
    [l_ok, s_detail] = obj.history.run(s_group, s_label, s_code);
    if ~isempty(h_dialog) && isvalid(h_dialog)
        close(h_dialog);
    end
    if ~l_ok && l_visible
        uialert(obj.h_figure, regexprep(s_detail, " \(\d+\.\d+ s\)$", ""), s_label);
    end
end
