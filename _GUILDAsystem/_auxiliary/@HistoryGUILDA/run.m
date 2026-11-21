function [l_ok, s_detail] = run(obj, s_group, s_label, s_code)
% Run a code string in the workspace of the log and record it as an entry.
%
% The entry is added with Status "run", then the code is evaluated with evalc in the private
% workspace (see HistoryGUILDA). Variables it assigns stay for the next runs. On success the
% Status is "done" and the Detail is the first lines of the Command Window output with the
% elapsed time (without hyperlinks and control characters: evalc wraps a warning in "[" char(8)
% ... "]" char(8), and a control character in the log list makes exportapp of the app fail); on an error the Status is "fail", the Detail is the error message, the
% workspace stays as it was and the error is not rethrown. The event Changed is notified
% when the entry is added and when it ends. With Echo the code lines (">> code") and the
% output are also printed in the Command Window.
%
% <@Examples>
% ```matlab
% [l_ok, s_detail] = h.run("Power flow", "Calculate", "res_pf = net.calculate_powerflow();");
% ```
    arguments (Input)
        obj                      % The log.
        s_group (1,1) string     % Group of the entry, e.g. the tab name; a section of the script.
        s_label (1,1) string     % Short description of the action.
        s_code  (1,1) string     % MATLAB code to run (possibly several lines).
    end
    arguments (Output)
        l_ok     (1,1) logical  % True when the code ran without an error.
        s_detail (1,1) string   % Result summary or error message, with the elapsed time.
    end
    obj.tab_entry(end+1, :) = {s_group, s_label, s_code, "run", ""};
    i_entry = height(obj.tab_entry);
    notify(obj, "Changed")
    if obj.l_echo
        fprintf("%s\n", join(">> " + splitlines(s_code), newline));
    end
    t_start = tic;
    try
        [obj.sct_variable, s_output] = eval_workspace(obj.sct_variable, char(s_code));
        l_ok = true;
        % First non-empty lines of the output, without hyperlinks, the brackets of a warning
        % and the control characters other than the line breaks
        sv_line = strtrim(splitlines(string(regexprep(s_output, ...
            {'<[^>]*>', '\[\x{8}|\]\x{8}', '[\x{0}-\x{9}\x{B}\x{C}\x{E}-\x{1F}]'}, {'', '', ' '}))));
        sv_line = sv_line(sv_line ~= "");
        s_detail = "done";
        if ~isempty(sv_line)
            s_detail = regexprep(join(sv_line(1:min(3, end)), " "), "\s+", " ");
        end
        if obj.l_echo
            fprintf("%s", s_output);
        end
    catch ME
        l_ok = false;
        s_detail = string(ME.message);
        if obj.l_echo
            fprintf(2, "%s\n", getReport(ME, "basic", "hyperlinks", "off"));
        end
    end
    s_detail = s_detail + sprintf(" (%.2f s)", toc(t_start));
    if l_ok
        obj.tab_entry.Status(i_entry) = "done";
    else
        obj.tab_entry.Status(i_entry) = "fail";
    end
    obj.tab_entry.Detail(i_entry) = s_detail;
    notify(obj, "Changed")
end
