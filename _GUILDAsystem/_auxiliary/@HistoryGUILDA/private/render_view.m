function render_view(obj, h)
% Redraw a view of attach_view: a line per entry and per code line.
    arguments (Input)
        obj  % The log.
        h    % List box of the view.
    end
    arguments (Output)
    end
    if ~isvalid(h)
        return
    end
    tab = obj.tab_entry;
    if height(tab) == 0
        sv_item = "No actions yet: each action of the GUI is added here as MATLAB code.";
        sv_code = "";
    else
        sct_mark = struct("run", "▶", "done", "✔", "fail", "✖");
        sv_item = strings(0, 1);
        sv_code = strings(0, 1);    % code of each line ("" for the other lines)
        for i = 1:height(tab)
            if i == 1 || tab.Group(i) ~= tab.Group(i-1)
                sv_item(end+1, 1) = "【" + tab.Group(i) + "】";    %#ok<AGROW>
                sv_code(end+1, 1) = "";                            %#ok<AGROW>
            end
            s_mark = "□";
            if isfield(sct_mark, tab.Status(i))
                s_mark = sct_mark.(tab.Status(i));
            end
            s_head = s_mark + " " + tab.Label(i);
            if tab.Detail(i) ~= ""
                s_head = s_head + "  → " + tab.Detail(i);
            end
            sv_line = splitlines(tab.Code(i));
            sv_item = [sv_item; s_head; "    >> " + sv_line];    %#ok<AGROW>
            sv_code = [sv_code; ""; sv_line];                    %#ok<AGROW>
        end
    end
    h.Items     = cellstr(sv_item);
    h.ItemsData = 1:numel(sv_item);
    h.UserData  = sv_code;
    h.Value     = [];
    drawnow limitrate
end
