function s_script = get_script(obj)
% MATLAB script of the entries that ran without an error, in the order they ran.
%
% The Header comes first. Each run of consecutive entries of one Group is a `%% <Group>`
% section, and each entry is its code after a `% <Label>` line. Entries with Status "fail"
% or "run" are left out, so the script reproduces what the GUI did.
%
% <@Examples>
% ```matlab
% disp(h.get_script())
% ```
    arguments (Input)
        obj  % The log.
    end
    arguments (Output)
        s_script (1,1) string  % Script text (lines separated by newline).
    end
    sv_line = obj.sv_header(:);
    l_comment = startsWith(strtrim(sv_line), "%");
    sv_line(~l_comment) = "% " + sv_line(~l_comment);
    tab = obj.tab_entry(obj.tab_entry.Status == "done", :);
    s_group = missing;
    for i = 1:height(tab)
        if ismissing(s_group) || tab.Group(i) ~= s_group
            s_group = tab.Group(i);
            if ~isempty(sv_line)
                sv_line(end+1, 1) = "";    %#ok<AGROW>
            end
            sv_line(end+1, 1) = "%% " + s_group;    %#ok<AGROW>
        end
        sv_line = [sv_line; "% " + tab.Label(i); splitlines(tab.Code(i))];    %#ok<AGROW>
    end
    if isempty(sv_line)
        s_script = "";
    else
        s_script = join(sv_line, newline) + newline;
    end
end
