function close_dialog(h_fig, s_code)
% End the wait of DrawerOptionDialog.ask with the code of the call, or with "" for a cancel (missing).
%
% An empty code means an invalid value: the form already shows why and the dialog stays open.
    arguments (Input)
        h_fig   % Figure of the dialog.
        s_code  % Code of get_code ("" while invalid), or missing for a cancel.
    end
    arguments (Output)
    end
    if ismissing(s_code)
        h_fig.UserData = "";
    elseif s_code == ""
        return
    else
        h_fig.UserData = s_code;
    end
    uiresume(h_fig)    % no effect when ask waits in its loop (hidden dialog), which reads UserData
end
